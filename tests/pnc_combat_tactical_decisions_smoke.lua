local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local ROOT = SHARED_ROOT .. "PNC/Core/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local pressureCount = 0
local visiblePressureCount = 0
local hordeCount = 0
local visibleHordeCount = 0
local targetCrowd = {}
local nearbyNPCs = {}
local nearbyPlayers = {}
local moves = {}
local skillLevel = 0
local grounded = false
local canSpendAttack = true
local holds = 0

local targetZombie = {
    isDead = function() return false end,
    isOnFloor = function() return grounded end,
    isCrawling = function() return grounded end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "LIVE",
        MELEE_RANGE = 1.3,
        RANGED_RANGE = 8.5,
        RANGED_MIN_STANDOFF = 2.2,
        RANGED_PREFERRED_MIN_DISTANCE = 5,
        RANGED_RETREAT_STEP = 3.2,
        RANGED_PRESSURE_COUNT = 2,
        RANGED_AIM_BASE_MS = 460,
        RANGED_AIM_MIN_MS = 140,
        RANGED_AIM_SKILL_REDUCTION_MS = 32,
        RANGED_AIM_DISTANCE_PENALTY_MS = 22,
        RANGED_AIM_PRESSURE_PENALTY_MS = 65,
        RANGED_AIM_MOVE_TOLERANCE = 0.35,
        RANGED_FRIENDLY_FIRE_CORRIDOR = 0.62,
        RANGED_FIRE_LANE_CACHE_MS = 120,
        RANGED_FIRE_LANE_STRAFE_DISTANCE = 1.6,
        RANGED_FIRE_LANE_LOCK_MS = 500,
        RANGED_RELOAD_BREAK_DISTANCE = 2.35,
        RANGED_RELOAD_BREAK_PRESSURE_COUNT = 2,
        COMBAT_RETREAT_STAMINA_RATIO = 0.1,
        COMBAT_RETREAT_STAMINA_CURRENT = 20,
        NPC_ZOMBIE_DEFENSE_RADIUS = 2.2,
        COMBAT_KITE_NEAR_MISS_WINDOW_MS = 1400,
        COMBAT_REENGAGE_STAMINA_RATIO = 0.28,
        COMBAT_EXHAUSTED_COUNTER_MS = 1800,
        COMBAT_EXHAUSTED_REENGAGE_CURRENT = 35,
        COMBAT_RETREAT_SAFETY_BUFFER = 0.25,
        COMBAT_SURROUND_RADIUS = 1.8,
        COMBAT_SURROUND_COUNT = 3,
        COMBAT_PRESSURE_RADIUS = 3,
        COMBAT_PRESSURE_COUNT = 4,
        COMBAT_HORDE_RADIUS = 5.5,
        COMBAT_HORDE_COUNT = 4,
        COMBAT_TARGET_CROWD_RADIUS = 2.2,
        COMBAT_TARGET_CROWD_COUNT = 3,
        COMBAT_KITE_MELEE_ENTER_BUFFER = 0.25,
        COMBAT_KITE_MELEE_HOLD_BUFFER = 0.45,
        COMBAT_KITE_MELEE_STOP_BUFFER = 0.16,
        COMBAT_KITE_RETREAT_LOCK_MS = 450,
        COMBAT_KITE_DAMAGE_PRESSURE_MS = 2500,
        COMBAT_KITE_DAMAGE_LOCK_MS = 900,
        COMBAT_KITE_DAMAGE_DISTANCE = 2.2,
        COMBAT_SHOVE_RANGE = 1.35,
        COMBAT_SHOVE_PRESSURE_COUNT = 2,
        COMBAT_GROUND_FINISHER_MAX_PRESSURE = 1,
        COMBAT_FORMATION_QUERY_RADIUS = 2.4,
        COMBAT_FORMATION_SLOT_RADIUS = 1.05,
        COMBAT_TACTICAL_DIAGNOSTIC_MS = 200,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        IsManagedNPCBody = function() return false end,
    },
    PathService = {
        MoveToward = function(_, _, x, y, _, mode, _, reason)
            moves[#moves + 1] = {
                x = x,
                y = y,
                mode = mode,
                reason = reason,
            }
            return true
        end,
    },
    BehaviorMoveIntent = {
        Hold = function()
            holds = holds + 1
            return true
        end,
        RequestMove = function(_, x, y, _, mode, _, reason)
            moves[#moves + 1] = {
                x = x,
                y = y,
                mode = mode,
                reason = reason,
            }
            return true
        end,
    },
    BehaviorCommon = {
        GetOwner = function()
            return {
                getX = function() return 10 end,
                getY = function() return 0 end,
                getZ = function() return 0 end,
            }
        end,
    },
    Perception = {
        CountEnemyZombies = function(_, radius)
            if radius == 1.8 then return math.min(pressureCount, 2) end
            if radius == 3 then return pressureCount end
            if radius == 5.5 then return hordeCount end
            if radius == 2.6 then return pressureCount end
            return 0
        end,
        GetVisibleZombieEntries = function(_, radius)
            local count = radius == 3
                and visiblePressureCount or visibleHordeCount
            local result = {}
            for i = 1, count do result[i] = {} end
            return result
        end,
        FindZombieByID = function() return targetZombie end,
    },
    SpatialIndex = {
        QueryZombies = function() return targetCrowd end,
        QueryNPCs = function() return nearbyNPCs end,
        QueryPlayers = function() return nearbyPlayers end,
    },
    Skills = {
        GetLevel = function() return skillLevel end,
        ResolveWeaponSkill = function() return "LongBlade" end,
    },
    Stamina = {
        GetRatio = function() return 1 end,
        CanSpendAttack = function() return canSpendAttack end,
    },
    TraversalQuery = {
        CanStep = function() return true end,
        CanOccupy = function() return true end,
    },
    Relationships = {
        AreNPCsEnemies = function() return false end,
    },
    CombatUnarmed = {
        IsGroundTarget = function() return grounded end,
    },
}

