local T = require "tests/support/test"

local now = 1000
local enemy = true
local interruptions = 0
local engagements = 0
local areaFallbacks = 0

local function body(x, y)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        isAlive = function() return true end,
    }
end

local victimBody = body(10, 10)
local attackerBody = body(18, 10)
local victim
local attacker = {
    id = "attacker",
    alive = true,
    x = 18,
    y = 10,
    z = 0,
    runtime = {
        target = { kind = "npc", id = "victim" },
    },
}

victim = {
    id = "victim",
    alive = true,
    attackType = "auto",
    x = 10,
    y = 10,
    z = 0,
    hostility = { attackNPCs = false },
    runtime = {
        animationScene = {
            id = "facility.living.sleep",
            blocking = true,
        },
    },
    orderSpec = {
        kind = "camp",
        x = 10,
        y = 10,
        z = 0,
        radius = 3,
    },
}

PNC = {
    Const = {
        ORDER_CAMP = "camp",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_ROAM = "roam",
        ORDER_LUMBER = "lumber",
        ORDER_FISHING = "fishing",
        ORDER_SCAVENGE = "scavenge",
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        CAMP_ENGAGE_RADIUS = 3,
        CAMP_RADIUS = 3,
        GUARD_ENGAGE_RADIUS = 4,
        GUARD_RADIUS = 4,
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        RANGED_RANGE = 8.5,
        TARGET_RECENT_ATTACKER_MS = 5000,
        TARGET_VISUAL_MEMORY_MS = 2200,
        TARGET_REASSESS_MS = 350,
        TARGET_SWITCH_DISTANCE_RATIO = 0.72,
        ZOMBIE_TARGET_RADIUS = 12,
        ROAM_TARGET_RADIUS = 12,
        THREAT_GUARD_SCAN_MS = 350,
        THREAT_GUARD_VALIDATE_MS = 250,
        THREAT_GUARD_RELEASE_GRACE_MS = 900,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            return { attacker }
        end,
    },
    Registry = {
        Get = function(id)
            if id == "victim" then return victim end
            if id == "attacker" then return attacker end
            return nil
        end,
        GetLiveZombie = function(id)
            if id == "victim" then return victimBody end
            if id == "attacker" then return attackerBody end
            return nil
        end,
    },
    Relationships = {
        AreNPCsEnemies = function(source, target, options)
            return enemy
                and source == victim
                and target == attacker
                and options
                and options.ignoreAttackNPCPolicy == true
        end,
    },
    Stealth = {},
    Perception = {},
    AnimationScenes = {
        Interrupt = function(record, _, reason)
            T.equal(reason, "combat", "NPC threat interrupts the passive scene")
            interruptions = interruptions + 1
            record.runtime.animationScene = nil
            return true
        end,
    },
    BehaviorCompanion = {
        Internal = {
            ResolveThreatTarget = function()
                areaFallbacks = areaFallbacks + 1
                return nil
            end,
            EngageResolvedTarget = function(record, _, target)
                engagements = engagements + 1
                record.runtime.target = target
                return true
            end,
        },
    },
    BehaviorCommon = {
        SetCombatTarget = function(record, target)
            record.runtime.target = target
            return true
        end,
        ClearCombatTarget = function(record)
            record.runtime.target = nil
        end,
    },
    PerformanceScalingDiagnostics = {
        SeatingAuditEnabled = false,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception.lua"
)
PNC.Perception.CanSeeWorldObject = function()
    return true, "clear"
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Targeting.lua"
)

T.truthy(PNC.Perception.IsTargetThreatening(victim, {
    kind = "npc",
    id = "attacker",
}), "active NPC target metadata identifies the victim")
T.truthy(PNC.Relationships.AreNPCsEnemies(victim, attacker, {
    ignoreAttackNPCPolicy = true,
}), "direct aggression relationship bypasses initiation policy")
local visible = PNC.Perception.CanSeeWorldObject(victim, attackerBody)
T.equal(visible, true, "active NPC body is visible")
local direct = PNC.Perception.FindImmediateNPCThreat(victim)
T.truthy(direct and direct.kind == "npc" and direct.id == "attacker",
    "actively attacking NPC was found as an immediate threat")
T.equal(direct.immediateSelfDefense, true,
    "direct NPC aggression is marked as self-defense")

local resolved = PNC.BehaviorTargeting.ResolveImmediateNPCThreat(victim)
T.truthy(resolved and resolved.kind == "npc",
    "immediate NPC target resolver returned the active attacker")
T.equal(resolved.immediateSelfDefense, true,
    "direct NPC aggression is marked as self-defense")

T.truthy(
    PNC.Perception.RememberAttacker(victim, {
        attackerKind = "npc",
        attackerID = "attacker",
    }, now),
    "NPC damage is remembered for direct self-defense")
resolved = PNC.BehaviorTargeting.ResolveImmediateNPCThreat(victim)
T.equal(resolved.kind, "npc",
    "recent NPC damage resolves even when attackNPCs is disabled")

enemy = false
T.falsy(PNC.Perception.FindImmediateNPCThreat(victim),
    "friendly NPC does not become an immediate threat")
enemy = true
victim.runtime.recentThreat = nil
attacker.runtime.target = nil
T.falsy(PNC.Perception.FindImmediateNPCThreat(victim),
    "nearby enemy NPC that is not attacking is ignored")
attacker.runtime.target = { kind = "npc", id = "victim" }

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard.lua"
)
local ThreatGuard = PNC.BehaviorThreatGuard

T.truthy(ThreatGuard.Tick(victim, {}, now),
    "passive camp owner enters threat guard for an attacking NPC")
T.equal(victim.activeBehavior, "CombatGuard:engaged",
    "NPC self-defense owns the behavior tick")
T.equal(victim.runtime.target.kind, "npc",
    "threat guard stores the hostile NPC target")
T.equal(engagements, 1,
    "NPC self-defense enters the shared combat handoff")
T.equal(interruptions, 1,
    "sleeping presentation is interrupted for NPC self-defense")
T.equal(areaFallbacks, 0,
    "direct NPC aggression preempts ordinary area defense")

T.finish("pnc_immediate_npc_threat_smoke")
