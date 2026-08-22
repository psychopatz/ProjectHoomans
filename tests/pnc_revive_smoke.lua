local T = require "tests/support/test"

local root = T.path("ProjectHoomans", "shared", "PNC/Core/")
local sharedRoot = T.path("ProjectHoomans", "shared", "")
local coreRoot = T.path("PsychopatzCore", "common", "")
T.addPackagePaths()
local now = 10000
local records = {}
local bodies = {}
local broadcasts = 0
local clearedAggro = 0
local scheduledAt
local currentWorldHour = 10

getGameTime = function()
    return { getWorldAgeHours = function() return currentWorldHour end }
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
    },
    Const = {
        DEFAULT_HP_MAX = 100,
        DEFAULT_ENGINE_BUFFER = 2,
        INCAPACITATED_HP = 1,
        INCAPACITATED_ENGINE_BUFFER = 1.5,
        INCAPACITATED_GRACE_MS = 1500,
        INCAPACITATED_TIMEOUT_MS = 30000,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 2500,
        REVIVE_HP = 10,
        REVIVE_PROTECTION_MS = 3000,
        REVIVE_BANDAGE_TYPE = "Base.Bandage",
        REVIVE_BANDAGE_COUNT = 5,
        REVIVE_RANGE = 3,
        BANDAGE_RANGE = 3,
        BANDAGE_TYPE = "Base.Bandage",
        BANDAGE_TYPES = { "Base.Bandage", "Base.RippedSheets" },
        BANDAGE_HEAL_PER_WORLD_HOUR = 1.5,
        BANDAGE_FIRST_AID_HEAL_BONUS = 0.25,
        BANDAGE_DIRTY_AFTER_WORLD_HOURS = 8,
        INCAPACITATED_RECOVERY_HP = 5,
        WOUND_BLEED_UPDATE_MS = 1000,
        WOUND_DIRTY_FLUSH_MS = 5000,
        PRESENCE_LIVE = "live",
        PRESENCE_CORPSE = "corpse",
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function(id) return bodies[id] end,
        MarkDirty = function() end,
    },
    Network = {
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
    },
    BodyLifecycle = {
        CreateInertCorpse = function() end,
    },
    ZombieAggro = {
        ClearForNPCBody = function() clearedAggro = clearedAggro + 1 end,
    },
    Scheduler = {
        Schedule = function(_, dueAt) scheduledAt = dueAt end,
    },
}

T.load(root .. "Base/PNC_Sandbox.lua")
T.load(root .. "Health/PNC_Health.lua")
T.load(root .. "Health/PNC_NPCWounds.lua")
T.load(root .. "Health/PNC_Treatment.lua")
T.load(root .. "Health/PNC_Revive.lua")

local function makeBody(x, y, z)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        setUseless = function() end,
        setHealth = function() end,
        setZombiesDontAttack = function() end,
    }
end

local function makeRecord(id)
    local record = {
        id = id,
        x = 0,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "live",
        runtime = {},
        health = {
            current = 1,
            max = 100,
            state = "incapacitated",
            downedAt = 0,
            reviveUntil = now + 10000,
        },
    }
    local bodyHealth = PNC.NPCWounds.Ensure(record)
    bodyHealth.wounds.Head = {
        partId = "Head",
        type = "laceration",
        bleedingRate = 0.05,
        severity = 10,
        damage = 10,
        bandaged = false,
    }
    PNC.NPCWounds.Recalculate(record)
    return record
end

