local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "conversation-safety-feedback-test" end
getText = function(key) return key end
Events = { OnTick = { Add = function() end } }

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getUsername = function() return "tester" end,
    getDisplayName = function() return "Alexandra Longsurname" end,
    getDescriptor = function()
        return {
            getForename = function() return "Alexandra" end,
            getSurname = function() return "Longsurname" end,
        }
    end,
}

PsychopatzCore = { Conversation = {} }
PNC = {
    Conversation = {},
    Core = { Now = function() return now end },
    Network = {
        ClientState = {
            snapshots = {
                ["npc-one"] = { id = "npc-one", name = "Mara" },
            },
        },
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
        IsNameKnown = function() return true end,
    },
}
getSpecificPlayer = function() return player end

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
local Presentation = require "PNC/Conversation/PNC_SocialFlavorPresentation"
local Flavor = require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

local view = {
    spec = { npcID = "npc-one" },
    historyPart = { messages = {} },
}
function view.historyPart:addMessage(message)
    self.messages[#self.messages + 1] = message
end
PsychopatzCore.Conversation.instance = view

Client.Reset()
local state = { npcID = "npc-one", token = "npc-one:1000:7" }
local accepted, reason = Presentation.EnqueueConversationSafety(
    {
        npcID = "npc-one",
        context = {
            player = player,
            npcType = "neutral",
        },
    },
    state,
    "danger"
)
T.truthy(accepted, "danger warning is delivered through social flavor")
T.equal(reason, "delivered", "danger warning is delivered immediately")
T.equal(#view.historyPart.messages, 1,
    "danger warning reaches the closing conversation history")
local message = view.historyPart.messages[1]
T.equal(message.speakerID, "npc-one", "warning preserves NPC speaker identity")
T.equal(message.presentationState.conversationUI, true,
    "warning targets the conversation UI")
T.equal(message.source.eventType, "conversation_safety",
    "warning keeps its social flavor event type")
T.contains(string.lower(message.text), "stay vigilant",
    "warning tells the player to stay vigilant")
T.equal(state.safetyFeedbackShown, true,
    "warning is marked as presented")
T.falsy(Presentation.EnqueueConversationSafety(
    { npcID = "npc-one", context = { player = player } },
    state,
    "danger"
), "same safety interruption is not repeated")

local sceneEnded = false
PNC.ConversationScene = {
    End = function() sceneEnded = true end,
}
isClient = function() return false end
T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_ConversationLifecycle.lua")
local lifecycle = PNC.Conversation.Lifecycle.Create()
local dangerousRecord = { runtime = { target = {} }, health = {} }
local dangerousNpc = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
local dangerousSpec = {
    npcID = "npc-one",
    character = dangerousNpc,
    context = {
        player = player,
        npcType = "neutral",
        entry = {
            id = "npc-one",
            zombie = dangerousNpc,
            record = dangerousRecord,
        },
    },
}
local started, startReason = lifecycle.begin(view, dangerousSpec)
T.equal(started, false, "danger blocks the initial conversation open")
T.equal(startReason, "danger", "initial conversation close keeps its reason")
view.historyPart.messages = {}
PsychopatzCore.Conversation.instance = view
Client.Reset()
lifecycle.finish(
    view,
    dangerousSpec,
    nil,
    "danger"
)
T.equal(#view.historyPart.messages, 1,
    "automatic danger close emits the safety warning")
T.equal(sceneEnded, false,
    "initial danger rejection has no scene lease to end")

sceneEnded = false
view.historyPart.messages = {}
Client.Reset()
lifecycle.finish(
    view,
    dangerousSpec,
    { npcID = "npc-one", token = "npc-one:1000:8" },
    "danger"
)
T.equal(#view.historyPart.messages, 1,
    "active danger close emits the safety warning")
T.equal(sceneEnded, true, "active danger close ends the scene lease")

local definition = Flavor.Get("social.conversation_safety_danger")
T.truthy(definition, "danger warning is registered in the flavor registry")
T.equal(#definition.npc, 3, "danger warning has base line variety")
T.equal(#definition.variants, 5, "danger warning has relationship variety")
for _, variant in ipairs(definition.variants) do
    T.equal(#variant.npc, 3,
        "danger warning role variant has line variety: " .. variant.id)
end

EventBus.clearOwner("conversation-safety-feedback-test")
T.finish("pnc_conversation_safety_feedback_smoke")
