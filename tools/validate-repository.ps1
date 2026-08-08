param(
    [switch]$SkipLuaSyntax,
    [string]$LuaCompiler = 'luac'
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

function Read-VersionInteger([string]$fieldName) {
    $match = [regex]::Match($versionSource, "(?m)^\s*$([regex]::Escape($fieldName))\s*=\s*(?<value>\d+)\s*,?")

    if (-not $match.Success) {
        Add-Failure "shared/version.lua does not define integer field: $fieldName"
        return $null
    }

    return [int]$match.Groups['value'].Value
}

$resourceMajor = Read-VersionInteger 'major'
$resourceMinor = Read-VersionInteger 'minor'
$resourcePatch = Read-VersionInteger 'patch'
$apiVersion = Read-VersionInteger 'api'
$protocolVersion = Read-VersionInteger 'protocol'
$prereleaseMatch = [regex]::Match($versionSource, "(?m)^\s*prerelease\s*=\s*'(?<value>[^']*)'")

if (-not $prereleaseMatch.Success) {
    Add-Failure 'shared/version.lua does not define prerelease.'
}

$resourceVersion = "$resourceMajor.$resourceMinor.$resourcePatch"

if ($prereleaseMatch.Success -and -not [string]::IsNullOrWhiteSpace($prereleaseMatch.Groups['value'].Value)) {
    $resourceVersion += "-$($prereleaseMatch.Groups['value'].Value)"
}

$manifestLuaPaths = [regex]::Matches($manifest, '[''"](?<path>[^''"]+\.lua)[''"]') |
    ForEach-Object { $_.Groups['path'].Value } |
    Where-Object { $_ -notmatch '[*?]' } |
    Sort-Object -Unique

foreach ($relativePath in $manifestLuaPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $resourceRoot $relativePath))) {
        Add-Failure "fxmanifest.lua references a missing file: $relativePath"
    }
}

$manifestVersionMatch = [regex]::Match($manifest, "(?m)^\s*version\s+'(?<value>[^']+)'")

if (-not $manifestVersionMatch.Success) {
    Add-Failure 'fxmanifest.lua does not declare a resource version.'
}
elseif ($manifestVersionMatch.Groups['value'].Value -ne $resourceVersion) {
    Add-Failure "fxmanifest.lua version $($manifestVersionMatch.Groups['value'].Value) does not match shared/version.lua $resourceVersion."
}

$changeLog = Get-Content -LiteralPath (Join-Path $repoRoot 'CHANGELOG.md') -Raw
$latestChangeLogMatch = [regex]::Match($changeLog, '(?m)^##\s+\[(?<value>[^\]]+)\]')

if (-not $latestChangeLogMatch.Success) {
    Add-Failure 'CHANGELOG.md has no release heading.'
}
elseif ($latestChangeLogMatch.Groups['value'].Value -ne $resourceVersion) {
    Add-Failure "Latest CHANGELOG version $($latestChangeLogMatch.Groups['value'].Value) does not match $resourceVersion."
}

$rootReadme = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
$documentedVersionMatch = [regex]::Match($rootReadme, 'Core Resource Version:\s*`(?<value>[^`]+)`')
$documentedApiMatch = [regex]::Match($rootReadme, 'Core API Version:\s*`(?<value>\d+)`')
$documentedProtocolMatch = [regex]::Match($rootReadme, 'Network Protocol Version:\s*`(?<value>\d+)`')

if (-not $documentedVersionMatch.Success -or $documentedVersionMatch.Groups['value'].Value -ne $resourceVersion) {
    Add-Failure 'README.md resource version does not match shared/version.lua.'
}

if (-not $documentedApiMatch.Success -or [int]$documentedApiMatch.Groups['value'].Value -ne $apiVersion) {
    Add-Failure 'README.md Core API version does not match shared/version.lua.'
}

if (-not $documentedProtocolMatch.Success -or [int]$documentedProtocolMatch.Groups['value'].Value -ne $protocolVersion) {
    Add-Failure 'README.md protocol version does not match shared/version.lua.'
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
            & $LuaCompiler -p $temporary 2>&1 | ForEach-Object { $compilerOutput = $_ }

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

$apiSource = Get-Content -LiteralPath (Join-Path $resourceRoot 'server/api.lua') -Raw
$exportsSource = Get-Content -LiteralPath (Join-Path $resourceRoot 'server/exports.lua') -Raw
$apiMethods = [regex]::Matches($apiSource, 'function\s+GCAPI\.(?<name>[A-Za-z0-9_]+)\s*\(') |
    ForEach-Object { $_.Groups['name'].Value } |
    Sort-Object -Unique
$exportPairs = [regex]::Matches($exportsSource, "exports\('(?<export>[^']+)',\s*GCAPI\.(?<method>[A-Za-z0-9_]+)\)")
$exportedMethods = $exportPairs | ForEach-Object { $_.Groups['method'].Value } | Sort-Object -Unique

foreach ($pair in $exportPairs) {
    if ($pair.Groups['export'].Value -ne $pair.Groups['method'].Value) {
        Add-Failure "Export $($pair.Groups['export'].Value) is not mapped to the same GCAPI method name."
    }
}

foreach ($method in $apiMethods) {
    if ($method -notin $exportedMethods) {
        Add-Failure "Public GCAPI method is missing a FiveM export: $method"
    }
}

foreach ($method in $exportedMethods) {
    if ($method -notin $apiMethods) {
        Add-Failure "FiveM export references a missing GCAPI method: $method"
    }
}

$clientEventsSource = Get-Content -LiteralPath (Join-Path $resourceRoot 'client/events.lua') -Raw

if ($clientEventsSource -match '\bRegisterNetEvent\s*\(') {
    Add-Failure 'client/events.lua bypasses the centralized server-origin guard.'
}

$exactTag = (& git -C $repoRoot describe --tags --exact-match 2>$null)

if ($LASTEXITCODE -eq 0 -and $exactTag) {
    $normalizedTag = $exactTag.Trim() -replace '^v', ''

    if ($normalizedTag -ne $resourceVersion) {
        Add-Failure "Git tag $exactTag does not match resource version $resourceVersion."
    }
}
elseif ($env:GITHUB_REF_TYPE -eq 'tag') {
    $normalizedTag = $env:GITHUB_REF_NAME -replace '^v', ''

    if ($normalizedTag -ne $resourceVersion) {
        Add-Failure "Release tag $($env:GITHUB_REF_NAME) does not match resource version $resourceVersion."
    }
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

# EN: `git describe --exact-match` is expected to return 1 for ordinary,
# untagged commits. Do not leak that probe status as the validator result.
#
# RU: `git describe --exact-match` ожидаемо возвращает 1 для обычных коммитов
# без тега. Этот служебный код не должен становиться результатом валидатора.
exit 0
