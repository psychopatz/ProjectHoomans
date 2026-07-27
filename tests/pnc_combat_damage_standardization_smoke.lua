local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertNear(actual, expected, label)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error((label or "assertNear") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local now = 2000
local authority = true
local records = {}
local bodies = {}
local recordBroadcasts = 0
local removals = 0
local corpseCreates = 0
local zombieReactionOptions

ZombRand = function() return 0 end
BodyPartType = {
    Head = {},
    Neck = {},
    Torso_Upper = {},
    Torso_Lower = {},
    Groin = {},
    UpperArm_L = {},
    UpperArm_R = {},
    ForeArm_L = {},
    ForeArm_R = {},
    Hand_L = {},
    Hand_R = {},
    UpperLeg_L = {},
    UpperLeg_R = {},
    LowerLeg_L = {},
    LowerLeg_R = {},
    Foot_L = {},
    Foot_R = {},
}

PNC = {
    Const = {
        DEFAULT_HP_MAX = 100,
        DEFAULT_ENGINE_BUFFER = 1000,
        INCAPACITATED_ENGINE_BUFFER = 1000,
        INCAPACITATED_HP = 1,
        INCAPACITATED_GRACE_MS = 1500,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 2500,
        REVIVE_HP = 10,
        REVIVE_PROTECTION_MS = 3000,
        PRESENCE_CORPSE = "corpse",
        WOUND_BLEED_UPDATE_MS = 1000,
        WOUND_DIRTY_FLUSH_MS = 5000,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
        Log = function() end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
        NPCZombieInfectionEnabled = function() return false end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        MarkDirty = function() end,
    },
    BodyLifecycle = {
        CreateInertCorpse = function()
            corpseCreates = corpseCreates + 1
            return true
        end,
    },
    Network = {
        BroadcastRecord = function() recordBroadcasts = recordBroadcasts + 1 end,
        BroadcastRemoval = function() removals = removals + 1 end,
        BroadcastZombieReaction = function(_, _, options)
            zombieReactionOptions = options
            return true
        end,
    },
    ZombieAggro = {
        OnZombieProvoked = function() end,
    },
}

dofile(ROOT .. "Health/PNC_Health.lua")
dofile(ROOT .. "Health/PNC_NPCWounds.lua")
dofile(ROOT .. "Combat/PNC_Combat_Damage.lua")

local function makeRecord(id)
    return {
        id = id,
        alive = true,
        x = 0,
        y = 0,
        z = 0,
        presenceRevision = 1,
        presenceState = "live",
        runtime = {},
        health = { current = 100, max = 100, state = "normal" },
    }
end

local function makeNPCBody()
    local engineHealth = 1000
    return {
        getHealth = function() return engineHealth end,
        setHealth = function(_, value) engineHealth = value end,
        setUseless = function() end,
        setZombiesDontAttack = function() end,
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end

local weapon = {
    getFullType = function() return "Base.Axe" end,
}
local attacker = makeRecord("attacker")
local attackerBody = makeNPCBody()
local targetRecord = makeRecord("npc_target")
local targetBody = makeNPCBody()
records[targetRecord.id] = targetRecord
bodies[targetRecord.id] = targetBody

local applied, reason, result = PNC.CombatDamage.ApplyTargetDamage(attacker, attackerBody, {
    kind = "npc",
    id = targetRecord.id,
}, {
    damage = 10,
    attackType = "melee",
    weaponItem = weapon,
})
assertEqual(applied, true, "NPC target damage")
assertEqual(reason, "hit_npc", "NPC target reason")
assertEqual(result.partId, "Head", "NPC target selected body part")
assertEqual(result.woundType, "laceration", "NPC melee wound type")
assertNear(targetRecord.health.current, 90, "NPC target overall health")
assertNear(targetRecord.health.body.parts.Head.current, 80, "NPC target part health")
assertEqual(targetRecord.health.body.wounds.Head.type, "laceration", "NPC target wound record")
assertEqual(recordBroadcasts, 1, "NPC damage immediately synchronized")

local playerPartDamage = 0
local playerPain = 0
local playerCut = 0
local playerBleeding = 0
local playerUpdates = 0
local playerPackets = 0
local playerPart = {
    AddDamage = function(_, value) playerPartDamage = playerPartDamage + value end,
    getAdditionalPain = function() return playerPain end,
    setAdditionalPain = function(_, value) playerPain = value end,
    getCutTime = function() return playerCut end,
    setCutTime = function(_, value) playerCut = value end,
    getBleedingTime = function() return playerBleeding end,
    setBleedingTime = function(_, value) playerBleeding = value end,
}
local playerBodyDamage = {
    getBodyPart = function(_, partType)
        assertEqual(partType, BodyPartType.Head, "player uses standardized body part")
        return playerPart
    end,
    Update = function() playerUpdates = playerUpdates + 1 end,
}
local player = {
    getBodyDamage = function() return playerBodyDamage end,
    sendPlayerStatsPacket = function() playerPackets = playerPackets + 1 end,
}
applied, reason, result = PNC.CombatDamage.ApplyTargetDamage(attacker, attackerBody, {
    kind = "player",
    player = player,
}, {
    damage = 10,
    attackType = "melee",
    weaponItem = weapon,
})
assertEqual(applied, true, "player target damage")
assertEqual(reason, "hit_player", "player target reason")
assertEqual(result.partId, "Head", "player target selected body part")
assertNear(playerPartDamage, 3.4, "player body-part damage")
assertEqual(playerCut, 8, "player laceration")
assertEqual(playerBleeding, 25, "player bleeding")
assertEqual(playerUpdates, 1, "player body damage update")
assertEqual(playerPackets, 1, "player multiplayer health packet")

local zombieHealth = 1
local zombie = {
    isDead = function() return zombieHealth <= 0 end,
    getHealth = function() return zombieHealth end,
    setHealth = function(_, value) zombieHealth = value end,
}
PNC.CombatZombieReaction = {
    ApplyWeaponHit = function(_, victim, _, scaledDamage, options)
        victim:setHealth(victim:getHealth() - scaledDamage)
        zombieReactionOptions = options
        return true
    end,
}
applied, reason, result = PNC.CombatDamage.ApplyTargetDamage(attacker, attackerBody, {
    kind = "zombie",
    worldObject = zombie,
}, {
    damage = 10,
    attackType = "ranged",
    weaponItem = weapon,
})
assertEqual(applied, true, "zombie target damage")
assertEqual(reason, "hit_zombie", "zombie target reason")
assertEqual(result.partId, "Head", "zombie target selected body part")
assertEqual(result.woundType, "bullet", "zombie ranged wound metadata")
assertEqual(zombieReactionOptions.partId, "Head", "zombie reaction body-part replication")

local dyingRecord = makeRecord("dying_npc")
dyingRecord.health.state = "incapacitated"
dyingRecord.health.downedAt = 0
local dyingBody = makeNPCBody()
records[dyingRecord.id] = dyingRecord
bodies[dyingRecord.id] = dyingBody
applied, reason = PNC.CombatDamage.ApplyTargetDamage(attacker, attackerBody, {
    kind = "npc",
    id = dyingRecord.id,
}, {
    damage = 10,
    attackType = "melee",
    weaponItem = weapon,
})
assertEqual(applied, true, "incapacitated NPC finishing damage")
assertEqual(reason, "hit_npc", "incapacitated NPC finish reason")
assertEqual(dyingRecord.alive, false, "NPC final death")
assertEqual(corpseCreates, 1, "NPC corpse created once")
assertEqual(removals, 1, "NPC death immediately synchronized")

authority = false
local beforeHealth = targetRecord.health.current
applied, reason = PNC.CombatDamage.ApplyTargetDamage(attacker, attackerBody, {
    kind = "npc",
    id = targetRecord.id,
}, {
    damage = 10,
    attackType = "melee",
    weaponItem = weapon,
})
assertEqual(applied, false, "client-only damage rejected")
assertEqual(reason, "not_authority", "client-only rejection reason")
assertEqual(targetRecord.health.current, beforeHealth, "client-only target unchanged")

print("pnc_combat_damage_standardization_smoke: ok")