dofile(ROOT .. "Combat/CombatTactics/PNC_Combat_Tactics.lua")

local function makeRecord(id)
    return {
        id = id,
        faction = "colonist",
        presenceState = "LIVE",
        alive = true,
        x = 0,
        y = 0,
        z = 0,
        runtime = {},
        equipment = {},
        stamina = { current = 100, max = 100 },
    }
end

local target = {
    kind = "zombie",
    zombieId = "z1",
    x = 1,
    y = 0,
    z = 0,
    distSq = 1,
    visible = true,
}

-- An unarmed novice uses a shove when two zombies enter its pressure bubble.
pressureCount = 2
visiblePressureCount = 2
hordeCount = 2
visibleHordeCount = 2
local record = makeRecord("novice")
local moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = false }
)
assertEqual(moved, false, "pressure shove does not move before committing")
assertEqual(reason, "pressure_shove", "pressure shove reason")
assertEqual(action, "shove", "pressure shove directive")

-- Skill and a weapon raise pressure tolerance, preserving an attack window.
now = now + 250
skillLevel = 8
record = makeRecord("veteran")
moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "skilled equipped melee does not panic")
assertEqual(action, nil, "skilled equipped melee keeps strike choice")
assertEqual(
    record.runtime.combatTactical.pressureTolerance,
    4,
    "skill and equipment influence pressure tolerance"
)

-- An avoided bite from one zombie opens a counter-shove instead of making
-- the NPC turn its back and enter a retreat path.
now = now + 250
pressureCount = 1
visiblePressureCount = 1
hordeCount = 1
visibleHordeCount = 1
record = makeRecord("lone_counter")
PNC.CombatTactics.MarkZombieNearMiss(record, 1, 0, 0, now)
moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "lone near miss incorrectly triggered retreat")
assertEqual(reason, "lone_threat_counter", "lone counter reason")
assertEqual(action, "shove", "lone near miss did not counter-shove")

