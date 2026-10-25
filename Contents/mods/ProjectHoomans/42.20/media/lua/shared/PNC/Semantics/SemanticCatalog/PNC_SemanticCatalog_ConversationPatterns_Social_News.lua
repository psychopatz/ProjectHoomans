-- News and gossip conversation-pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

function Internal.RegisterNewsSignals()
    registerPattern(
        "pnc.social.gossip_event",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "HEAR" },
            { kind = "literal", value = "that", optional = true },
            { kind = "any", capture = "target" },
            { kind = "concept", id = "BITTEN" },
        },
        {
            intent = "GOSSIP",
            speechAct = "GOSSIP",
            subject = "GOSSIP",
            target = "$capture.target",
            slots = {
                information = {
                    event = "BITTEN",
                    subject = "$capture.target",
                },
            },
        },
        0.88,
        90
    )

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
        registerPattern(
            pattern.id,
            pattern.match,
            {
                intent = "GOSSIP",
                speechAct = "GOSSIP",
                subject = "GOSSIP",
                target = pattern.target and "$capture.target" or nil,
                slots = {
                    information = { event = "NEWS" },
                },
            },
            0.98,
            130
        )
    end
end

return Internal
