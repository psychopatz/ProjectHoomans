-- Targeted news pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social spoke requires Catalog.Internal")
end

local registerNewsPattern = Internal.RegisterNewsPattern
if type(registerNewsPattern) ~= "function" then
    error("semantic catalog social spoke requires RegisterNewsPattern")
end

function Internal.RegisterTargetedNewsSignals()
    local patterns = {
        {
            id = "pnc.social.news_any_about_target",
            match = {
                { kind = "literal", value = "any" },
                { kind = "concept", id = "NEWS" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
        {
            id = "pnc.social.news_tell_me_about_target",
            match = {
                { kind = "literal", value = "tell" },
                { kind = "literal", value = "me" },
                { kind = "literal", value = "some", optional = true },
                { kind = "concept", id = "NEWS" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
        {
            id = "pnc.social.news_what_heard_about_target",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "concept", id = "HEAR" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
    }
    local index
    local pattern
    for index = 1, #patterns do
        pattern = patterns[index]
        registerNewsPattern(pattern.id, pattern.match, true)
    end
end

return Internal