-- An exhausted fighter commits a weakened emergency strike against one
-- adjacent zombie instead of entering a stamina-draining shove loop.
now = now + 250
canSpendAttack = false
record = makeRecord("exhausted_counter")
record.stamina.current = 5
moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "exhausted lone fighter entered retreat first")
assertEqual(reason, "exhausted_lone_counter",
    "exhausted lone counter reason")
assertEqual(action, nil, "exhausted lone fighter did not commit melee")
assertEqual(record.runtime.emergencyMeleeUntil, now + 300,
    "emergency melee lease was not armed")

-- The counter window is finite. Afterwards the NPC takes one bounded step
-- outside the red circle, then holds position until enough stamina returns.
now = now + 1801
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "exhausted counter never yielded to retreat")
assertEqual(reason, "exhausted_recovery_retreat",
    "exhausted recovery retreat reason")
record.x = -1.3
target.distSq = 5.29
now = now + 250
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "safe exhausted fighter did not hold to recover")
assertEqual(reason, "recovering_stamina_safe",
    "safe recovery hold reason")
assertEqual(holds > 0, true, "safe recovery did not stop locomotion")
record.stamina.current = 35
record.x = 0
target.distSq = 1
now = now + 250
moved = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "recovered fighter did not re-engage")
canSpendAttack = true

-- Crowd pressure alone must not make a healthy follower abandon the player.
-- A real avoided zombie impact arms the short reactive kite.
now = now + 250
pressureCount = 4
visiblePressureCount = 4
hordeCount = 4
visibleHordeCount = 4
record = makeRecord("boundary_retreat")
moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "pressure boundary does not trigger proactive retreat")
PNC.CombatTactics.MarkZombieNearMiss(record, 1, 0, 0, now)
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "near miss triggers reactive kite")
assertEqual(reason, "near_miss_kite", "reactive kite reason")
assert(
    moves[#moves].x < record.x,
    "retreat goal must increase distance from the threat"
)
record.x = -0.5
now = now + 250
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "locked retreat remains authoritative")
assert(
    moves[#moves].x < record.x,
    "fixed retreat leg must continue away from danger"
)

-- A successful zombie hit uses the same horde gate as an avoided hit, then
-- keeps a low-stamina fighter safe until the re-engagement threshold is met.
now = now + 250
record = makeRecord("damage_retreat")
record.stamina.current = 20
record.orderSpec = { kind = "follow" }
PNC.CombatTactics.MarkZombieDamage(record, 1, 0, 0, now)
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "zombie damage triggers horde retreat")
assertEqual(reason, "zombie_damage_retreat", "damage retreat reason")
local retreatState = record.runtime.combatRetreat
local retreatGoalX = retreatState.goalX
record.x = retreatGoalX
now = now + 250
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "damaged fighter does not attack below stamina threshold")
assertEqual(reason, "recovering_stamina_safe", "damage retreat recovery reason")
record.stamina.current = 35
now = now + 250
moved = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "fighter re-engages at stamina threshold")

-- A ranged attack arbitration pass must not erase the zombie-attack marker
-- before the ranged tactical precheck gets a chance to retreat.
now = now + 250
record = makeRecord("ranged_damage_retreat")
PNC.CombatTactics.MarkZombieDamage(record, 1, 0, 0, now)
PNC.CombatTactics.ClearRetreatState(record)
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "ranged",
    { hasWeapon = true }
)
assertEqual(moved, true, "ranged damage marker reaches retreat arbitration")
assertEqual(reason, "zombie_damage_retreat", "ranged damage retreat reason")
record.runtime.target = target
local interruptAttack, interruptReason =
    PNC.CombatTactics.ShouldInterruptAttackForRetreat(record)
assertEqual(interruptAttack, true, "active attack yields to retreat")
assertEqual(interruptReason, "zombie_damage_retreat",
    "active attack retreat handoff reason")

