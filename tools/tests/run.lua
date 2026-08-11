local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/tests/run.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools/tests'
local toolRoot = scriptDirectory .. separator .. '..'
package.path = toolRoot .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Manifest = require('gcore_manifest')
local Graph = require('gcore_graph')
local Conformance = require('gcore_conformance')
local Generator = require('gcore_generator')
local Package = require('gcore_package')
local Sha256 = require('gcore_sha256')
local Discovery = require('gcore_discovery')

local repoRoot = arg[1] or '.'
local assertions, failures = 0, 0

local function expect(value, message)
    assertions = assertions + 1
    if value then print('[PASS] ' .. message)
    else failures = failures + 1; print('[FAIL] ' .. message) end
end

local function hasIssue(result, code)
    for _, issue in ipairs(result.issues or {}) do if issue.code == code then return true end end
    return false
end

local fixtures = FS.Join(repoRoot, 'tools', 'tests', 'fixtures', 'modules')
local templateRoot = FS.Join(repoRoot, 'tools', 'templates', 'module')

print('=== GCore Ecosystem Tooling Tests ===')

local parsed = Manifest.Parse([[
name 'parser_fixture'
gcore_module 'yes'
gcore_capability 'one'
gcore_capability 'two'
error('manifest parser must never execute Lua')
]])
expect(Manifest.First(parsed, 'name') == 'parser_fixture', 'declarative manifest metadata parsed')
expect(#Manifest.Values(parsed, 'gcore_capability') == 2, 'repeated manifest metadata preserved')
expect(Manifest.ParseDependency('provider:api>=2').minimumApi == 2, 'dependency grammar parsed')
expect(Manifest.ParseDependency('../provider:api>=1') == nil, 'unsafe dependency grammar rejected')

local valid = Conformance.Validate(FS.Join(fixtures, 'valid_module'))
expect(valid.ok, 'valid third-party fixture passes conformance')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'missing_manifest')), 'GC-CONFORMANCE-MANIFEST-MISSING'), 'missing manifest rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'missing_metadata')), 'GC-CONFORMANCE-METADATA-MISSING'), 'missing metadata rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'private_core_import')), 'GC-CONFORMANCE-CORE-INTERNAL'), 'private core global rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'unknown_core_export')), 'GC-CONFORMANCE-CORE-EXPORT-UNKNOWN'), 'unknown core export rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'missing_dependency')), 'GC-CONFORMANCE-DEPENDENCY-DECLARATION'), 'missing FiveM dependency declaration rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'bad_docs')), 'GC-CONFORMANCE-FILE-MISSING'), 'missing bilingual docs rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'missing_manifest_file')), 'GC-CONFORMANCE-MANIFEST-FILE-MISSING'), 'missing manifest script rejected')
expect(hasIssue(Conformance.Validate(FS.Join(fixtures, 'unsafe_manifest_path')), 'GC-CONFORMANCE-MANIFEST-PATH-UNSAFE'), 'manifest path traversal rejected')

local plan = assert(Generator.BuildPlan({ name = 'gc_generated', type = 'domain' }, templateRoot))
expect(plan['server/main.lua'] ~= nil and plan['client/main.lua'] == nil, 'server-only generator plan is minimal')
local clientPlan = assert(Generator.BuildPlan({ name = 'gc_client', type = 'integration', client = true }, templateRoot))
expect(clientPlan['client/main.lua'] ~= nil and clientPlan['web/package.json'] == nil, 'client module adds only client runtime')
local nuiPlan = assert(Generator.BuildPlan({ name = 'gc_nui', type = 'domain', nui = true }, templateRoot))
expect(nuiPlan['client/main.lua'] ~= nil and nuiPlan['web/package.json'] ~= nil, 'NUI module adds TypeScript build skeleton')
local thirdParty = assert(Generator.BuildPlan({ name = 'vendor_module', type = 'domain', thirdParty = true }, templateRoot))
expect(thirdParty['fxmanifest.lua']:match("gcore_module 'yes'") ~= nil, 'third-party generator uses metadata marker')
local _, invalidName = Generator.BuildPlan({ name = '../bad', type = 'domain' }, templateRoot)
expect(invalidName == 'GC-GENERATOR-NAME-INVALID', 'generator rejects path traversal')

