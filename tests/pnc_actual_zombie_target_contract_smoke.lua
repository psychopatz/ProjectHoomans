local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local now = 1000

local function body(id, managed)
    return {
        id = id,
        managed = managed == true,
        getX = function() return 2 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getModData = function()
            return { PNC_ZombieID = id }
        end,
        isZombie = function() return true end,
        isDead = function() return false end,
        isAlive = function() return true end,
        getTarget = function() return nil end,
    }
end

local actualZombie = body("real-zed", false)
local managedNPCBody = body("managed-npc", true)

PNC = {
    Const = {
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        ZOMBIE_TARGET_RADIUS = 12,
        ROAM_TARGET_RADIUS = 12,
        TARGET_RECENT_ATTACKER_MS = 5000,
        ZOMBIE_ATTACKER_OBSERVATION_MS = 1500,
        PERCEPTION_CANDIDATE_CACHE_MS = 100,
        PERCEPTION_CANDIDATE_CACHE_MAX = 8,
        PERCEPTION_FRAME_MS = 200,
        PERCEPTION_FRAME_MOVE_TOLERANCE = 0.5,
        PERCEPTION_LOS_MAX_CANDIDATES = 6,
        COMBAT_TARGET_CROWD_RADIUS = 2.2,
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
    },
    Types = {},
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
            local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function(bodyValue)
            return bodyValue and bodyValue.managed == true or false
        end,
    },
    SpatialIndex = {
        QueryZombies = function()
            return { actualZombie, managedNPCBody }
        end,
        FindZombieByID = function(id)
            if id == actualZombie.id then return actualZombie end
            if id == managedNPCBody.id then return managedNPCBody end
            return nil
        end,
    },
    Registry = {
        FindRecordByZombie = function(bodyValue)
            if bodyValue == managedNPCBody then
                return { id = "managed-npc" }
            end
            return nil
        end,
        Get = function() return nil end,
        GetLiveZombie = function(id)
            if id == "observer" then return body("observer", true) end
            return nil
        end,
    },
    Relationships = {},
    Stealth = {},
}

T.load(ROOT .. "Base/PNC_Types/PNC_Types_TacticalClasses.lua")
T.equal(
    PNC.Types.DefaultHostility("neutral").attackZombies,
    true,
    "neutral NPCs retain universal real-zombie defense"
)
T.equal(
    PNC.Types.NormalizeHostility("neutral", {
        attackZombies = false,
    }).attackZombies,
    true,
    "legacy false zombie policy cannot disable real-zombie defense"
)

T.load(ROOT .. "Perception/PNC_Perception.lua")
T.load(ROOT .. "Perception/PNC_Perception_Frame.lua")
PNC.Perception.CanSeeWorldObject = function()
    return true, "clear"
end

T.truthy(
    PNC.Perception.IsActualZombieBody(actualZombie),
    "unmanaged IsoZombie is an actual zombie target"
)
T.falsy(
    PNC.Perception.IsActualZombieBody(managedNPCBody),
    "repurposed managed IsoZombie is not an actual zombie target"
)

local record = {
    id = "observer",
    x = 0,
    y = 0,
    z = 0,
    attackType = "auto",
    hostility = { attackZombies = false },
    runtime = {},
}

local actualTarget = PNC.Perception.Internal.BuildZombieTarget(
    record, actualZombie, 4, "clear"
)
T.truthy(actualTarget, "actual zombie target was built")
T.equal(actualTarget.kind, "zombie", "actual zombie target kind is stable")
T.falsy(
    PNC.Perception.Internal.BuildZombieTarget(
        record, managedNPCBody, 4, "clear"
    ),
    "managed NPC body cannot enter the zombie target path"
)
T.equal(
    #PNC.Perception.GetVisibleZombieEntries(record, 12),
    1,
    "visible zombie frame excludes the managed NPC body"
)

T.truthy(
    PNC.Perception.FindBestEnemyZombie(record, 12),
    "neutral record still acquires an actual zombie"
)
T.truthy(
    PNC.Perception.FindNearestEnemyZombie(record, 12),
    "neutral record still acquires a nearby actual zombie"
)
T.equal(
    PNC.Perception.CountEnemyZombies(record, 12),
    1,
    "managed NPC body is excluded from the actual-zombie count"
)

record.runtime.recentThreat = {
    kind = "zombie",
    id = actualZombie.id,
    expiresAt = now + 100,
}
T.truthy(
    PNC.Perception.ResolveRecentAttacker(record, now),
    "actual zombie recent attacker remains actionable"
)
record.runtime.recentThreat.id = managedNPCBody.id
T.falsy(
    PNC.Perception.ResolveRecentAttacker(record, now),
    "managed NPC body cannot masquerade as a zombie recent attacker"
)

record.runtime.recentThreat = nil
record.runtime.zombieAttacker = {
    zombieId = actualZombie.id,
    observedAt = now,
}
T.truthy(
    PNC.Perception.FindImmediateZombieThreat(record, 6),
    "actual zombie observed attacker remains actionable"
)
record.runtime.zombieAttacker.zombieId = managedNPCBody.id
T.falsy(
    PNC.Perception.FindImmediateZombieThreat(record, 6),
    "managed NPC body cannot masquerade as an observed zombie attacker"
)

PNC.BehaviorThreatGuard = { Internal = {} }
PNC.BehaviorCommon = {}
PNC.BehaviorCompanion = {}
PNC.AnimationScenes = {}
PNC.CombatTactics = {}
T.load(ROOT .. "Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Transitions_Combat.lua")

T.truthy(
    PNC.BehaviorThreatGuard.Internal.CanAttackTarget(
        record, actualTarget
    ),
    "real zombie is attackable even with legacy neutral hostility"
)
T.falsy(
    PNC.BehaviorThreatGuard.Internal.CanAttackTarget(
        record, { kind = "zombie", zombieId = managedNPCBody.id }
    ),
    "managed NPC body is rejected by the combat authorization boundary"
)
T.finish("pnc_actual_zombie_target_contract_smoke")
