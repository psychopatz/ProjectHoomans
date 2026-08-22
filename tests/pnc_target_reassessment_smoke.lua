local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
PNC = {
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        TARGET_REASSESS_MS = 350,
        TARGET_SWITCH_DISTANCE_RATIO = 0.72,
        TARGET_RECENT_ATTACKER_MS = 5000,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
    },
    SpatialIndex = {},
    Stealth = {},
    Registry = {
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
}

dofile(ROOT .. "Perception/PNC_Perception.lua")

local player = { kind = "player", onlineID = 1, x = 1, y = 0, distSq = 1, visible = true }
local attacker = { kind = "npc", id = "attacker", x = 4, y = 0, distSq = 16, visible = true, threatening = true }
assertEqual(
    PNC.Perception.SelectPreferredTarget(player, attacker),
    attacker,
    "nearby active threat outranks a closer non-threatening enemy"
)
attacker.distSq = 49
assertEqual(
    PNC.Perception.SelectPreferredTarget(player, attacker),
    player,
    "distant attacker does not override immediate target"
)

local source = { id = "source", x = 0, y = 0, runtime = {} }
PNC.Perception.RememberAttacker(source, {
    attackerKind = "npc",
    attackerID = "attacker",
}, now)
attacker.distSq = 16
attacker.threatening = nil
assertEqual(
    PNC.Perception.IsTargetThreatening(source, attacker),
    true,
    "recent NPC attacker is remembered as a threat"
)
PNC.Perception.RememberAttacker(source, {
    attackerKind = "zombie",
    attackerZombieId = "zed_attacker",
}, now)
assertEqual(
    PNC.Perception.IsTargetThreatening(source, {
        kind = "zombie",
        zombieId = "zed_attacker",
    }),
    true,
    "recent zombie attacker is remembered by stable spatial id"
)
source.runtime.recentThreat.expiresAt = now - 1
PNC.Registry.Get = function(id)
    if id == "attacker" then
        return {
            runtime = {
                target = { kind = "npc", id = "source" },
            },
        }
    end
    return nil
end
assertEqual(
    PNC.Perception.IsTargetThreatening(source, attacker),
    true,
    "enemy NPC actively targeting source is an immediate threat"
)

dofile(ROOT .. "Behaviors/PNC_Behavior_Targeting.lua")

local Targeting = PNC.BehaviorTargeting
local zombieThreat = {
    kind = "zombie",
    zombieId = "zed_attacker",
    x = 2,
    y = 0,
    distSq = 4,
    visible = true,
    threatening = true,
}
PNC.Perception.FindImmediateZombieThreat = function()
    return zombieThreat
end
assertEqual(
    Targeting.ResolveImmediateZombieThreat(source),
    zombieThreat,
    "immediate zombie threat is available to hostile arbitration"
)
local current = {
    kind = "player",
    onlineID = 1,
    x = 8,
    y = 0,
    distSq = 64,
    visible = true,
    threatening = false,
}
local freshThreat = {
    kind = "npc",
    id = "attacker",
    x = 3,
    y = 0,
    distSq = 9,
    visible = true,
    threatening = true,
}

Targeting.UpdateTargetFromWorld = function(_, target) return target end
PNC.Perception.ResolveHostileTarget = function() return freshThreat end
PNC.Perception.ResolveCompanionTarget = function() return freshThreat end
PNC.Perception.ResolveRoamingTarget = function() return freshThreat end

source.runtime.target = current
source.runtime.nextTargetReassessAt = 0
assertEqual(Targeting.ResolveHostileEngageTarget(source), freshThreat, "hostile target reassessment")

source.runtime.target = current
source.runtime.nextTargetReassessAt = 0
assertEqual(Targeting.ResolveCompanionEngageTarget(source), freshThreat, "companion target reassessment")

source.runtime.target = current
source.runtime.nextTargetReassessAt = 0
assertEqual(Targeting.ResolveRoamingEngageTarget(source, 12), freshThreat, "roaming target reassessment")

source.runtime.target = current
source.runtime.nextTargetReassessAt = now + 100
assertEqual(Targeting.ResolveHostileEngageTarget(source), current, "reassessment interval prevents target flicker")

local distantThreat = {
    kind = "npc",
    id = "distant_attacker",
    x = 7,
    y = 0,
    distSq = 49,
    visible = true,
    threatening = true,
}
local nearbyPassive = {
    kind = "player",
    onlineID = 2,
    x = 2,
    y = 0,
    distSq = 4,
    visible = true,
    threatening = false,
}
assertEqual(
    Targeting.SelectReassessedTarget(source, nearbyPassive, distantThreat),
    nearbyPassive,
    "distant attacker does not force an irrational target switch"
)

print("pnc_target_reassessment_smoke: ok")
