GCIdentityAPI = {}

function GCIdentityAPI.GetIdentityVersion()
    return GCIdentityVersion.GetString()
end

function GCIdentityAPI.GetIdentityApiVersion()
    return GCIdentityVersion.api
end

function GCIdentityAPI.GetIdentityProtocolVersion()
    return GCIdentityVersion.protocol
end

function GCIdentityAPI.IsAuthorized(playerSource)
    return GCIdentityStates.IsAuthorized(playerSource)
end

function GCIdentityAPI.IsIdentityReady(playerSource)
    return GCIdentityStates.IsReady(playerSource)
end

function GCIdentityAPI.GetIdentityState(playerSource)
    local session = GCIdentityStates.Get(playerSource)
    return session and session.state or nil
end

function GCIdentityAPI.GetAccount(playerSource)
    return GCIdentityService.GetAccount(playerSource)
end

function GCIdentityAPI.GetCharacters(playerSource)
    return GCIdentityService.GetCharacters(playerSource)
end

function GCIdentityAPI.GetSelectedCharacter(playerSource)
    return GCIdentityService.GetSelectedCharacter(playerSource)
end
