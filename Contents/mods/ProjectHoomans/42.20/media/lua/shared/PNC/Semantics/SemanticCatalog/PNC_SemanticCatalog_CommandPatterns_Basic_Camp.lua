-- Camp command pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog command spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog command spoke requires RegisterPattern")
end

function Internal.RegisterCampCommands()
    registerPattern(
        "pnc.command.camp_campfire",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP" },
            { kind = "literal", value = "the", optional = true },
            { kind = "concept", id = "CAMPFIRE" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "campfire",
                concept = "CAMPFIRE",
                text = "campfire",
            },
        },
        0.97,
        150
    )
    registerPattern(
        "pnc.command.camp_room",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP" },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "room",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "room",
                roomQuery = "$capture.room",
                roomType = "$capture.room.concept",
                text = "$capture.room.text",
                unresolved = "$capture.room.unresolved",
            },
        },
        0.95,
        140,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.command.camp_here",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "here", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "here",
            },
        },
        0.96,
        160
    )
    registerPattern(
        "pnc.command.camp_here_place",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "this" },
            { kind = "literal", value = "place" },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "here",
            },
        },
        0.96,
        160
    )
end

return Internal

