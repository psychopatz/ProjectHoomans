local T = require "tests/support/test"
T.addPackagePaths()

local originalRequire = require
local originalPsychopatzCore = PsychopatzCore
local originalPNC = PNC
local originalInputClass = PsychopatzConversationLLMInput
local llmCalls = 0
local registeredFallbacks = {}

PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(value)
                return value and (value.fallback
                    or registeredFallbacks[value.key]) or ""
            end,
            RegisterFallback = function(key, value)
                registeredFallbacks[key] = value
                return value
            end,
        },
    },
}
PNC = {}
PsychopatzConversationLLMInput = {
    new = function(_, x, y, width, height, options)
        return { x = x, y = y, width = width, height = height, options = options }
    end,
}

local gameTime = {}
function gameTime:getWorldAgeHours() return 49.5 end
function gameTime:getTimeOfDay() return 13.5 end
function gameTime:getHour() return 13 end
function gameTime:getMinutes() return 30 end
local climate = {}
function climate:getPrecipitationIntensity() return 0.4 end
function climate:isRaining() return true end
function climate:getFogIntensity() return 0 end
getGameTime = function() return gameTime end
getClimateManager = function() return climate end
getTimeInMillis = function() return 1000 end

local traceEntries = {}
PsychopatzCore.DebugTrace = {
    IsEnabled = function() return true end,
    Record = function(definition)
        traceEntries[#traceEntries + 1] = definition
        return true
    end,
}

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
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local providerReady = true
PNC.PBrainZ = {
    IsProviderAvailable = function() return providerReady end,
    Submit = function()
        llmCalls = llmCalls + 1
        error("LLM must not be called for a greeting")
    end,
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Context.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)

-- The production widget dependencies are UI-only. Keep the routing test
-- headless while preserving the real Core parser, Hoomans catalog, policy,
-- router, and input spokes.
require = function() return true end
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle.lua"
)
require = originalRequire

local queued = {}
local session = {
    characterUUID = "player-one",
    conversationID = "conversation-one",
    append = function(self, speaker, value, metadata)
        self.lastAppend = {
            speaker = speaker, value = value, metadata = metadata,
        }
        return { messageID = "message-one" }
    end,
    queueMessage = function(self, speaker, payload, metadata)
        queued[#queued + 1] = {
            speaker = speaker, payload = payload, metadata = metadata,
        }
    end,
}
local view = {
    spec = {
        npcID = "npc-alice",
        context = {
            identityState = "known",
            npcName = "Alice",
            npcFullName = "Alice",
            relationshipState = "Acquaintance",
            conversationTopic = "whats_up",
            entry = {
                snapshot = {
                    activeBehavior = "Fishing:WAITING",
                    healthState = "injured",
                    needs = {
                        hunger = 0.10,
                        thirst = 0.82,
                        fatigue = 0.20,
                    },
                },
            },
        },
    },
    session = session,
    isConversationInteractive = function() return true end,
}

local initialContext = Input.Internal.ShallowContext(view)
T.equal(initialContext.currentTopic, "whats_up",
    "authored conversation topic enters semantic context before input")

local accepted, reason = Input.Submit(view, "hello there")
T.equal(accepted, true, "greeting is accepted locally")
T.equal(reason, nil, "local greeting has no rejection reason")
T.equal(#queued, 1, "local greeting queues exactly one response")
T.equal(queued[1].payload.fallback, "Hey there. Wet one today.",
    "greeting can use the live weather context")
T.equal(queued[1].payload.text, "Hey there. Wet one today.",
    "live semantic payload keeps readable fallback text")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "greeting never enters the LLM route")
T.equal(llmCalls, 0,
    "recognized greeting stays local even when the provider is ready")

T.equal(registeredFallbacks["semantic.command.accepted"], "Okay.",
    "semantic policy registers a readable history fallback")
T.equal(registeredFallbacks["semantic.ask_clarification"],
    "I'm not sure what you mean.",
    "clarification history fallback is registered")
T.equal(view.session.semanticDialogueState.currentTopic, "greeting",
    "greeting updates the compact conversation topic")
T.equal(traceEntries[1].event, "semantic_input_local",
    "local greeting emits an opt-in semantic route trace")
T.equal(traceEntries[1].data.route, "deterministic",
    "local route trace records deterministic routing")
