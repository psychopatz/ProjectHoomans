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
local NameplateSpeech = require "PNC/UI/Nameplates/PNC_NameplateSpeech"
-- Native shared composition loads the production response registry before
-- client presentation; the standalone fixture must honor that contract.
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
local Reactions = require "PNC/Semantics/PNC_SemanticSocialReaction"
local Presentation = require "PNC/Conversation/PNC_SocialFlavorPresentation"

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
local warningText = string.lower(message.text or "")
T.equal(message.speakerID, "npc-one", "warning preserves NPC speaker identity")
T.equal(message.presentationState.conversationUI, true,
    "warning targets the conversation UI")
T.equal(message.presentationState.nameplate, true,
    "warning remains visible after the conversation view closes")
T.equal(message.presentationState.interrupt, true,
    "warning can interrupt ordinary speech")
T.equal(message.source.eventType, "conversation_safety",
    "warning keeps its social flavor event type")
T.equal(message.source.priority, 100,
    "warning uses the critical social flavor priority")
T.truthy(
    string.find(warningText, "safe", 1, true)
        or string.find(warningText, "danger", 1, true)
        or string.find(warningText, "threat", 1, true)
        or string.find(warningText, "watch", 1, true)
        or string.find(warningText, "alert", 1, true)
        or string.find(warningText, "guard", 1, true),
    "warning explains that danger prevents the conversation"
)
PsychopatzCore.Conversation.instance = nil
T.truthy(NameplateSpeech.Get("npc-one"),
    "danger warning remains available to the NPC nameplate")
PsychopatzCore.Conversation.instance = view
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

local semantic = Reactions.Resolve({
    eventID = "conversation-safety:semantic-check",
    eventType = "conversation_safety",
    npcID = "npc-one",
    context = {
        eventType = "conversation_safety",
        npcID = "npc-one",
        socialRole = "neutral",
    },
})
T.truthy(semantic, "danger warning is selected by the semantic catalog")
T.equal(semantic.realizationFamily, "semantic.conversation.safety",
    "danger warning reports semantic pool ownership")
T.truthy(semantic.responsePlan,
    "danger warning carries a semantic response plan")

EventBus.clearOwner("conversation-safety-feedback-test")
T.finish("pnc_conversation_safety_feedback_smoke")
