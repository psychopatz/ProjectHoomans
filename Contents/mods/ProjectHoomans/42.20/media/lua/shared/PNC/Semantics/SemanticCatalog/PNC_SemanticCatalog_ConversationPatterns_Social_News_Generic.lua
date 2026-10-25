-- Generic news pattern registrations.
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

function Internal.RegisterGenericNewsSignals()
    local patterns = {
        {
            id = "pnc.social.news_you_got",
            match = {
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            -- Some input sources drop the final "s" in this exact phrasing.
            -- Keep that shorthand local instead of making "new" a global alias.
            id = "pnc.social.news_you_got_short",
            match = {
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "literal", value = "new" },
            },
        },
        {
            id = "pnc.social.news_have_you_got",
            match = {
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_do_you_have",
            match = {
                { kind = "literal", value = "do" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "concept", id = "HAVE" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_any",
            match = {
                { kind = "literal", value = "any" },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_tell_me",
            match = {
                { kind = "literal", value = "tell" },
                { kind = "literal", value = "me" },
                { kind = "literal", value = "some", optional = true },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_what_is",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "is" },
                { kind = "literal", value = "the", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_whats_the",
            match = {
                { kind = "literal", value = "what's" },
                { kind = "literal", value = "the", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_have_you_heard",
            match = {
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "concept", id = "HEAR" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
    }
    local index
    local pattern
    for index = 1, #patterns do
        pattern = patterns[index]
        registerNewsPattern(pattern.id, pattern.match, false)
    end
end

return Internal