T.equal(traceEntries[1].data.pattern, "pnc.social.greet",
    "local route trace records the matched semantic pattern")
T.equal(traceEntries[1].data.providerUsed, false,
    "local route trace records that no provider was used")

local timeAccepted = Input.Submit(view, "what time is it")
T.equal(timeAccepted, true, "time question is accepted locally")
T.equal(queued[2].payload.fallback, "It's 1:30 PM.",
    "time question uses the live local clock snapshot")
T.equal(view.session.semanticDialogueState.currentTopic, "time",
    "time question updates the current topic")

local dayAccepted = Input.Submit(view, "what day is it")
T.equal(dayAccepted, true, "calendar question is accepted locally")
T.equal(queued[3].payload.fallback, "It's day 2.",
    "calendar question uses the live world day snapshot")
T.equal(view.session.semanticDialogueState.currentTopic, "time",
    "calendar question remains in the time topic")

local weatherAccepted = Input.Submit(view, "is it raining")
T.equal(weatherAccepted, true, "weather question is accepted locally")
T.equal(queued[4].payload.fallback, "It's raining right now.",
    "weather question uses the live climate snapshot")
T.equal(view.session.semanticDialogueState.currentTopic, "weather",
    "weather question updates the current topic")

local activityAccepted = Input.Submit(view, "what are you doing")
T.equal(activityAccepted, true, "activity question is accepted locally")
T.equal(queued[5].payload.fallback, "I'm trying to catch something.",
    "activity question uses the NPC's current behavior projection")
T.equal(view.session.semanticDialogueState.currentTopic, "activity",
    "activity question updates the current topic")

local wellbeingAccepted = Input.Submit(view, "are you okay")
T.equal(wellbeingAccepted, true, "wellbeing question is accepted locally")
T.equal(queued[6].payload.fallback,
    "I've been better. I could really use some water.",
    "wellbeing response uses bounded NPC need pressure")
T.equal(view.session.semanticDialogueState.currentTopic, "wellbeing",
    "wellbeing question updates the current topic")

providerReady = false
local offlineGreetingAccepted = Input.Submit(view, "hello there")
T.equal(offlineGreetingAccepted, true,
    "greeting remains local when the provider is disabled")
T.equal(queued[7].payload.fallback, "Hey there. Wet one today.",
    "provider-disabled greeting still uses the local response catalog")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "provider-disabled greeting remains on the deterministic route")
T.equal(llmCalls, 0,
    "provider-disabled greeting never attempts the LLM")

local insultBefore = #queued
local insultAccepted = Input.Submit(view, "fuck you")
T.equal(insultAccepted, true,
    "recognized hostile language remains responsive without the provider")
T.equal(#queued, insultBefore + 1,
    "recognized hostile language queues one local response")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "recognized hostile language stays on the deterministic route")
T.equal(view.lastSemanticDialogueResult.decision.branch,
    "HOSTILE_REMARK_RECEIVED",
    "recognized hostile language selects its local branch")
T.falsy(string.find(queued[#queued].payload.fallback,
    "I'm not sure what you mean.", 1, true),
    "recognized hostile language does not use generic clarification")
T.equal(llmCalls, 0,
    "provider-disabled hostile language never attempts the LLM")

local typoInsultAccepted = Input.Submit(view, "fuk you")
T.equal(typoInsultAccepted, true,
    "a misspelled hostile remark remains responsive without the provider")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "a misspelled hostile remark stays on the local route")
T.equal(view.lastSemanticDialogueResult.ir.diagnostics.fuzzyMatch, true,
    "the live input route exposes typo correction diagnostics")
T.equal(llmCalls, 0,
    "provider-disabled typo handling never attempts the LLM")

local unavailableBefore = #queued
local unavailableAccepted = Input.Submit(
    view, "Can you do something about this?"
)
T.equal(unavailableAccepted, true,
    "ambiguous input remains responsive when the provider is disabled")
T.equal(llmCalls, 0,
    "provider-disabled ambiguous input does not attempt an LLM call")
T.equal(#queued, unavailableBefore + 1,
    "provider-disabled ambiguity queues one deterministic response")
