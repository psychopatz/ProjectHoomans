local T = require "tests/support/test"
T.addPackagePaths()

-- The semantic parser must boot without a bridge, LLM provider, game actor,
-- or gameplay service. This test deliberately supplies only the Core table.
PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local CommandAdapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCommandAdapter.lua"
)
local Parser = Semantic.Parser
local IR = Semantic.IR

local follow = Parser.Parse("Follow me.")
T.equal(follow.intent, "REQUEST", "follow intent")
T.equal(follow.action, "FOLLOW", "follow action")
T.equal(follow.diagnostics.recommendedRoute, "deterministic",
    "high-confidence commands stay in Lua")
T.truthy(follow.confidence >= 0.90, "follow confidence")

local synonym = Parser.Parse("Come with me!")
T.equal(synonym.action, "FOLLOW", "follow synonym")
T.equal(synonym.diagnostics.matchedPattern, "pnc.command.follow",
    "synonyms use the same semantic pattern")

local stopFollowing = Parser.Parse("Stop following me")
T.equal(stopFollowing.action, "STOP",
    "progressive follow language resolves to the existing stop action")
T.equal(Policy.Decide(stopFollowing, nil, { llmEnabled = false }).branch,
    "COMMAND_ACCEPTED", "stop-following uses the existing command branch")
T.equal(CommandAdapter.Resolve(stopFollowing), "stay",
    "stop-following reuses the existing authoritative stay command")
local dontFollow = Parser.Parse("Please don't follow me")
T.equal(dontFollow.action, "STOP",
    "a direct prohibition maps to the existing safe inverse command")
local doNotFollow = Parser.Parse("Do not follow me")
T.equal(doNotFollow.action, "STOP",
    "uncontracted prohibitions share the same Hoomans action")
local dontStopFollowing = Parser.Parse("Don't stop following me")
T.falsy(dontStopFollowing.action,
    "negating stop does not trigger a stop command")
T.equal(dontStopFollowing.diagnostics.noMatch, true,
    "unsupported double negation remains unresolved")

local greeting = Parser.Parse("hello there")
T.equal(greeting.intent, "GREET", "greeting intent")
T.equal(greeting.speechAct, "GREET", "greeting speech act")
T.equal(greeting.diagnostics.matchedPattern, "pnc.social.greet",
    "greeting uses the local social pattern")
T.equal(greeting.diagnostics.recommendedRoute, "deterministic",
    "greetings never require the optional LLM")

local hunger = Parser.Parse("I'm hungry")
T.equal(hunger.intent, "INFORM", "self-state intent")
T.equal(hunger.subject, "HUNGER", "self-state subject")
T.equal(hunger.provenance.pattern, "pnc.state.self_hunger_im",
    "self-state claims use the dedicated state pattern")

local selfWellbeing = Parser.Parse("im fine thank you")
T.equal(selfWellbeing.intent, "INFORM",
    "a first-person fine reply is a self-state report")
T.equal(selfWellbeing.subject, "WELLBEING",
    "fine replies use the explicit wellbeing subject")
T.equal(selfWellbeing.slots.state.type, "WELLBEING",
    "fine replies preserve their state type")
T.equal(selfWellbeing.slots.state.value, "fine",
    "fine replies preserve the reported status")
T.equal(selfWellbeing.socialContext.selfDirected, true,
    "fine replies are explicitly self-directed")
T.equal(selfWellbeing.socialContext.target, "SELF",
    "fine replies cannot be mistaken for an NPC state claim")
local punctuatedWellbeing = Parser.Parse("I'm fine, thank you.")
T.equal(punctuatedWellbeing.subject, "WELLBEING",
    "punctuation and the standard contraction keep the same self-state meaning")
local selfWellbeingDecision = Policy.Decide(
    selfWellbeing, nil, { llmEnabled = false })
T.equal(selfWellbeingDecision.branch, "SELF_STATE_RECEIVED",
    "first-person wellbeing replies reach the local self-state response")
