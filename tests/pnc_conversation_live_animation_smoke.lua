local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

local FILE = T.path(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationLiveAnimation.lua"
)

local subscribed
local sent = {}
local requested = {}
local definition = {
    id = "greeting.wavehi",
}
local messageModule = {
    EVENT_TYPE = "Conversation.Message",
}
local eventBus = {
    clearOwner = function() end,
    subscribe = function(_, callback, owner)
        subscribed = { callback = callback, owner = owner }
    end,
}

local originalRequire = require
require = function(name)
    if name == "PsychopatzCore/Conversation/PsychopatzConversationMessage" then
        return messageModule
    end
    if name == "PsychopatzCore/Events/PC_EventBus" then
        return eventBus
    end
    return originalRequire(name)
end

local body = {}
local record = { id = "npc-1", presenceState = "live" }

PsychopatzCore = {
    Conversation = {},
    Events = eventBus,
}
PsychopatzCore.Conversation.Message = messageModule

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_NPC_PRESENTATION_ANIMATION = "NPCPresentationAnimation",
    },
    Core = {
        Now = function() return 1000 end,
        IsClientOnly = function() return false end,
    },
    PresentationAnimations = {
        Get = function(animationID)
            if animationID == "greeting.wavehi" then return definition end
            return nil
        end,
        Request = function(targetRecord, targetBody, animationID, options)
            requested[#requested + 1] = {
                record = targetRecord,
                body = targetBody,
                animationID = animationID,
                options = options,
            }
            return true, "started"
        end,
    },
    Registry = {
        Get = function(npcID)
            if npcID == "npc-1" then return record end
            return nil
        end,
        GetLiveZombie = function(npcID)
            if npcID == "npc-1" then return body end
            return nil
        end,
    },
}

local Bridge = T.load(FILE)
require = originalRequire
T.truthy(subscribed, "conversation bridge did not subscribe to messages")

local accepted, reason = Bridge.HandleMessage({
    speakerKind = "npc",
    speakerID = "npc-1",
    messageID = "message-1",
    portraitAnimation = "greeting.wavehi",
})
T.truthy(accepted, "NPC conversation message did not reach live presentation")
T.equal(reason, "started", "live presentation returned the wrong result")
T.equal(#requested, 1, "NPC conversation message was not presented once")
T.equal(requested[1].options.eventID, "message-1",
    "conversation message identity was not forwarded")

local duplicate, duplicateReason = Bridge.HandleMessage({
    speakerKind = "npc",
    speakerID = "npc-1",
    messageID = "message-1",
    portraitAnimation = "greeting.wavehi",
})
T.falsy(duplicate, "conversation message was delivered twice")
T.equal(duplicateReason, "duplicate_event",
    "conversation duplicate did not report its reason")
T.equal(#requested, 1, "duplicate conversation message reached live presentation")

local ignored, ignoredReason = Bridge.HandleMessage({
    speakerKind = "player",
    speakerID = "npc-1",
    messageID = "player-message",
    portraitAnimation = "greeting.wavehi",
})
T.falsy(ignored, "player conversation message was treated as an NPC reaction")
T.equal(ignoredReason, "not_npc_message",
    "non-NPC conversation message reported the wrong reason")

PNC.Core.IsClientOnly = function() return true end
PsychopatzCore.Conversation.instance = {
    spec = {
        npcID = "npc-1",
        context = {
            conversationLifecycleState = { token = "lease-1" },
        },
    },
}
sendClientCommand = function(module, command, payload)
    sent[#sent + 1] = {
        module = module,
        command = command,
        payload = payload,
    }
end

local queued, queuedReason = Bridge.HandleMessage({
    speakerKind = "npc",
    speakerID = "npc-1",
    messageID = "message-2",
    presentationState = { liveAnimation = "greeting.wavehi" },
})
T.truthy(queued, "client-only conversation message was not queued")
T.equal(queuedReason, "network_queued",
    "client-only conversation message returned the wrong result")
T.equal(#sent, 1, "client-only conversation message was not sent")
T.equal(sent[1].payload.token, "lease-1",
    "conversation lease token was not forwarded")

PsychopatzCore.Conversation.instance = nil
local headlessQueued, headlessReason = Bridge.HandleMessage({
    speakerKind = "npc",
    speakerID = "npc-1",
    messageID = "message-3",
    source = { conversationToken = "headless-lease" },
    portraitAnimation = "greeting.wavehi",
})
T.truthy(headlessQueued, "headless LLM animation was not queued")
T.equal(headlessReason, "network_queued",
    "headless LLM animation returned the wrong result")
T.equal(#sent, 2, "headless LLM animation was not sent")
T.equal(sent[2].payload.token, "headless-lease",
    "headless LLM conversation token was not forwarded")

T.finish("pnc_conversation_live_animation_smoke")
