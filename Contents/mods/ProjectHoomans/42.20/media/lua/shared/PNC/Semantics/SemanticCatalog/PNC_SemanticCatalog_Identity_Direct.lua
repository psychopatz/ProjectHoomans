-- Direct identity claim pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog or {}
local Internal = Catalog.Internal or {}
Catalog.Internal = Internal

if type(Internal.RegisterIdentityPattern) ~= "function" then
    error("semantic identity direct spoke requires identity core")
end

function Internal.RegisterIdentityDirectPatterns()
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_im",
        { "i'm" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_i_am",
        { "i", "am" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_im_plain",
        { "im" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.name_is_my_name",
        {},
        { "is", "my", "name" },
        0.97,
        154
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.my_name_is",
        { "my", "name", "is" },
        nil,
        0.97,
        154
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.call_me",
        { "call", "me" },
        nil,
        0.97,
        154
    )
end

return Internal