T.equal(selfWellbeingDecision.route, "deterministic",
    "the wellbeing acknowledgment does not require the optional LLM")
T.truthy(string.find(
    selfWellbeingDecision.response.templateID,
    "semantic.self_state.wellbeing", 1, true
), "fine replies receive an empathetic deterministic response")

local thirstyReport = Parser.Parse("I am thirsty")
T.equal(thirstyReport.subject, "THIRST",
    "first-person thirst uses the existing state-report path")
T.equal(thirstyReport.slots.state.value, "thirsty",
    "the thirst report preserves the recognized state phrase")
T.equal(Policy.Decide(thirstyReport, nil, { llmEnabled = false }).branch,
    "SELF_STATE_RECEIVED", "thirst reports reach the local response")
local tiredReport = Parser.Parse("I'm exhausted")
T.equal(tiredReport.subject, "FATIGUE",
    "first-person fatigue uses the existing state-report path")
T.equal(Policy.Decide(tiredReport, nil, { llmEnabled = false }).branch,
    "SELF_STATE_RECEIVED", "fatigue reports reach the local response")

local standaloneOkay = Parser.Parse("okay")
T.equal(standaloneOkay.intent, "ACCEPT",
    "standalone okay retains its existing acceptance meaning")
local fineByMe = Parser.Parse("fine by me")
T.equal(fineByMe.intent, "AGREE",
    "fine by me retains its existing agreement meaning")
local longerFine = Parser.Parse("I am fine with that")
T.falsy(longerFine.intent == "INFORM"
    and longerFine.subject == "WELLBEING",
    "a longer agreement clause is not truncated into a wellbeing report")
local negatedFine = Parser.Parse("I am not fine")
T.falsy(negatedFine.intent == "INFORM"
    and negatedFine.subject == "WELLBEING",
    "negated wellbeing is not treated as a positive fine report")

local date = Parser.Parse("What day is it?")
T.equal(date.subject, "DATE", "higher-priority date concept wins")
T.equal(date.provenance.pattern, "pnc.question.day",
    "date questions use the local date pattern")

local weather = Parser.Parse("What is the weather?")
T.equal(weather.subject, "WEATHER", "weather question subject")
T.equal(weather.provenance.pattern, "pnc.question.weather",
    "weather questions use the local context pattern")

local offer = Parser.Parse("Who wants an apple?")
T.equal(offer.intent, "OFFER", "offer intent")
T.equal(offer.speechAct, "OFFER", "offer speech act")
T.equal(offer.object.text, "apple", "offer preserves the item phrase")
T.equal(offer.object.unresolved, true,
    "unknown offered items remain data for the later item resolver")
T.equal(offer.diagnostics.recommendedRoute, "deterministic",
    "an item offer has no gameplay side effect and remains local")

local waitHere = Parser.Parse("Wait here.")
T.equal(waitHere.action, "STAY", "wait maps to existing stay semantics")

local campHere = Parser.Parse("lets camp in here")
T.equal(campHere.action, "CAMP", "camp-here action")
T.equal(campHere.target.scope, "here",
    "camp-here preposition keeps a generic site scope")
T.falsy(campHere.target.roomQuery,
    "camp-here does not capture the deictic word as a room")

local campPlace = Parser.Parse("camp at this place")
T.equal(campPlace.action, "CAMP", "camp-this-place action")
T.equal(campPlace.target.scope, "here",
    "camp-this-place keeps a generic site scope")

local goHome = Parser.Parse("Go home.")
T.equal(goHome.action, "GO", "go home action")
T.equal(goHome.destination.category, "HOME", "go home destination")

local water = Parser.Parse("Can you bring me some water?")
T.equal(water.intent, "REQUEST", "water request intent")
T.equal(water.action, "FETCH", "water request action")
T.equal(water.object.category, "WATER", "water request object")
T.equal(water.object.quantity, "SOME", "water request quantity")
T.equal(water.diagnostics.recommendedRoute, "deterministic",
    "common fetch request stays in Lua")