local cycles = Graph.FindCycles({
    { resource = 'a', requiredModules = { { resource = 'b' } } },
    { resource = 'b', requiredModules = { { resource = 'a' } } }
})
expect(#cycles > 0, 'dependency graph detects a cycle')
expect(Sha256.Sum('abc') == 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', 'portable SHA-256 matches standard vector')
expect(not Package.ShouldInclude('.env'), 'packager excludes .env')
expect(not Package.ShouldInclude('web/node_modules/pkg/file.js'), 'packager excludes node_modules')
expect(not Package.ShouldInclude('coverage/result.json'), 'packager excludes coverage')
expect(not Package.ShouldInclude('.git/config'), 'packager excludes .git')
expect(not Package.ShouldInclude('data/runtime.sqlite'), 'packager excludes database files')
expect(not Package.ShouldInclude('data/identities.json'), 'packager excludes top-level runtime data')
expect(Package.ShouldInclude('web/dist/index.html'), 'packager includes production NUI dist')

local modules = assert(Discovery.Find(repoRoot))
expect(#modules >= 4, 'metadata discovery finds official ecosystem modules')

local existingRoot = FS.Join(
    repoRoot,
    'build',
    'tool-tests',
    'generator-existing-' .. tostring(os.time()) .. '-' .. tostring(math.random(1000, 9999))
)
assert(FS.MakeDir(FS.Join(existingRoot, 'gc_existing')))
local _, existingError = Generator.Generate(
    { name = 'gc_existing', type = 'domain' },
    templateRoot,
    existingRoot
)
expect(existingError == 'GC-GENERATOR-DESTINATION-EXISTS', 'generator never overwrites an existing module')

local unique = tostring(os.time()) .. '-' .. tostring(math.random(100000, 999999))
local workRoot = FS.Join(repoRoot, 'build', 'tool-tests', unique)
local workModule = FS.Join(workRoot, 'valid_module')
for _, source in ipairs(assert(FS.ListFiles(FS.Join(fixtures, 'valid_module')))) do
    local relative = FS.Relative(FS.Join(fixtures, 'valid_module'), source)
    assert(FS.CopyFile(source, FS.Join(workModule, relative)))
end
assert(FS.WriteFile(FS.Join(workModule, '.env'), 'SECRET=must-not-package\n'))
assert(FS.WriteFile(FS.Join(workModule, 'node_modules', 'fixture.txt'), 'excluded\n'))
assert(FS.WriteFile(FS.Join(workModule, 'data', 'identities.json'), '{"private":true}\n'))
local packageResult = assert(Package.Build(workModule, FS.Join(workRoot, 'release'), {
    skipTests = true,
    repoRoot = repoRoot,
    harness = FS.Join(repoRoot, 'tools', 'module_test_harness.lua')
}))
expect(not FS.Exists(FS.Join(packageResult.root, 'resource', '.env')), 'artifact excludes physical .env')
expect(not FS.Exists(FS.Join(packageResult.root, 'resource', 'node_modules')), 'artifact excludes physical node_modules')
expect(not FS.Exists(FS.Join(packageResult.root, 'resource', 'data')), 'artifact excludes physical runtime data')
expect(FS.IsFile(packageResult.archive), 'packager creates distributable tar artifact')
expect(#packageResult.checksum == 64, 'packager emits SHA-256 checksum')

print(('Tooling total: %d | Passed: %d | Failed: %d'):format(assertions, assertions - failures, failures))
if failures > 0 then os.exit(1) end
