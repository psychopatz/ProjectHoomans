local root = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local now = 10000
local records = {}
local bodies = {}
local broadcasts = 0
local clearedAggro = 0
local scheduledAt

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
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
        PRESENCE_LIVE = "live",
        PRESENCE_CORPSE = "corpse",
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function(id) return bodies[id] end,
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

dofile(root .. "Base/PNC_Sandbox.lua")
dofile(root .. "Health/PNC_Health.lua")
dofile(root .. "Health/PNC_Revive.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

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
    return {
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
assertEqual(PNC.Sandbox.ZombiesTargetDownedNPC(), false, "sandbox default")
assertEqual(PNC.Sandbox.CanZombieTargetRecord(downed), false, "downed targeting default")
assertEqual(PNC.Health.ApplyDamage(downed, bodies[downed.id], {
    amount = 12,
    attackerKind = "zombie",
}), false, "protected zombie damage")
assertEqual(downed.health.state, "incapacitated", "protected state")

downed.health.reviveUntil = now - 1
PNC.Health.Update(downed, bodies[downed.id], now)
assertEqual(downed.health.state, "incapacitated", "downed NPC does not bleed out")
assertEqual(PNC.Health.CanRevive(downed), true, "expired legacy timer does not block revive")

SandboxVars = { ProjectHoomans = { ZombiesTargetDownedNPC = true } }
assertEqual(PNC.Sandbox.CanZombieTargetRecord(downed), true, "enabled downed targeting")
PNC.Health.ApplyDamage(downed, bodies[downed.id], {
    amount = 12,
    attackerKind = "zombie",
})
assertEqual(downed.health.state, "dead", "enabled final blow")

local reviveRecord = makeRecord("revive")
records[reviveRecord.id] = reviveRecord
bodies[reviveRecord.id] = makeBody(0, 0, 0)
local shortPlayer = makePlayer(4, 0)
local success, reason = PNC.Revive.Try(shortPlayer, reviveRecord.id)
assertEqual(success, false, "four bandages rejected")
assertEqual(reason, "missing_bandages", "missing bandage reason")
assertEqual(shortPlayer.removedCount(), 0, "failed revive consumes nothing")

local farPlayer = makePlayer(5, 4)
success, reason = PNC.Revive.Try(farPlayer, reviveRecord.id)
assertEqual(success, false, "distant revive rejected")
assertEqual(reason, "too_far", "distance reason")
assertEqual(farPlayer.removedCount(), 0, "distant revive consumes nothing")

local player = makePlayer(5, 0)
success, reason = PNC.Revive.Try(player, reviveRecord.id)
assertEqual(success, true, "valid revive")
assertEqual(reason, "revived", "revive reason")
assertEqual(player.removedCount(), 5, "revive bandage cost")
assertEqual(reviveRecord.health.state, "normal", "incapacitation cured")
assertEqual(reviveRecord.health.current, 10, "revive health")
assertEqual(broadcasts, 1, "revive broadcast")
assertEqual(clearedAggro, 1, "revive clears zombie pressure")
assertEqual(PNC.Sandbox.CanZombieTargetRecord(reviveRecord), false, "revive recovery protection")
assertEqual(PNC.Health.ApplyDamage(reviveRecord, bodies[reviveRecord.id], {
    amount = 12,
    attackerKind = "zombie",
}), false, "recovery protection blocks zombie damage")
assertEqual(reviveRecord.health.current, 10, "protected revive health")

now = now + PNC.Const.REVIVE_PROTECTION_MS + 1
PNC.Health.Update(reviveRecord, bodies[reviveRecord.id], now)
assertEqual(PNC.Sandbox.CanZombieTargetRecord(reviveRecord), true, "recovery protection expires")

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
assertEqual(PNC.Health.ApplyDamage(transitionRecord, makeBody(0, 0, 0), {
    amount = 10,
    attackerKind = "player",
    type = "transition_test",
}), true, "damage enters incapacitation")
assertEqual(transitionRecord.health.state, "incapacitated", "transition health state")
assertEqual(transitionResets, 1, "transition resets path ownership")
assertEqual(transitionAnimations, 1, "transition applies downed state immediately")
assertEqual(scheduledAt, now + 50, "transition schedules downed reassertion")

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
dofile(root .. "Behaviors/PNC_Behavior_Incapacitated.lua")
local behaviorRecord = makeRecord("behavior")
behaviorRecord.runtime.target = { kind = "zombie" }
behaviorRecord.runtime.attackAction = { kind = "shove" }
PNC.BehaviorIncapacitated.Tick(behaviorRecord, {})
assertEqual(behaviorRecord.runtime.target, nil, "incapacitated target cleared")
assertEqual(behaviorRecord.runtime.attackAction, nil, "incapacitated attack cleared")
assertEqual(behaviorRecord.runtime.combatBlockReason, "incapacitated", "incapacitated combat blocked")
assertEqual(halted, 1, "incapacitated NPC held still")
assertEqual(downedAnimations, 1, "incapacitated pose maintained")

print("PNC revive smoke test passed")