local wantFetch = Parser.Parse("I want you to retrieve some food")
T.equal(wantFetch.action, "FETCH",
    "a constrained want-you-to frame reuses the existing FETCH concept")
T.equal(wantFetch.object.category, "FOOD",
    "the new request frame keeps the existing item role")
T.equal(wantFetch.diagnostics.matchedPattern, "pnc.request.want_you_fetch",
    "the explicit conversational request frame is diagnosable")
local wantFetchDecision = Policy.Decide(wantFetch, nil, { llmEnabled = false })
T.equal(wantFetchDecision.branch, "REQUEST_ACKNOWLEDGED",
    "the new wording reaches the existing item-request branch")
T.equal(wantFetchDecision.actionIntent.action, "FETCH",
    "the existing FETCH task path receives the semantic action")
local negatedWantFetch = Parser.Parse("I don't want you to retrieve food")
T.falsy(negatedWantFetch.action,
    "negative desire language is not promoted into a FETCH command")
T.equal(negatedWantFetch.diagnostics.noMatch, true,
    "negative desire language remains unresolved until a refusal rule exists")

local food = Parser.Parse("Get some food")
T.equal(food.object.category, "FOOD", "food synonym object")

local medicine = Parser.Parse("Bring me meds")
T.equal(medicine.object.category, "MEDICINE",
    "new concepts are vocabulary registrations")

local inventoryWhat = Parser.Parse("What kind of seafood do you have?")
T.equal(inventoryWhat.subject, "INVENTORY",
    "what-kind inventory questions are semantic questions")
T.equal(inventoryWhat.inventoryQuery.concept, "SEAFOOD",
    "what-kind inventory questions preserve the concept")

local unknownItem = Parser.Parse("Bring me an apple")
T.equal(unknownItem.action, "FETCH",
    "fetch accepts an item name outside the core vocabulary")
T.equal(unknownItem.object.text, "apple",
    "unknown item text remains available to the item selector")
T.equal(unknownItem.object.unresolved, true,
    "unknown fetch objects remain explicitly unresolved")

local compoundItem = Parser.Parse("Bring me some medical supplies")
T.equal(compoundItem.action, "FETCH",
    "fetch accepts bounded compound item names")
T.equal(compoundItem.object.text, "medical supplies",
    "compound item text remains intact for MarketSense selection")

local negated = Parser.Parse("Don't go")
T.equal(negated.action, "GO", "negated command action")
T.equal(negated.modifiers.negated, true, "negation is semantic metadata")

local question = Parser.Parse("Where is John?")
T.equal(question.intent, "QUESTION", "question intent")
T.equal(question.subject, "LOCATION", "question subject")
T.equal(question.target.text, "john", "unresolved target is preserved")
T.equal(question.target.unresolved, true, "world resolution stays downstream")

local whereFind = Parser.Parse("Where can I find Sarah?")
T.equal(whereFind.subject, "LOCATION",
    "find phrasing reuses the local location question")
T.equal(whereFind.target.text, "sarah",
    "find phrasing preserves the requested person")
T.equal(whereFind.diagnostics.matchedPattern, "pnc.question.where_can_find",
    "find phrasing uses its explicit rule")

local whereKnow = Parser.Parse("Do you know where Sarah is?")
T.equal(whereKnow.subject, "LOCATION",
    "embedded where questions become location queries")
T.equal(whereKnow.target.text, "sarah",
    "embedded where questions stop the target at the copula")

local seenHave = Parser.Parse("Have you seen Sarah?")
T.equal(seenHave.subject, "SEEN",
    "present perfect phrasing reuses the seen question")
T.equal(seenHave.target.text, "sarah",
    "present perfect seen queries preserve the target")

local seenHappen = Parser.Parse("Did you happen to see Sarah?")
T.equal(seenHappen.subject, "SEEN",
    "polite seen phrasing reuses the seen question")
T.equal(seenHappen.target.text, "sarah",
    "polite seen queries preserve the target")

