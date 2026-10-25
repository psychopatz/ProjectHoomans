-- Shared self-state registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog self-state spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog self-state spoke requires RegisterPattern")
end

Internal.SelfStatePrefixes = {
    { id = "im", tokens = { "i'm" } },
    { id = "i_am", tokens = { "i", "am" } },
    { id = "im_plain", tokens = { "im" } },
}
Internal.SelfWellbeingStatuses = {
    { id = "fine", phrase = "fine", value = "fine", thankYou = true },
    { id = "okay", phrase = "okay", value = "okay", thankYou = true },
    { id = "ok", phrase = "ok", value = "okay", thankYou = true },
    { id = "alright", phrase = "alright", value = "alright" },
    { id = "all_right", phrase = "all right", value = "all right" },
    { id = "good", phrase = "good", value = "good" },
}

function Internal.BuildSelfStateSocialContext()
    return {
        directed = false,
        selfDirected = true,
        target = "SELF",
    }
end

return Internal