local function makePlayer(bandageCount, x)
    local removed = 0
    local values = {}
    local list = {}
    local inventory = {}
    local i
    function list:size() return #values end
    function list:get(index) return values[index + 1] end
    function inventory:getAllTypeRecurse() return list end
    function inventory:getItemCount() return #values - removed end
    for i = 1, bandageCount do
        local container = {}
        local item = {}
        function container:Remove()
            removed = removed + 1
        end
        function item:getContainer() return container end
        values[#values + 1] = item
    end
    return {
        getInventory = function() return inventory end,
        getX = function() return x or 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        removedCount = function() return removed end,
    }
end

local downed = makeRecord("downed")
records[downed.id] = downed
bodies[downed.id] = makeBody(0, 0, 0)

SandboxVars = nil
T.equal(PNC.Sandbox.ZombiesTargetDownedNPC(), false, "sandbox default")
T.equal(PNC.Sandbox.CanZombieTargetRecord(downed), false, "downed targeting default")
T.equal(PNC.Health.ApplyDamage(downed, bodies[downed.id], {
    amount = 12,
    attackerKind = "zombie",
}), false, "protected zombie damage")
T.equal(downed.health.state, "incapacitated", "protected state")

downed.health.reviveUntil = now - 1
PNC.Health.Update(downed, bodies[downed.id], now)
T.equal(downed.health.state, "incapacitated", "downed NPC does not bleed out")
T.equal(PNC.Health.CanRevive(downed), true, "expired legacy timer does not block revive")

SandboxVars = { ProjectHoomans = { ZombiesTargetDownedNPC = true } }
T.equal(PNC.Sandbox.CanZombieTargetRecord(downed), true, "enabled downed targeting")
PNC.Health.ApplyDamage(downed, bodies[downed.id], {
    amount = 12,
    attackerKind = "zombie",
})
T.equal(downed.health.state, "dead", "enabled final blow")

local reviveRecord = makeRecord("revive")
records[reviveRecord.id] = reviveRecord
bodies[reviveRecord.id] = makeBody(0, 0, 0)
local shortPlayer = makePlayer(0, 0)
local success, reason = PNC.Revive.Try(shortPlayer, reviveRecord.id)
T.equal(success, false, "missing bandage rejected")
T.equal(reason, "missing_bandages", "missing bandage reason")
T.equal(shortPlayer.removedCount(), 0, "failed revive consumes nothing")

local farPlayer = makePlayer(1, 4)
success, reason = PNC.Revive.Try(farPlayer, reviveRecord.id)
T.equal(success, false, "distant revive rejected")
T.equal(reason, "too_far", "distance reason")
T.equal(farPlayer.removedCount(), 0, "distant revive consumes nothing")

local player = makePlayer(1, 0)
success, reason = PNC.Revive.Try(player, reviveRecord.id)
T.equal(success, true, "valid bulk bandage compatibility")
T.equal(reason, "wounds_bandaged", "bulk bandage reason")
T.equal(player.removedCount(), 1, "one material per wound")
T.equal(reviveRecord.health.state, "incapacitated", "bandage does not instantly revive")
T.equal(reviveRecord.health.current, 1, "bandage grants no instant health")
T.equal(reviveRecord.health.body.bandagedWoundCount, 1, "wound was bandaged")
T.equal(broadcasts, 1, "revive broadcast")
T.equal(clearedAggro, 0, "bandaging does not fake recovery")

currentWorldHour = currentWorldHour + 3
now = now + 1000
PNC.Health.Update(reviveRecord, bodies[reviveRecord.id], now)
T.equal(reviveRecord.health.state, "normal", "healing threshold resumes walking")
T.truthy(reviveRecord.health.current >= 5, "gradual healing did not reach recovery threshold")
T.equal(clearedAggro, 1, "actual recovery clears zombie pressure")
T.equal(PNC.Sandbox.CanZombieTargetRecord(reviveRecord), false, "recovery protection")
local protectedHealth = reviveRecord.health.current
T.equal(PNC.Health.ApplyDamage(reviveRecord, bodies[reviveRecord.id], {
    amount = 12,
    attackerKind = "zombie",
}), false, "recovery protection blocks zombie damage")
T.equal(reviveRecord.health.current, protectedHealth, "protected recovery health")

now = now + PNC.Const.REVIVE_PROTECTION_MS + 1
PNC.Health.Update(reviveRecord, bodies[reviveRecord.id], now)
T.equal(PNC.Sandbox.CanZombieTargetRecord(reviveRecord), true, "recovery protection expires")

local transitionAnimations = 0
local transitionResets = 0
local transitionRecord = {
    id = "transition",
    alive = true,
    presenceState = "live",
    runtime = {},
    health = {
        current = 5,
        max = 100,
        state = "normal",
        recentDamageUntil = 0,
        reviveProtectionUntil = 0,
    },
}
PNC.PathService = {
    Reset = function() transitionResets = transitionResets + 1 end,
}
PNC.Animation = {
    ApplyDowned = function() transitionAnimations = transitionAnimations + 1 end,
}
T.equal(PNC.Health.ApplyDamage(transitionRecord, makeBody(0, 0, 0), {
    amount = 10,
    attackerKind = "player",
    type = "transition_test",
}), true, "damage enters incapacitation")
T.equal(transitionRecord.health.state, "incapacitated", "transition health state")
T.equal(transitionResets, 1, "transition resets path ownership")
T.equal(transitionAnimations, 1, "transition applies downed state immediately")
T.equal(scheduledAt, now + 50, "transition schedules downed reassertion")

local halted = 0
local downedAnimations = 0
PNC.BehaviorCommon = {
    GetOwner = function() return nil end,
    ClearCombatTarget = function(record)
        record.runtime.target = nil
        record.runtime.targetKind = "none"
        record.runtime.combatBlockReason = "incapacitated"
    end,
    HaltMovement = function() halted = halted + 1 end,
}
PNC.Animation = {
    ApplyDowned = function() downedAnimations = downedAnimations + 1 end,
}
T.load(root .. "Behaviors/PNC_Behavior_Incapacitated.lua")
local behaviorRecord = makeRecord("behavior")
behaviorRecord.runtime.target = { kind = "zombie" }
behaviorRecord.runtime.attackAction = { kind = "shove" }
PNC.BehaviorIncapacitated.Tick(behaviorRecord, {})
T.equal(behaviorRecord.runtime.target, nil, "incapacitated target cleared")
T.equal(behaviorRecord.runtime.attackAction, nil, "incapacitated attack cleared")
T.equal(behaviorRecord.runtime.combatBlockReason, "incapacitated", "incapacitated combat blocked")
T.equal(halted, 1, "incapacitated NPC held still")
T.equal(downedAnimations, 1, "incapacitated pose maintained")
T.finish("pnc_revive_smoke")

T.finish("pnc_revive_smoke")
