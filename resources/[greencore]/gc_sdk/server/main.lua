local compatible, compatibilityError = GCSDK.RequireCoreApi(1)
if compatible then
    print(('[GC][SDK] gc_sdk %s ready / API %d'):format(
        GCSDKVersion.GetString(),
        GCSDKVersion.api
    ))
else
    print(('[GC][SDK] unavailable: %s'):format(tostring(compatibilityError)))
end
