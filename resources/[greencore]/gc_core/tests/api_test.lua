GCTest.Register('api.version_contract', function()
    local dto = GCAPI.GetVersion()

    GCTest.ExpectEqual(dto.version, '0.1.2-alpha', 'public DTO contains release version')
    GCTest.ExpectEqual(dto.apiVersion, GCAPI.GetApiVersion(), 'DTO API version is consistent')
    GCTest.ExpectEqual(dto.protocolVersion, GCAPI.GetProtocolVersion(), 'DTO protocol version is consistent')

    dto.resource.patch = 999
    GCTest.ExpectEqual(GCAPI.GetVersion().resource.patch, 2, 'public DTO does not expose internal table')
end, 'integration')

GCTest.Register('api.invalid_source_contract', function()
    GCTest.ExpectFalse(GCAPI.IsPlayerConnected('1'), 'string source is rejected')
    GCTest.ExpectNil(GCAPI.GetPlayerSession(-1), 'negative source is rejected')
end, 'security')
