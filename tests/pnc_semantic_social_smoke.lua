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
local ResponseCatalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local DialogueContext = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
local IdentityExchange = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticIdentityExchange.lua"
)
local Parser = Semantic.Parser

T.truthy(Semantic.Registry.GetSpeechAct("INSULT"),
    "insult speech act is registered by the social catalog")
T.truthy(Semantic.Registry.GetSpeechAct("HOSTILE_REMARK"),
    "hostile remark speech act is registered by the social catalog")

local insult = Parser.Parse("fuck you")
T.equal(insult.intent, "INSULT", "directed profanity becomes an insult")
T.equal(insult.speechAct, "INSULT", "insult preserves its speech act")
T.equal(insult.subject, "RECIPIENT", "insult is directed at the recipient")
T.equal(insult.diagnostics.matchedPattern, "pnc.social.insult",
    "exact insult uses the exact social pattern")
T.equal(insult.diagnostics.recommendedRoute, "deterministic",
    "known insult stays on the local route")
T.equal(insult.emotionalState.intensity, "high",
    "insult intensity remains semantic metadata")

local censored = Parser.Parse("f*** you")
T.equal(censored.intent, "INSULT", "censored profanity is recognized locally")
T.equal(censored.diagnostics.recommendedRoute, "deterministic",
    "censored insult does not need the LLM")

local prefixed = Parser.Parse("hey, fuck you")
T.equal(prefixed.intent, "INSULT", "a short conversational prefix is allowed")
T.equal(prefixed.diagnostics.matchedPattern, "pnc.social.insult_prefixed",
    "prefixed insult uses its bounded prefix pattern")
T.truthy(prefixed.confidence >= 0.80,
    "prefixed insult remains sufficiently confident")

local selfMockery = Parser.Parse("I'm an idiot")
T.equal(selfMockery.intent, "SELF_REFLECTION",
    "self-mockery is a self-reflection act")
T.equal(selfMockery.subject, "SELF",
    "self-mockery keeps the speaker as its target")
T.truthy(selfMockery.socialContext
    and selfMockery.socialContext.selfDirected == true,
    "self-mockery is marked self-directed")
T.equal(selfMockery.socialContext.reflectionType, "SELF_MOCKERY",
    "self-mockery preserves its reflection subtype")

local selfMockeryIAm = Parser.Parse("I am an idiot")
T.equal(selfMockeryIAm.intent, "SELF_REFLECTION",
    "expanded first-person self-mockery is recognized")

local selfHunger = Parser.Parse("I'm starving")
T.equal(selfHunger.intent, "INFORM",
    "hunger is an information/state report")
T.equal(selfHunger.subject, "HUNGER",
    "hunger state is not mistaken for a name")
T.falsy(selfHunger.socialContext and selfHunger.socialContext.identityClaim,
    "hunger state does not create an identity claim")

local plainSelfHunger = Parser.Parse("im starving")
T.equal(plainSelfHunger.subject, "HUNGER",
    "plain im hunger state is not mistaken for a name")

local recipientInsult = Parser.Parse("you are an idiot")
T.equal(recipientInsult.intent, "INSULT",
    "second-person insult targets the recipient")
T.equal(recipientInsult.subject, "RECIPIENT",
    "second-person insult keeps recipient targeting")
T.equal(recipientInsult.diagnostics.matchedPattern,
    "pnc.social.insult_you_are",
    "expanded second-person insult uses its explicit grammar")

local recipientContraction = Parser.Parse("you're an idiot")
T.equal(recipientContraction.intent, "INSULT",
    "contracted second-person insult is recognized")
T.equal(recipientContraction.diagnostics.matchedPattern,
    "pnc.social.insult_youre",
    "contracted insult uses its explicit grammar")

local malformedSelfPrefix = Parser.Parse("I idiot")
T.falsy(malformedSelfPrefix.intent == "INSULT",
    "a first-person prefix cannot turn self-reference into a recipient insult")

local identityClaim = Parser.Parse("I'm Patrick")
T.equal(identityClaim.intent, "INFORM",
    "first-person name introduction becomes an information act")
T.equal(identityClaim.subject, "IDENTITY",
    "first-person name introduction targets identity")
T.truthy(identityClaim.socialContext
    and identityClaim.socialContext.identityClaim == true,
    "name introduction carries an identity-claim marker")
T.equal(identityClaim.slots.identityClaim.name, "patrick",
    "name introduction preserves the normalized claimed name")

local conversationalIdentity = Parser.Parse("im psycho btw")
T.truthy(conversationalIdentity.socialContext
    and conversationalIdentity.socialContext.identityClaim == true,
    "plain im introductions remain identity claims")
T.equal(conversationalIdentity.slots.identityClaim.name, "psycho",
    "plain im introductions capture the name before conversational filler")

local turnTakingIdentity = Parser.Parse("I'm Psycho, now your turn")
T.equal(turnTakingIdentity.slots.identityClaim.name, "psycho",
    "turn-taking filler does not become part of the claimed name")

local namedIdentity = Parser.Parse(
    "psycho is my name, nice to meet you"
)
T.equal(namedIdentity.slots.identityClaim.name, "psycho",
    "is-my-name introductions capture the leading name")

local possessiveIdentity = Parser.Parse(
    "my name is psycho, nice to meet you"
)
T.equal(possessiveIdentity.slots.identityClaim.name, "psycho",
    "my-name-is introductions capture the claimed name")

local plainSelfMockery = Parser.Parse("im an idiot")
T.equal(plainSelfMockery.intent, "SELF_REFLECTION",
    "plain im self-mockery remains self-directed")