-- Follow-mode retreat destinations stay inside the owner leash even when the
-- raw retreat vector points away from the owner.
record = makeRecord("follow_clamp")
record.orderSpec = { kind = "follow" }
local clamped = PNC.CombatTactics.Internal.BuildRetreatFromSource(
    record, target, 20, 1, 0, 0,
    PNC.CombatTactics.Internal.EnsureRetreatState(record)
)
local ownerDistance = math.sqrt((clamped.x - 10) ^ 2 + clamped.y ^ 2)
assert(ownerDistance <= 5.5 + 0.0001, "follow retreat exceeded owner leash")

-- A native route that makes no physical progress releases combat ownership
-- instead of rebuilding the same retreat forever while the NPC is mauled.
now = now + 250
record = makeRecord("stalled_retreat")
PNC.CombatTactics.MarkZombieNearMiss(record, 1, 0, 0, now)
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, true, "stalled-retreat fixture starts movement")
now = now + 1000
moved, reason = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "stalled retreat did not release combat")
assertEqual(reason, "retreat_stalled", "stalled retreat reason")
assertEqual(record.runtime.retreatMode, false,
    "stalled retreat retained movement ownership")

-- A crawler is only finished when the immediate area is safe.
now = now + 250
grounded = true
pressureCount = 1
visiblePressureCount = 1
record = makeRecord("stomper")
moved, _, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "safe crawler does not trigger retreat")
assertEqual(action, "ground", "safe crawler opens ground finisher")

now = now + 250
pressureCount = 3
visiblePressureCount = 3
hordeCount = 6
visibleHordeCount = 6
record = makeRecord("crawler_pressure")
moved, reason, action = PNC.CombatTactics.PreAttackDecision(
    record,
    {},
    target,
    "melee",
    { hasWeapon = true }
)
assertEqual(moved, false, "crawler pressure alone does not trigger retreat")
assertEqual(action, "ground", "crawler pressure leaves attack arbitration active")

-- Friendly humans crossing the shot corridor block fire.
grounded = false
pressureCount = 0
visiblePressureCount = 0
hordeCount = 0
visibleHordeCount = 0
nearbyNPCs = {
    {
        id = "ally",
        faction = "colonist",
        alive = true,
        x = 3,
        y = 0.1,
        z = 0,
    },
}
target.x = 6
target.distSq = 36
record = makeRecord("shooter")
local safe
safe, reason = PNC.CombatTactics.IsFriendlyFireSafe(record, target)
assertEqual(safe, false, "ally blocks firearm lane")
assertEqual(reason, "friendly_fire_risk", "friendly fire reason")

nearbyNPCs = {}
now = now + 121
safe = PNC.CombatTactics.IsFriendlyFireSafe(record, target)
assertEqual(safe, true, "clear firearm lane")

-- Ranged fire waits for skill/distance-based aim confidence.
skillLevel = 0
local ready
ready, reason = PNC.CombatTactics.CanTakeRangedShot(record, target)
assertEqual(ready, false, "new target requires aim settle")
assertEqual(reason, "aiming", "aim settle reason")
now = now + 1000
ready = PNC.CombatTactics.CanTakeRangedShot(record, target)
assertEqual(ready, true, "settled clear shot becomes available")

-- Reload is abandoned when the threat reaches point-blank range.
record.runtime.attackAction = { attackType = "reload" }
target.x = 1
target.distSq = 1
local interrupt
interrupt, reason = PNC.CombatTactics.ShouldInterruptReload(record, target)
assertEqual(interrupt, true, "point-blank threat interrupts reload")
assertEqual(reason, "reload_interrupted_by_pressure", "reload interruption reason")

-- Multiple allies receive a stable offset approach slot instead of stacking.
nearbyNPCs = {
    {
        id = "ally",
        faction = "colonist",
        alive = true,
        x = 1,
        y = 0.5,
        z = 0,
    },
}
local approachX
local approachY
local formation
approachX, approachY, formation =
    PNC.CombatTactics.GetMeleeApproachPoint(record, target)
assertEqual(formation, true, "nearby ally enables melee formation slot")
assert(
    math.abs(approachX - target.x) > 0.01
        or math.abs(approachY - target.y) > 0.01,
    "formation slot differs from target center"
)

print("pnc_combat_tactical_decisions_smoke: ok")
