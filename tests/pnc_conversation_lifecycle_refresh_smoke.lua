local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

local now = 1000
local beginCalls = 0
local beginResult = true
local beginReason

local Safety = {
    Check = function() return nil end,
    ResolveActors = function(spec)
        return spec.player, spec.zombie, spec.record, spec.npcID
    end,
    GetMaximumDistance = function() return 12 end,
    GetDangerRadius = function() return 20 end,
    GuardsThreats = function() return true end,
    DescribeAvailability = function()
        return {
            npcID = "npc-refresh",
            liveBodyPresent = true,
            liveBodyAlive = true,
            registryBodyPresent = true,
            presenceBodyPresent = true,
            presenceBodyAlive = true,
            cachedBodyPresent = true,
            snapshotPresent = true,
            snapshotAlive = true,
            snapshotPosition = true,
            snapshotConversation = true,
            networkClient = false,
            presenceState = "present",
            recordAlive = true,
            bodyLease = true,
            presenceRevision = 1,
        }
    end,
}

package.preload["PNC/Conversation/PNC_ConversationSafety"] =
    function()
        PNC.Conversation.Safety = Safety
        return Safety
    end
package.preload["PNC/Conversation/PNC_ConversationFarewell"] =
    function()
        PNC.Conversation.Farewell = {}
        return PNC.Conversation.Farewell
    end

isClient = function() return false end
PNC = {
    Core = { Now = function() return now end },
    Conversation = {},
    ConversationScene = {
        CMD_BEGIN = "conversationBegin",
        ID = "social.conversation",
        Begin = function()
            beginCalls = beginCalls + 1
            if beginResult then return true, { token = "lease" } end
            return false, beginReason or "invalid_lease"
        end,
    },
}

local Lifecycle = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationLifecycle.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationLifecycle_Create_Update.lua"
)

local state = {
    npcID = "npc-refresh",
    token = "conversation-token",
    started = true,
    lastHeartbeatAt = 0,
    nextSafetyCheckAt = 999999,
}
local spec = {
    npcID = "npc-refresh",
    player = {},
    zombie = {},
    record = { alive = true },
    context = {},
}
local view = { spec = spec }

local refreshed, refreshReason = Lifecycle.Internal.RefreshNow(
    view, spec, state
)
T.truthy(refreshed, "active native conversation renews its lease on demand")
T.equal(refreshReason, nil, "successful lease renewal has no rejection reason")
T.equal(beginCalls, 1, "request-time renewal reaches the authoritative scene once")
T.equal(state.lastHeartbeatAt, now,
    "successful request-time renewal advances the heartbeat timestamp")

beginResult = false
beginReason = "invalid_lease"
now = now + 1000
state.lastHeartbeatAt = 1000
local renewed, renewedReason = Lifecycle.Internal.RefreshNow(
    view, spec, state
)
T.falsy(renewed,
    "failed renewal interrupts the native update instead of masking expiry")
T.equal(renewedReason, "invalid_lease",
    "failed renewal preserves the authoritative rejection reason")
T.equal(state.lastHeartbeatAt, 1000,
    "failed renewal does not claim a fresh heartbeat")
local updateReason = Lifecycle.Internal.CreateUpdate(view, spec, state)
T.equal(updateReason, "invalid_lease",
    "native lifecycle update surfaces the failed renewal")

-- Closing is a public operation independent of start/heartbeat support.
local closeOrder = {}
local ended
PNC.ConversationScene.End = function(record, zombie, token, reason, options)
    closeOrder[#closeOrder + 1] = "scene"
    ended = { record, zombie, token, reason, options }
end
PNC.Conversation.Farewell.Schedule = function()
    closeOrder[#closeOrder + 1] = "farewell"
end
PNC.Conversation.Memory = { Events = {
    GetConversationTopicMask = function(session, limit)
        T.equal(limit, 64, "close topic classification stays bounded")
        return 7
    end,
} }
package.preload["PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"] = function() return true end
PsychopatzCore = { Conversation = { History = { Clear = function()
    closeOrder[#closeOrder + 1] = "clear"
end } } }
local resetCount = 0
local session = {
    namespace = "ProjectHoomans", npcID = spec.npcID,
    semanticDialogueContext = { Reset = function()
        T.equal(closeOrder[#closeOrder], "clear", "history is cleared before semantic reset")
        resetCount = resetCount + 1
    end },
    semanticDialoguePending = {}, semanticDialogueRouter = {},
    semanticActorConversationService = {}, semanticDialogueState = {},
    queue = { "pending" }, busy = true, llmPending = true,
}
view.session = session
view.lastSemanticDialogueResult = {}
view.lastSemanticActionResult = {}
view.historyPart = {
    messages = { { source = { eventType = "conversation_safety" } }, { text = "old" } },
    setMessages = function(self, messages)
        T.equal(view.session.semanticDialogueContext, nil,
            "semantic state is cleared before history presentation")
        T.equal(PNC.Semantics.DialogueInput.ActiveView, view,
            "active semantic view remains until presentation cleanup finishes")
        self.messages = messages
    end,
    setTyping = function(self, speaker) self.typingSpeaker = speaker end,
}
PNC.Semantics = { DialogueInput = { ActiveView = view } }
Lifecycle.Create().finish(view, spec, state, "closed")
T.equal(table.concat(closeOrder, ","), "farewell,scene,clear",
    "close schedules outcome, ends authority, then clears working state")
T.equal(ended[1], spec.record, "SP closes the canonical record")
T.equal(ended[3], state.token, "SP preserves scene lease token")
T.equal(ended[4], "conversation_closed", "SP preserves close reason")
T.equal(ended[5].memoryTopicMask, 7, "SP forwards bounded topic mask")
T.equal(resetCount, 1, "close resets semantic working context exactly once")
T.truthy(session.closed and session.conversationMemoryClosed, "session is closed")
T.equal(session.semanticDialogueRouter, nil, "router is released")
T.equal(session.semanticActorConversationService, nil, "actor context is released")
T.equal(#session.queue, 0, "queued work is cleared")
T.falsy(session.busy or session.llmPending, "pending flags clear")
T.equal(PNC.Semantics.DialogueInput.ActiveView, nil, "active view is released")
T.equal(view.lastSemanticActionResult, nil, "action presentation is released")
T.equal(#view.historyPart.messages, 0, "ordinary close clears visible history")

local sent
isClient = function() return true end
sendClientCommand = function(module, command, payload) sent = { module, command, payload } end
PNC.ConversationScene.CMD_END = "conversationEnd"
PNC.SemanticSpeechPresentation = { EnqueueConversationSafety = function() return true end }
PNC.Semantics.DialogueInput.ActiveView = view
view.historyPart.messages = {
    { source = { eventType = "conversation_safety" } }, { text = "old" },
}
ended = nil
Lifecycle.Finish(view, spec, state, "danger")
T.equal(ended, nil, "MP client never closes authoritative state locally")
T.equal(sent[2], "conversationEnd", "MP requests scene close")
T.equal(sent[3].token, state.token, "MP preserves authority token")
T.equal(sent[3].memoryTopicMask, 7, "MP forwards same bounded memory facts")
T.falsy(sent[3].enforceDistance, "active scene close keeps opening-only distance rule")
T.equal(#view.historyPart.messages, 1, "danger close preserves only safety feedback")
T.equal(view.historyPart.messages[1].source.eventType, "conversation_safety",
    "retained line is safety presentation")

T.finish("pnc_conversation_lifecycle_refresh_smoke")
