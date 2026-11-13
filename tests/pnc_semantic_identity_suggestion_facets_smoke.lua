local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = {
        AllowsSharedCode = function() return true end,
    },
}
PNC = {
    Semantics = {},
    IdentityAlias = {
        Generate = function() return "Alex Reed" end,
    },
}

local Provider = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/Suggestions/StaticProvider.lua"
)

local function ids(context)
    local output = {}
    for _, definition in ipairs(Provider.collect(context) or {}) do
        output[definition.id] = true
    end
    return output
end

local initial = ids({
    activeHubID = nil,
    npcKnowledge = {
        identity = {},
    },
})
T.truthy(initial["question.identity"],
    "generic identity suggestion remains available before identity is known")
T.truthy(initial["question.identity_nickname"],
    "nickname suggestion is available before nickname is known")
T.truthy(initial["question.identity_surname"],
    "surname suggestion is available before surname is known")
T.truthy(initial["question.identity_faction"],
    "faction suggestion is available before faction is known")

local nicknameKnown = ids({
    activeHubID = nil,
    npcKnowledge = {
        identity = {
            nickname = "Pat",
        },
    },
})
T.falsy(nicknameKnown["question.identity_nickname"],
    "known nickname suggestion is removed")
T.truthy(nicknameKnown["question.identity_surname"],
    "unknown surname suggestion remains available")
T.truthy(nicknameKnown["question.identity_faction"],
    "unknown faction suggestion remains available")

local allKnown = ids({
    activeHubID = nil,
    identityState = "known",
    npcKnowledge = {
        factionKnown = true,
        factionName = "The Rovers",
        identity = {
            nickname = "Pat",
            surname = "Parker",
        },
    },
})
T.falsy(allKnown["question.identity"],
    "generic identity suggestion is removed after identity exchange")
T.falsy(allKnown["question.identity_nickname"],
    "nickname suggestion is removed after disclosure")
T.falsy(allKnown["question.identity_surname"],
    "surname suggestion is removed after disclosure")
T.falsy(allKnown["question.identity_faction"],
    "faction suggestion is removed after disclosure")

local factionByID = ids({
    activeHubID = nil,
    npcKnowledge = {
        factionKnown = true,
        factionID = "faction:rovers",
        identity = {},
    },
})
T.falsy(factionByID["question.identity_faction"],
    "known faction ID also removes the faction suggestion")

T.finish("pnc_semantic_identity_suggestion_facets_smoke")
