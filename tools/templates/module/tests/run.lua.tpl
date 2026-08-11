GCModuleTest.Load('shared/version.lua')

GCModuleTest.Register('{{MODULE_NAME}}.version_contract', 'contract', function()
    GCModuleTest.ExpectEqual(GCModuleVersion.GetString(), '{{VERSION}}', 'resource version is stable')
end)
