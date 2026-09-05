local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
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
local Presentation = require "PNC/Conversation/PNC_SocialFlavorPresentation"
local Diary = PNC.Conversation.Diary
local received
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    received = message
end, "presentation-message-test")

Client.Reset()
local accepted = Presentation.Receive({
    eventID = "social:event:one",
    flavorID = "social.witnessed_player_kill",
    family = "combat_commentary",
    npcID = "npc-one",
    socialRole = "neutral",
    llmEligible = false,
}, {
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
T.truthy(string.find(received.text, "Alexandra", 1, true),
    "dialogue addresses the player by first name")
T.falsy(string.find(received.text, "Maximilian", 1, true),
    "dialogue does not repeat the player's surname")
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
local teammateAccepted = Presentation.Receive({
    eventID = "social:event:teammate",
    flavorID = "social.witnessed_teammate_hurt",
    family = "combat_commentary",
    npcID = "npc-one",
    socialRole = "neutral",
    llmEligible = false,
    context = { victimNPCID = "npc-two" },
}, {
    npcID = "npc-one",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.truthy(teammateAccepted, "teammate flavor is accepted")
Client.Pump(now)
T.truthy(received, "teammate flavor reaches the Core message bus")
T.truthy(string.find(received.text, "Jordan", 1, true),
    "teammate flavor addresses the injured NPC by first name")
T.falsy(string.find(received.text, "Longsurname", 1, true),
    "teammate flavor does not repeat the injured NPC surname")

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
local llmAccepted = Presentation.Receive({
    eventID = "social:event:voice-binding",
    flavorID = "social.witnessed_player_kill",
    family = "voice_binding",
    npcID = "npc-one",
    socialRole = "neutral",
    llmEligible = true,
}, {
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
T.finish("pnc_social_flavor_presentation_smoke")