T.equal(queued[#queued].payload.fallback, "I'm not sure what you mean.",
    "provider-disabled ambiguity uses deterministic clarification")
T.falsy(string.find(queued[#queued].payload.fallback, "Give me a moment", 1, true),
    "provider-disabled ambiguity never emits the legacy wait placeholder")

local semanticRouter = Input.Internal.RouterFor(view)
local entityPreview = semanticRouter:Preview("help Alice")
T.equal(entityPreview.accepted, true,
    "known conversation entity is accepted locally")
T.equal(entityPreview.ir.target.id, "npc-alice",
    "conversation context supplies the current NPC identity candidate")
T.equal(entityPreview.ir.diagnostics.unresolvedEntity, false,
    "known conversation entity is resolved before policy")
T.truthy(Semantic, "Core semantic parser remains the active parser")

view.spec.context.entry.snapshot.needs.hunger = 0.82
view.spec.context.entry.snapshot.needs.thirst = 0.10
view.spec.context.entry.snapshot.needs.fatigue = 0.10
local offerAccepted = Input.Submit(view, "who wants an apple")
T.equal(offerAccepted, true, "item offers stay on the local route")
T.equal(view.lastSemanticDialogueResult.decision.branch,
    "OFFER_RECEIVED", "offers select a dedicated semantic branch")
T.equal(queued[#queued].payload.fallback, "I could use one.",
    "a hungry NPC reacts to an offer from its local need state")

view.spec.context.entry.snapshot.needs.hunger = 0.10
local declinedOffer = Input.Submit(view, "who wants an apple")
T.equal(declinedOffer, true, "a non-hungry NPC can decline locally")
T.equal(queued[#queued].payload.fallback,
    "No thanks, I'm not hungry.",
    "offer response changes with the NPC's current need state")

local identityAccepted = Input.Submit(view, "im psycho btw")
T.equal(identityAccepted, true,
    "natural identity introductions are accepted by the local route")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "natural identity introductions never enter the LLM route")
T.equal(view.lastSemanticDialogueResult.ir.provenance.pattern,
    "pnc.identity.self_name_im_plain",
    "natural identity introductions use the identity grammar")
T.equal(llmCalls, 0,
    "natural identity introductions do not call the LLM")

-- An identity claim has an authoritative response.  The local semantic
-- branch must not also queue its provisional exchange line, or one utterance
-- appears as two contradictory NPC replies in the live conversation.
local identityEvents = {}
local identityQueue = {}
PNC.Client = {
    RequestNPCKnowledgeTopic = function(npcID, topicID, options)
        identityEvents[#identityEvents + 1] = {
            kind = "identity_disclosure",
            npcID = npcID,
            topicID = topicID,
            options = options,
        }
        return true
    end,
    SubmitSemanticIdentity = function(npcID, options)
        identityEvents[#identityEvents + 1] = {
            kind = options and options.kind,
            npcID = npcID,
            options = options,
        }
        return true
    end,
}
local identitySession = {
    characterUUID = "player-one",
    conversationID = "identity-conversation",
    append = function(self, speaker, value, metadata)
        self.lastAppend = { speaker = speaker, value = value, metadata = metadata }
        return { messageID = "identity-message" }
    end,
    queueMessage = function(self, speaker, payload, metadata)
        identityQueue[#identityQueue + 1] = {
            speaker = speaker, payload = payload, metadata = metadata,
        }
    end,
}
local identityView = {
    spec = {
        npcID = "npc-identity",
        context = {
            identityState = "unknown",
            npcName = "Mara",
            npcFullName = "Mara Vale",
            relationshipState = "FirstMeet",
            conversationTopic = "greeting",
        },
    },
    session = identitySession,
    isConversationInteractive = function() return true end,
}
T.equal(Input.Submit(identityView, "what is your name"), true,
    "identity question starts the authoritative exchange")
T.equal(#identityQueue, 1,
    "identity question has one local request response")
T.equal(Input.Submit(identityView, "im psycho"), true,
    "identity claim is submitted to the authority")
T.equal(#identityQueue, 1,
    "identity claim does not queue a contradictory provisional response")
T.equal(identityEvents[2].kind, "identity_claim",
    "identity claim uses the authoritative identity transport")

PNC = originalPNC
PsychopatzCore = originalPsychopatzCore
PsychopatzConversationLLMInput = originalInputClass

T.finish("pnc_semantic_local_route_smoke")
