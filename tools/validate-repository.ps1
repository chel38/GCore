param(
    [switch]$SkipLuaSyntax
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resourceRoot = Join-Path $repoRoot 'resources/[greencore]/gc_core'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$message) {
    $failures.Add($message)
}

$manifestPath = Join-Path $resourceRoot 'fxmanifest.lua'
$manifest = Get-Content -LiteralPath $manifestPath -Raw
$versionSource = Get-Content -LiteralPath (Join-Path $resourceRoot 'shared/version.lua') -Raw

if ($manifest -notmatch "version\s+'0\.1\.2-alpha'") {
    Add-Failure 'fxmanifest.lua release version is not 0.1.2-alpha.'
}

foreach ($expected in @(
    'major = 0',
    'minor = 1',
    'patch = 2',
    "prerelease = 'alpha'",
    'api = 1',
    'protocol = 1'
)) {
    if (-not $versionSource.Contains($expected)) {
        Add-Failure "shared/version.lua is missing: $expected"
    }
}

$productionLoadsTests = [regex]::Matches(
    $manifest,
    'server_scripts\s*\{(?<body>(?s:.*?))\}'
) | Where-Object { $_.Groups['body'].Value -match '[''"]tests/' }

if ($productionLoadsTests) {
    Add-Failure 'Tests are executed through server_scripts in production.'
}

$coreLuaFiles = Get-ChildItem -LiteralPath $resourceRoot -Recurse -Filter '*.lua'

foreach ($file in $coreLuaFiles) {
    $relative = [IO.Path]::GetRelativePath($resourceRoot, $file.FullName).Replace('\', '/')
    $source = Get-Content -LiteralPath $file.FullName -Raw

    if ($relative -ne 'shared/runtime.lua' -and $source -match '\bIsDuplicityVersion\b') {
        Add-Failure "Forbidden runtime detection outside shared/runtime.lua: $relative"
    }

    if (
        $relative -ne 'shared/events.lua' -and
        $relative -notlike 'tests/*' -and
        $source -match '[''"]gc_core:(?:server|client):'
    ) {
        Add-Failure "Network event literal outside shared/events.lua: $relative"
    }

    if (
        $relative -notin @('server/states.lua', 'server/sessions.lua') -and
        $relative -notlike 'tests/*' -and
        $source -match '\.state\s*=(?!=)'
    ) {
        Add-Failure "Direct state mutation outside state/session ownership: $relative"
    }

    if (-not $SkipLuaSyntax) {
        $temporary = [IO.Path]::Combine([IO.Path]::GetTempPath(), ([guid]::NewGuid().ToString() + '.lua'))

        try {
            $portableSource = [regex]::Replace($source, '`[^`\r\n]+`', '0')
            [IO.File]::WriteAllText($temporary, $portableSource, [Text.UTF8Encoding]::new($false))
            & luac -p $temporary 2>&1 | ForEach-Object { $compilerOutput = $_ }

            if ($LASTEXITCODE -ne 0) {
                Add-Failure "Lua syntax failed for $relative`: $compilerOutput"
            }
        }
        finally {
            Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($versionSource -match 'GCConfig\.General\.(?:apiVersion|protocolVersion)') {
    Add-Failure 'Version source depends on duplicate config version fields.'
}

$generalConfig = Get-Content -LiteralPath (Join-Path $resourceRoot 'config/general.lua') -Raw

if ($generalConfig -match '\b(?:apiVersion|protocolVersion)\s*=') {
    Add-Failure 'config/general.lua duplicates API or protocol versions.'
}

$securityDocument = Get-Content -LiteralPath (Join-Path $repoRoot 'SECURITY.md') -Raw

if ($securityDocument -notmatch 'github\.com/chel38/GCore/security/advisories/new') {
    Add-Failure 'SECURITY.md does not link to GitHub private vulnerability reporting.'
}

$markdownFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/](?:server|txData|\.git)[\\/]' }

foreach ($file in $markdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $matches = [regex]::Matches($content, '\]\((?<target>(?!https?://|mailto:|#)[^)]+)\)')

    foreach ($match in $matches) {
        $target = $match.Groups['target'].Value.Trim('<', '>').Split('#')[0]

        if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^app://') {
            continue
        }

        $decoded = [Uri]::UnescapeDataString($target)
        $resolved = Join-Path $file.DirectoryName $decoded

        if (-not (Test-Path -LiteralPath $resolved)) {
            $relativeFile = [IO.Path]::GetRelativePath($repoRoot, $file.FullName)
            Add-Failure "Broken local Markdown link in $relativeFile`: $target"
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Repository validation passed ($($coreLuaFiles.Count) Lua files, $($markdownFiles.Count) Markdown files)."
