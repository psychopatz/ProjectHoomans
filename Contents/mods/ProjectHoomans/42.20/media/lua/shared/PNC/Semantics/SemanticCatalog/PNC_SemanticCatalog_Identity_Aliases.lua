-- Alias-style identity claim pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog or {}
local Internal = Catalog.Internal or {}
Catalog.Internal = Internal

if type(Internal.RegisterIdentityPattern) ~= "function" then
    error("semantic identity aliases spoke requires identity core")
end

function Internal.RegisterIdentityAliasPatterns()
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_my_names",
        { "my", "name's" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_you_can_call_me",
        { "you", "can", "call", "me" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_i_go_by",
        { "i", "go", "by" },
        nil,
        0.98,
        155
    )
    Internal.RegisterIdentityPattern(
        "pnc.identity.self_name_i_am_called",
        { "i'm", "called" },
        nil,
        0.98,
        155
    )
end

return Internal
