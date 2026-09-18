local T = require "tests/support/test"
T.addPackagePaths()

local now = 0
local setOrders = 0
local broadcasts = 0
local records = {}
local bodies = {}

local function bodyFor(id, x)
    local body = { id = id, x = x, y = 0, z = 0 }
    function body:getX() return self.x end
    function body:getY() return self.y end
    function body:getZ() return self.z end
    function body:isDead() return false end
    return body
end

local function recordFor(id, x)
    local record = {
        id = id,
        alive = true,
        presenceState = "live",
        x = x,
        y = 0,
        z = 0,
        runtime = {},
    }
    records[id] = record
    bodies[id] = bodyFor(id, x)
    return record
end

recordFor("npc-alice", 0)
recordFor("npc-bob", 10)

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ORDER_CAMP = "camp",
    },
    Core = {
        Now = function() return now end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
    },
    CompanionCommands = {
        Get = function(commandID)
            if commandID ~= "camp" then return nil end
            return {
                buildOrder = function(_, _, options)
                    return {
                        kind = "camp",
                        x = options.x,
                        y = options.y,
                        z = options.z,
                        radius = options.campSite.radius,
                        stopDistance = options.campSite.stopDistance,
                        scope = options.zone.scope,
                        siteScope = options.zone.siteScope,
                        siteID = options.zone.siteID,
                        campfireID = options.zone.campfireID,
                        campId = options.campId,
                        placementState = options.placementState,
                        placementCampID = options.placementCampID,
                        placementIndex = options.placementIndex,
                    }
                end,
            }
        end,
    },
    OrderSystem = {
        SetOrder = function(record, orderSpec)
            setOrders = setOrders + 1
            record.orderSpec = orderSpec
        end,
    },
    Network = {
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
    },
}

local Coordinator = T.load(
    "ProjectHoomans",
    "server",
    "PNC/World/PNC_CampMovementCoordinator.lua"
)

local root = {
    kind = "camp_site",
    scope = "campfire",
    siteScope = "campfire",
    siteID = "campfire:test",
    campfireID = "campfire:test",
    x = 5,
    y = 0,
    z = 0,
    radius = 3,
    stopDistance = 1,
    label = "campfire",
}

local accepted, reason, targetIDs = Coordinator.StartGroupCamp(
    root,
    { records["npc-alice"], records["npc-bob"] },
    { revision = 4, assignments = {} },
    { campId = "camp:test", ownerKey = "player", now = 0 }
)
T.equal(accepted, 2, "coordinator accepts both live targets")
T.equal(reason, "commanded", "coordinator command result")
T.equal(#targetIDs, 2, "coordinator returns both affected ids")
T.equal(records["npc-alice"].orderSpec.placementState, "moving",
    "only the first target starts moving")
T.equal(records["npc-bob"].orderSpec.placementState, "queued",
    "later targets remain queued")
T.equal(records["npc-alice"].orderSpec.x, 5,
    "first target uses the single validated root")
T.equal(records["npc-bob"].orderSpec.x, 5,
    "later target uses the same root instead of a distant zone")
T.equal(Coordinator.IsPlacementLocked(records["npc-bob"]), true,
    "queued placement owns the behavior boundary")

Coordinator.Pump(100)
T.equal(records["npc-bob"].orderSpec.placementState, "queued",
    "queued target is not promoted before the first target arrives")
bodies["npc-alice"].x = 5
Coordinator.Pump(400)
T.equal(records["npc-alice"].orderSpec.placementState, "arrived",
    "first target reaches the root before the next movement starts")
T.equal(records["npc-bob"].orderSpec.placementState, "queued",
    "next target waits for the placement handoff delay")

Coordinator.Pump(800)
T.equal(records["npc-bob"].orderSpec.placementState, "moving",
    "next target is promoted one at a time")
bodies["npc-bob"].x = 5
Coordinator.Pump(1200)
T.equal(records["npc-bob"].orderSpec.placementState, "arrived",
    "second target reaches the same root")
Coordinator.Pump(1600)
T.equal(Coordinator.PendingCount, 0,
    "completed placement session is removed from the pending queue")
T.equal(Coordinator.IsPlacementLocked(records["npc-alice"]), false,
    "arrived target is released from the movement lock")
T.equal(Coordinator.IsPlacementLocked(records["npc-bob"]), false,
    "all arrived targets are released from the movement lock")
T.equal(setOrders, 5, "one order is written per placement state transition")
T.equal(broadcasts, 5, "placement transitions use normal record broadcast")

-- A blocked/failed placement must release the single movement slot so the
-- next member can be attempted, while the failed member stays held rather
-- than starting an unbounded fallback path of its own.
local blocked = true
PNC.PathService = {
    GetMovementRecoveryState = function()
        if blocked then
            return { phase = "blocked", lastProgressAt = 0 }
        end
        return { phase = "idle", lastProgressAt = now }
    end,
}
recordFor("npc-charlie", 0)
recordFor("npc-dana", 10)
local failedAccepted, failedReason = Coordinator.StartGroupCamp(
    root,
    { records["npc-charlie"], records["npc-dana"] },
    { revision = 5, assignments = {} },
    { campId = "camp:failure", ownerKey = "player", now = 0 }
)
T.equal(failedAccepted, 2, "failure scenario accepts both live targets")
T.equal(failedReason, "commanded", "failure scenario command result")
Coordinator.Pump(100)
Coordinator.Pump(10200)
T.equal(records["npc-charlie"].orderSpec.placementState, "failed",
    "blocked placement is marked failed")
T.equal(records["npc-dana"].orderSpec.placementState, "queued",
    "failure does not start the next target in the same tick")
blocked = false
Coordinator.Pump(10600)
T.equal(records["npc-dana"].orderSpec.placementState, "moving",
    "next target starts after the failed placement handoff")
bodies["npc-dana"].x = 5
Coordinator.Pump(10900)
T.equal(records["npc-dana"].orderSpec.placementState, "arrived",
    "replacement target reaches the shared root")
Coordinator.Pump(11300)
T.equal(Coordinator.PendingCount, 0,
    "failure session also drains completely")
T.equal(Coordinator.IsPlacementLocked(records["npc-charlie"]), true,
    "failed target remains held for explicit recovery")

-- Reassigning a queued member must not be overwritten when its old session
-- reaches that queue slot.
recordFor("npc-eve", 0)
recordFor("npc-frank", 10)
local replacedAccepted = Coordinator.StartGroupCamp(
    root,
    { records["npc-eve"], records["npc-frank"] },
    { revision = 6, assignments = {} },
    { campId = "camp:replace", ownerKey = "player", now = 0 }
)
T.equal(replacedAccepted, 2, "replacement scenario accepts both targets")
records["npc-frank"].orderSpec = { kind = "follow" }
records["npc-frank"].runtime.campPlacement = nil
bodies["npc-eve"].x = 5
Coordinator.Pump(100)
Coordinator.Pump(500)
T.equal(records["npc-frank"].orderSpec.kind, "follow",
    "queued reassignment is not overwritten by camp promotion")
Coordinator.Pump(750)
T.equal(Coordinator.PendingCount, 0,
    "reassigned queue entry is skipped without wedging the session")

T.finish("pnc_camp_movement_coordinator_smoke")