local locationDecision = Policy.Decide(whereKnow, nil, { llmEnabled = false })
T.equal(locationDecision.branch, "QUESTION_RECEIVED",
    "read-only location questions can answer without a resolved target")
T.equal(locationDecision.response.templateID,
    "semantic.question.location_unknown",
    "unresolved location questions keep the explicit uncertainty response")
local seenDecision = Policy.Decide(seenHave, nil, { llmEnabled = false })
T.equal(seenDecision.branch, "QUESTION_RECEIVED",
    "read-only seen questions can answer without a resolved target")
T.equal(seenDecision.response.templateID, "semantic.question.seen_unknown",
    "unknown seen facts remain uncertain instead of fabricated")

local howFeeling = Parser.Parse("How are you feeling?")
T.equal(howFeeling.subject, "WELLBEING",
    "feeling questions use the existing local wellbeing answer")
T.equal(howFeeling.diagnostics.matchedPattern,
    "pnc.question.wellbeing_feeling",
    "the explicit feeling frame wins over the shorter how-are-you frame")
local howBeen = Parser.Parse("How have you been?")
T.equal(howBeen.subject, "WELLBEING",
    "recent wellbeing questions use the existing local answer")
local feelingOkay = Parser.Parse("Are you feeling okay?")
T.equal(feelingOkay.subject, "WELLBEING",
    "feeling-check wording uses the existing wellbeing answer")

local recentActivity = Parser.Parse("What have you been doing?")
T.equal(recentActivity.subject, "ACTIVITY",
    "recent activity phrasing uses the existing local answer")
local recentActivityUpTo = Parser.Parse("What have you been up to?")
T.equal(recentActivityUpTo.subject, "ACTIVITY",
    "recent up-to phrasing uses the existing local answer")
local activityNow = Parser.Parse("What are you doing right now?")
T.equal(activityNow.subject, "ACTIVITY",
    "time-qualified activity questions use the existing local answer")
local everythingOkay = Parser.Parse("Is everything okay?")
T.equal(everythingOkay.subject, "WELLBEING",
    "broad but direct wellbeing checks use the existing local answer")

local wellbeingDecision = Policy.Decide(howBeen, nil, { llmEnabled = false })
T.equal(wellbeingDecision.branch, "QUESTION_RECEIVED",
    "expanded wellbeing phrasing stays on the pure Lua question branch")
T.equal(wellbeingDecision.response.templateID,
    "semantic.question.wellbeing.default",
    "expanded phrasing reuses the existing wellbeing response variant")

local statementWithLocation = Parser.Parse("I know where Sarah is")
T.falsy(statementWithLocation.intent,
    "embedded statements do not become location questions")
local statementWithWellbeing = Parser.Parse("I wonder how you have been")
T.falsy(statementWithWellbeing.intent,
    "embedded statements do not become wellbeing questions")
local activityHow = Parser.Parse("How are you carrying the boxes?")
T.falsy(activityHow.intent,
    "how-are-you activity questions do not become wellbeing questions")
local activityOkay = Parser.Parse("Are you okay fixing the fence?")
T.falsy(activityOkay.intent,
    "okay followed by an activity does not become a wellbeing question")

local unknown = Parser.Parse("Can you do something about this?")
T.falsy(unknown.intent, "unknown language has no invented intent")
T.truthy(unknown.confidence < 0.60, "unknown language is low confidence")
T.equal(unknown.diagnostics.recommendedRoute, "llm_fallback",
    "low confidence recommends optional LLM fallback")
T.equal(unknown.diagnostics.noMatch, true, "unknown language is diagnosable")

local valid, reason = IR.Validate(water)
T.equal(valid, true, "semantic IR validates")
T.equal(reason, nil, "valid IR has no validation reason")
T.equal(Catalog.registered, true, "domain catalog loaded")
T.truthy(Semantic.Registry.GetSpeechAct("GOSSIP"),
    "speech acts are extensible registry metadata")

T.finish("pnc_semantic_nlu_smoke")
