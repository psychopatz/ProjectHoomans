local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "presentation-test" end
getText = function(key) return key end
Events = { OnTick = { Add = function() end } }
getSpecificPlayer = function()
    return {
        getUsername = function() return "tester" end,
        getDisplayName = function()
            return "Alexandra Maximilian Longsurname"
        end,
        getDescriptor = function()
            return {
                getForename = function() return "Alexandra" end,
                getSurname = function() return "Maximilian Longsurname" end,
            }
        end,
    }
end

PsychopatzCore = { Conversation = {} }
PNC = {
    Conversation = {},
    Network = {
        ClientState = {
            playerContext = { characterUUID = "character-one" },
            playerNameKnowledge = { ["npc-one"] = true },
            snapshots = {
                ["npc-one"] = { id = "npc-one", name = "Mara" },
                ["npc-two"] = {
                    id = "npc-two",
                    name = "Jordan Longsurname",
                },
            },
        },
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    VoiceGateway = {
        GetNPCBinding = function(npcID)
            return {
                npc_uuid = tostring(npcID),
                slot = "VoiceFemale:0",
                pitch = 0,
            }
        end,
    },
}

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
-- Native shared composition loads the production response registry before
-- client presentation; the standalone fixture must honor that contract.
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
local Reactions = require "PNC/Semantics/PNC_SemanticSocialReaction"
local Presentation = require "PNC/Conversation/PNC_SemanticSpeechPresentation"
local Diary = PNC.Conversation.Diary
local received
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    received = message
end, "presentation-message-test")

local function semanticFlavor(eventID, eventType, context)
    context = context or {}
    context.eventType = eventType
    context.npcID = context.npcID or "npc-one"
    context.socialRole = context.socialRole or "neutral"
    local semantic = Reactions.Resolve({
        eventID = eventID,
        eventType = eventType,
        npcID = context.npcID,
        context = context,
    })
    T.truthy(semantic, "semantic event realization is available: " .. eventType)
    T.truthy(semantic.fallback, "semantic event has selected wording: " .. eventType)
    return {
        eventID = eventID,
        eventType = eventType,
        family = "semantic_event",
        npcID = context.npcID,
        socialRole = context.socialRole,
        llmEligible = false,
        semanticOwned = true,
        resolvedText = semantic.fallback,
        responsePlanID = semantic.responsePlanID,
        realizationFamily = semantic.realizationFamily,
        realizationID = semantic.realizationID,
        factRefs = semantic.groundedFactRefs,
        offerIDs = semantic.offerIDs,
        context = context,
        source = {
            kind = "semantic_speech",
            channel = "social_event",
            eventType = eventType,
        },
    }
end

Client.Reset()
local accepted = Presentation.Receive(semanticFlavor(
    "social:event:one",
    "zombie_kill_witnessed"
), {
    npcID = "npc-one",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.truthy(accepted, "Hoomans adapter accepts a social event")
Client.Pump(now)
T.truthy(received, "adapter reaches the Core message bus")
T.equal(received.speakerID, "npc-one", "adapter preserves NPC identity")
T.equal(received.speakerName, "Mara", "adapter resolves NPC display name")
T.truthy(received.text ~= "", "adapter resolves relationship-aware text")
T.equal(received.source.kind, "semantic_speech",
    "event delivery preserves semantic speech ownership")
T.equal(received.source.eventType, "zombie_kill_witnessed",
    "event delivery preserves the typed semantic event")
local entries = Diary.Get("npc-one")
T.equal(#entries, 1, "adapter records the delivered flavor in the diary")
T.equal(entries[1].kind, "social_flavor", "diary identifies reusable flavor")
T.equal(entries[1].eventID, "social:event:one", "diary preserves event identity")

Client.Reset()
local diaryCountBeforeInteraction = #Diary.Get("npc-one")
T.truthy(Client.Enqueue({
    eventID = "emote:event:player",
    text = "Let's camp here.",
    family = "emote_interaction",
    priority = 100,
    weight = 100,
    speakerID = "tester",
    speakerKind = "player",
    source = { kind = "emote_interaction" },
}), "interaction line enters the shared queue")
Client.Pump(now)
T.equal(#Diary.Get("npc-one"), diaryCountBeforeInteraction,
    "ambient presentation ignores queued player interaction lines")

Client.Reset()
received = nil
local teammateAccepted = Presentation.Receive(semanticFlavor(
    "social:event:teammate",
    "witnessed_teammate_hurt",
    { victimNPCID = "npc-two" }
), {
    npcID = "npc-one",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.truthy(teammateAccepted, "teammate flavor is accepted")
Client.Pump(now)
T.truthy(received, "teammate flavor reaches the Core message bus")
T.equal(received.source.kind, "semantic_speech",
    "teammate delivery preserves semantic speech ownership")
T.equal(received.source.eventType, "witnessed_teammate_hurt",
    "teammate delivery preserves its typed semantic event")

local capturedBinding
local capturedSpeechMessage
Client.SetLLMProvider(function(item, complete)
    capturedBinding = item.context and item.context.voiceBinding
    if item.context and item.context.eventType == "player_spoke" then
        capturedSpeechMessage = item.context.playerMessage
    end
    complete("Stay close.", { ttsManaged = true })
    return true
end)
Client.Reset()
local voiceFlavor = semanticFlavor(
    "social:event:voice-binding",
    "zombie_kill_witnessed"
)
voiceFlavor.llmEligible = true
local llmAccepted = Presentation.Receive(voiceFlavor, {
    npcID = "npc-one",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.truthy(llmAccepted, "voice-bound flavor is accepted")
Client.Pump(now)
T.truthy(capturedBinding, "ambient flavor resolves an NPC voice binding")
T.equal(capturedBinding.slot, "VoiceFemale:0",
    "ambient flavor preserves the reusable voice slot")

Client.Reset()
received = nil
local speechAccepted = Presentation.ReceivePlayerSpeech(
    getSpecificPlayer(),
    "The road is clear.",
    { targets = { { id = "npc-one", name = "Mara" } } }
)
T.truthy(speechAccepted, "player speech enters local social flavor")
Client.Pump(now)
T.equal(capturedSpeechMessage, "The road is clear.",
    "PBrainZ receives the raw player speech context")
T.truthy(received, "player speech reaction reaches the Core message bus")
T.equal(received.speakerID, "npc-one",
    "player speech reaction is voiced by the colonist")
Client.SetLLMProvider(nil)

EventBus.clearOwner("presentation-message-test")
T.finish("pnc_semantic_speech_presentation_smoke")
