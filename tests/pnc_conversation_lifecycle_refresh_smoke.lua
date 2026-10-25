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

T.finish("pnc_conversation_lifecycle_refresh_smoke")