local profanity = Parser.Parse("shit")
T.equal(profanity.intent, "HOSTILE_REMARK",
    "standalone profanity becomes a hostile social remark")
T.equal(profanity.diagnostics.matchedPattern, "pnc.social.profanity",
    "standalone profanity uses the local profanity pattern")

local threat = Parser.Parse("I'll kill you")
T.equal(threat.intent, "THREATEN", "explicit threat remains distinct from insult")
T.equal(threat.diagnostics.matchedPattern, "pnc.social.threaten",
    "explicit threat uses the threat pattern")

local wait = Parser.Parse("stay right here")
T.equal(wait.action, "STAY", "common wait wording is vocabulary data")

local state = Semantic.DialogueState.New({ participants = { "npc:mara" } })
local decision = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara",
})
T.equal(decision.route, "deterministic",
    "local social recognition never waits for the provider")
T.equal(decision.branch, "HOSTILE_REMARK_RECEIVED",
    "insult selects a dedicated social response branch")
T.truthy(decision.response.fallback ~= "I'm not sure what you mean.",
    "recognized insult does not use generic clarification")

local withdrawn = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-withdrawn",
    dialogueSituation = {
        social = { style = "withdrawn" },
    },
})
T.equal(withdrawn.response.templateID, "semantic.social.hostile_withdrawn",
    "hostile response can use NPC social style")

local selfReflection = Policy.Decide(selfMockery, state, {
    llmEnabled = false,
    npcID = "mara-friend",
    relationshipState = "Friend",
    socialStyle = "friendly",
})
T.equal(selfReflection.branch, "SELF_REFLECTION_RECEIVED",
    "self-mockery selects a dedicated reflection response branch")
T.equal(selfReflection.response.templateID,
    "semantic.social.self_reflection.friendly",
    "friendly standing produces a supportive self-reflection response")

local withdrawnReflection = Policy.Decide(selfMockery, state, {
    llmEnabled = false,
    npcID = "mara-withdrawn-reflection",
    relationshipState = "Stranger",
    socialStyle = "withdrawn",
})
T.equal(withdrawnReflection.response.templateID,
    "semantic.social.self_reflection.withdrawn",
    "withdrawn social style produces a distinct self-reflection response")

local identityDecision = Policy.Decide(identityClaim, state, {
    llmEnabled = false,
    npcID = "mara-identity",
    identityState = "known",
    npcName = "Mara",
    npcFullName = "Mara",
})
T.equal(identityDecision.branch, "IDENTITY_CLAIM_RECEIVED",
    "a name introduction enters the identity exchange branch")
T.equal(identityDecision.response.fallback,
    "Nice to meet you. What's your name?",
    "identity claim waits for authoritative validation before disclosure")

local identityQuestion = Parser.Parse("what's your name")
local identityQuestionDecision = Policy.Decide(identityQuestion, state, {
    llmEnabled = false,
    npcID = "mara-identity-question",
    identityState = "known",
    npcName = "Mara",
    npcFullName = "Mara",
})
T.equal(identityQuestionDecision.branch, "QUESTION_RECEIVED",
    "identity question remains a question while starting the exchange")
T.truthy(identityQuestionDecision.response.fallback
    and string.find(identityQuestionDecision.response.fallback,
        "What's your name?", 1, true),
    "identity question asks the player for their name")

local exchangeContext = DialogueContext.New()
exchangeContext:RecordTurn(identityQuestion, { speaker = "npc" })
T.equal(exchangeContext:ToContext().pendingIdentityExchange.kind,
    "PLAYER_NAME",
    "identity question creates a bounded player-name obligation")
exchangeContext:RecordTurn(selfHunger, { speaker = "player" })
T.falsy(exchangeContext:ToContext().pendingIdentityExchange,
    "a subsequent topic turn retires the pending name obligation")
T.truthy(IdentityExchange.NamesEqual("Patrick", "patrick"),
    "identity validation compares names case-insensitively")
T.falsy(IdentityExchange.NamesEqual("Patrick", "Patricia"),
    "identity validation rejects a different exact name")

local identityEvasion = Policy.Decide(selfHunger, state, {
    llmEnabled = false,
    npcID = "mara-identity-evasion",
    pendingIdentityExchange = { kind = "PLAYER_NAME", requestedAt = 1 },
    socialStyle = "friendly",
})
T.equal(identityEvasion.branch, "IDENTITY_NAME_EVASION",
    "changing topics while a name answer is pending is an identity evasion")
T.equal(identityEvasion.response.templateID,
    "semantic.identity.evasion.friendly",
    "identity evasion uses the relationship-aware disappointment response")

state:Record(insult, { timestamp = 100 })
local firstHostile = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-escalation",
})
T.falsy(firstHostile.response.templateID == "semantic.social.hostile_escalated",
    "the first hostile remark does not start at the escalation branch")
state:Record(insult, { timestamp = 200 })
local escalated = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-escalation",
})
T.equal(escalated.response.templateID, "semantic.social.hostile_escalated",
    "recent hostile remarks produce a bounded escalation response")

local first = ResponseCatalog.Select(
    "semantic.hostile_remark", { npcID = "repeat-check" }, "same-salt"
)
local second = ResponseCatalog.Select(
    "semantic.hostile_remark", { npcID = "repeat-check" }, "same-salt"
)
T.truthy(first and second, "hostile response pool remains available")
T.falsy(first.id == second.id,
    "response selection rotates instead of repeating the same variant")

local unknown = Parser.Parse("Can you do something about this?")
T.falsy(unknown.intent, "unrelated language does not become a hostile act")

T.finish("pnc_semantic_social_smoke")
