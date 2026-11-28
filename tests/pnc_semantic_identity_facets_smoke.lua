local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/Dialogue/Policy.lua"
)
local Parser = Semantic.Parser

local nickname = Parser.Parse("what do people call you")
T.equal(nickname.subject, "IDENTITY_NICKNAME",
    "nickname question has its own semantic subject")
T.equal(nickname.diagnostics.matchedPattern,
    "pnc.question.identity.nickname",
    "nickname question uses the dedicated deterministic pattern")

local surname = Parser.Parse("what's your last name")
T.equal(surname.subject, "IDENTITY_SURNAME",
    "surname question has its own semantic subject")
T.equal(surname.diagnostics.matchedPattern,
    "pnc.question.identity.surname",
    "surname question uses the dedicated deterministic pattern")

local faction = Parser.Parse("who are you with")
T.equal(faction.subject, "IDENTITY_FACTION",
    "faction question has its own semantic subject")
T.equal(faction.diagnostics.matchedPattern,
    "pnc.question.identity.faction",
    "faction question uses the dedicated deterministic pattern")

for _, phrasing in ipairs({
    "what faction is this",
    "which faction is this",
    "what's your faction",
    "who runs this place",
}) do
    local parsed = Parser.Parse(phrasing)
    T.equal(parsed.intent, "QUESTION",
        phrasing .. " parses as QUESTION")
    T.equal(parsed.subject, "IDENTITY_FACTION",
        phrasing .. " parses as IDENTITY_FACTION")
end

local generic = Parser.Parse("what's your name")
T.equal(generic.subject, "IDENTITY",
    "generic name question keeps the identity subject")

local knownNickname = Policy.Decide(nickname, nil, {
    llmEnabled = false,
    npcID = "npc-pat",
    identityState = "known",
    identityLevel = "nickname",
    npcName = "Pat",
    npcKnowledge = { identity = { nickname = "Pat" } },
})
T.equal(knownNickname.branch, "QUESTION_RECEIVED",
    "nickname question remains a read-only question")
T.equal(knownNickname.response.templateID,
    "hoomans.question.repeat_known.repeat_nickname",
    "known nickname selects the nickname response")
T.contains(knownNickname.response.fallback, "Pat",
    "known nickname response uses the learned value")

local unknownSurname = Policy.Decide(surname, nil, {
    llmEnabled = false,
    npcID = "npc-pat",
    identityState = "known",
    identityLevel = "nickname",
    npcName = "Pat",
    npcKnowledge = { identity = { nickname = "Pat" } },
})
T.equal(unknownSurname.response.templateID,
    "hoomans.question.about_you.gated.surname_guarded",
    "unknown surname remains undisclosed")
T.falsy(string.find(unknownSurname.response.fallback, "Parker", 1, true),
    "unknown surname response does not invent a surname")

local knownFaction = Policy.Decide(faction, nil, {
    llmEnabled = false,
    npcID = "npc-pat",
    identityState = "known",
    identityLevel = "nickname",
    npcName = "Pat",
    factionName = "The Rovers",
})
T.equal(knownFaction.response.templateID,
    "hoomans.question.repeat_known.repeat_faction",
    "known faction selects the faction response")
T.contains(knownFaction.response.fallback, "The Rovers",
    "known faction response uses the learned value")

T.finish("pnc_semantic_identity_facets_smoke")
