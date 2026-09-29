local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local loggedEvents = {}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_OWNER_RESOLVE_MAX_ATTEMPTS = 5,
    },
    Core = {},
    BehaviorCommon = {},
    BehaviorCompanion = { Internal = {} },
    PerformanceScalingDiagnostics = {
        IsFollowerPresenceAuditEnabled = function() return true end,
        LogFollowerPresence = function(eventName, fields)
            loggedEvents[#loggedEvents + 1] = {
                event = tostring(eventName),
                fields = fields or {},
            }
        end,
    },
}

local function loggedField(fragment)
    local index
    local field
    local entry
    for index = 1, #loggedEvents do
        entry = loggedEvents[index]
        for _, field in ipairs(entry.fields) do
            if tostring(field) == fragment then return entry.event end
        end
    end
    return nil
end

local function loggedEvent(name)
    local index
    for index = 1, #loggedEvents do
        if loggedEvents[index].event == name then return true end
    end
    return false
end

local now = 0
local owner = {
    x = 30,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getUsername = function() return "owner" end,
    getOnlineID = function() return 42 end,
}

PNC.Core.Now = function() return now end
PNC.Core.Distance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end
PNC.BehaviorCompanion.Internal.GetFollowState = function(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState or {}
    return record.runtime.followState
end
PNC.BehaviorCommon.GetOwner = function(record)
    return record.testOwner
end
local moveRefusalReason = nil
PNC.BehaviorCommon.MoveRecord = function(
    record, _, targetX, targetY, targetZ
)
    if moveRefusalReason ~= nil then
        return false, moveRefusalReason
    end
    local dx = targetX - record.x
    local dy = targetY - record.y
    local length = math.sqrt(dx * dx + dy * dy)
    local step = math.min(5, length)
    if length > 0 then
        record.x = record.x + (dx / length) * step
        record.y = record.y + (dy / length) * step
    end
    record.z = targetZ
    return true, "abstract_move"
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua"
)

local record = {
    id = "abstract_follower",
    x = 0,
    y = 0,
    z = 0,
    anchorX = -20,
    anchorY = 0,
    anchorZ = 0,
    ownerUsername = "owner",
    ownerOnlineID = 42,
    orderSpec = { kind = "follow" },
    runtime = {
        target = { kind = "zombie" },
        attackAction = { finishAt = 9000 },
    },
    testOwner = owner,
}

now = 3000
PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
T.truthy(record.x > 0, "abstract follower did not move toward its owner")
T.equal(record.activeJob, "FollowOwner", "abstract follower job")
T.equal(
    record.activeBehavior,
    "FollowOwner:abstract",
    "abstract follower behavior"
)
T.equal(record.runtime.followState.mode, "abstract_follow",
    "abstract follower mode")
T.falsy(record.runtime.target, "abstract follower clears stale combat target")
T.falsy(record.runtime.attackAction,
    "abstract follower clears stale attack action")

-- A stationary facility lease halts the move inside MoveRecord. The follower
-- must report the refusal instead of pretending it moved.
moveRefusalReason = "sleep_hold"
record.runtime.facilityActivity = { capability = "sleep", phase = "SLEEPING" }
loggedEvents = {}
now = 5000
local heldX = record.x
local heldY = record.y
PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
T.near(record.x, heldX, 0.0001, "held follower must not move on refusal")
T.near(record.y, heldY, 0.0001, "held follower must not move on refusal")
T.truthy(loggedEvent("abstract_follow_move_held"),
    "a refused abstract follow move must be reported")
T.equal(loggedField("moved=false"), "abstract_follow_tick",
    "the follower audit must report the real displacement")
moveRefusalReason = nil
record.runtime.facilityActivity = nil

-- An unresolved owner must not silently walk to the anchor: for a colonist the
-- anchor is the base it already occupies, which looks like "following" while
-- nothing moves. Retry resolution first, wake presence, then fall back.
record.testOwner = nil
record.runtime.followOwnerResolveAttempts = nil
local anchorStartX = record.x
local attempts
for attempts = 1, 5 do
    now = now + 3000
    local attemptX = record.x
    PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
    T.near(record.x, attemptX, 0.0001,
        "unresolved owner must not anchor-walk during the retry budget")
    T.equal(record.activeBehavior, "FollowOwner:owner_unresolved",
        "unresolved owner behavior")
    T.equal(record.runtime.followState.mode, "owner_unresolved",
        "unresolved owner follow mode")
    T.truthy(record.runtime.forcePresenceCheck == true,
        "unresolved owner must wake the presence pass")
end
-- The next attempt exceeds the budget and falls back to the anchor.
now = now + 3000
PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
T.truthy(record.x < anchorStartX,
    "ownerless abstract follower still returns to its anchor after the retry")
T.equal(record.runtime.followState.mode, "returning_to_anchor",
    "ownerless abstract follower mode after the retry budget")

T.finish("pnc_abstract_follow_smoke")
