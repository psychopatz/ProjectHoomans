local T = require "tests/support/test"

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local function distance(x1, y1, x2, y2)
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local threatActive = false
local movement
local halted = false
local cleared = false
local campWakeCause

PNC = {
    Const = {
        ORDER_CAMP = "camp",
        ORDER_GUARD = "guard",
        CAMP_RADIUS = 3,
        CAMP_STOP_DISTANCE = 0.45,
        CAMP_ENGAGE_RADIUS = 3,
    },
    Core = {
        Now = function() return 1000 end,
        DeepCopy = copy,
        Distance = distance,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
        MarkDirty = function() end,
    },
    Tasking = {
        Events = {
            Emit = function(_, details) campWakeCause = details.cause end,
        },
    },
    BehaviorCommon = {
        ClearCombatTarget = function() cleared = true end,
        HaltMovement = function() halted = true end,
        MoveRecord = function(_, _, x, y, z, mode, stopDistance, reason)
            movement = {
                x = x, y = y, z = z, mode = mode,
                stopDistance = stopDistance, reason = reason,
            }
        end,
    },
    BehaviorCompanion = {
        Internal = {
            TryRespondToThreat = function()
                return threatActive
            end,
        },
    },
    Animation = { Apply = function() end },
    NavigationRouter = { Clear = function() end },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_BehaviorRegistry.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_JobSystem.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Orders/PNC_OrderSystem.lua")
local AtCamp = T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_AtCamp.lua")

T.equal(PNC.JobSystem.OrderJobs.camp, "AtCamp",
    "camp order selects the dedicated job")
T.truthy(PNC.BehaviorRegistry.Handlers.AtCamp,
    "camp behavior is registered without changing the coordinator")

local record = {
    id = "npc:camp",
    alive = true,
    x = 20,
    y = 30,
    z = 0,
    anchorX = 20,
    anchorY = 30,
    anchorZ = 0,
    runtime = {},
}

PNC.OrderSystem.SetOrder(record, {
    kind = "camp", radius = 4,
})
T.equal(record.orderSpec.kind, "camp", "camp order persists through normalization")
T.equal(record.orderSpec.x, 20, "camp defaults its anchor to the NPC position")
T.equal(record.orderSpec.y, 30, "camp defaults its anchor to the NPC position")
T.equal(record.orderSpec.radius, 4, "camp radius persists through normalization")
T.equal(campWakeCause, "CAMP_ENTERED",
    "entering camp wakes task evaluation after the camp snapshot boundary")
T.equal(PNC.JobSystem.Select(record), "AtCamp",
    "camp order resolves through the normal job selector")

AtCamp.Tick(record)
T.equal(record.activeBehavior, "AtCamp", "camp behavior idles at its anchor")
T.truthy(halted, "camp behavior halts inside the camp radius")
T.truthy(cleared, "camp behavior clears stale combat state while idling")

record.x = 26
movement = nil
halted = false
AtCamp.Tick(record)
T.equal(record.activeBehavior, "AtCamp:returning",
    "camp behavior returns an NPC that leaves the camp radius")
T.equal(movement.reason, "camp_anchor", "camp return uses the camp movement lane")
T.equal(movement.mode, "walk", "camp return uses walking movement")
T.equal(halted, false, "camp return does not halt before reaching camp")

threatActive = true
record.x = 20
AtCamp.Tick(record)
T.equal(record.activeBehavior, "AtCamp:combat",
    "camp behavior hands nearby threats to companion combat")

T.finish("pnc_camp_foundation_smoke")
