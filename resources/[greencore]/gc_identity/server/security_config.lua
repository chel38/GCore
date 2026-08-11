GCIdentitySecurityConfig = {}

local function convar(name)
    local value = GetConvar(name, '')
    return type(value) == 'string' and value or ''
end

function GCIdentitySecurityConfig.MailUrl()
    return convar('gcore_mail_service_url') ~= ''
        and convar('gcore_mail_service_url')
        or 'http://127.0.0.1:8091'
end

function GCIdentitySecurityConfig.MailToken()
    return convar('gcore_mail_token')
end

function GCIdentitySecurityConfig.ChallengeSecret()
    return convar('gcore_identity_challenge_secret')
end

function GCIdentitySecurityConfig.IpSecret()
    return convar('gcore_ip_fingerprint_secret')
end

function GCIdentitySecurityConfig.ValidateMailBoundary()
    local url = GCIdentitySecurityConfig.MailUrl()
    if not url:match('^http://127%.0%.0%.1:%d+/?$') then
        return false, 'GC-IDENTITY-MAIL-URL-UNSAFE'
    end
    if #GCIdentitySecurityConfig.MailToken() < 32 then
        return false, 'GC-IDENTITY-MAIL-TOKEN-MISSING'
    end
    if #GCIdentitySecurityConfig.ChallengeSecret() < 32 then
        return false, 'GC-IDENTITY-CHALLENGE-SECRET-MISSING'
    end
    if #GCIdentitySecurityConfig.IpSecret() < 32 then
        return false, 'GC-IDENTITY-IP-SECRET-MISSING'
    end
    return true
end
