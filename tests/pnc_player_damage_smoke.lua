local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local records = {}
local bodies = {}
local broadcasts = 0

PNC = {
    Const = {
        FACTION_COLONIST = "colonist",
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        DEFAULT_HP_MAX = 100,
        DEFAULT_ENGINE_BUFFER = 1000,
        INCAPACITATED_ENGINE_BUFFER = 1000,
        INCAPACITATED_HP = 1,
        INCAPACITATED_GRACE_MS = 1500,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 2500,
        PLAYER_HIT_DAMAGE_SCALE = 10,
        PLAYER_HIT_DAMAGE_MAX = 50,
        PLAYER_HIT_MELEE_RANGE = 3,
        PLAYER_HIT_RANGED_RANGE = 20,
        PLAYER_HIT_REPORT_COOLDOWN_MS = 80,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
    },
    Identity = {
        NormalizeSeed = function(seed) return tonumber(seed) or 1 end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        MarkDirty = function() end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    BodyLifecycle = {
        CreateInertCorpse = function() end,
    },
    Network = {
        GetZombieOnlineID = function() return 77 end,
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
    },
}

dofile(ROOT .. "Base/PNC_Types.lua")
dofile(ROOT .. "Health/PNC_Health.lua")
dofile(ROOT .. "Health/PNC_PlayerDamage.lua")

assertEqual(PNC.Types.NormalizeFaction("colonist"), "colonist", "colonist faction")
assertEqual(PNC.Types.NormalizeFaction("companion"), "colonist", "legacy companion migration")
assertEqual(PNC.Types.NormalizeFaction("friendly"), "colonist", "legacy friendly migration")
assertEqual(PNC.Types.NormalizeFaction("neutral"), "neutral", "neutral faction")
assertEqual(PNC.Types.NormalizeFaction("bandit"), "hostile", "hostile alias")
assertEqual(PNC.Types.NormalizeDefinition({ faction = "companion" }).faction, "colonist", "legacy definition migration")

local function makeRecord(id, faction)
    return {
        id = id,
        faction = faction,
        presenceState = "live",
        alive = true,
        health = {
            current = 100,
            max = 100,
            state = "normal",
            lastDamageAt = 0,
            recentDamageUntil = 0,
            reviveProtectionUntil = 0,
        },
        runtime = {},
    }
end

local engineHealth = 1000
local bodyModData = {
    PNC_NPC = true,
    PNC_UUID = "neutral_1",
    PNC_BodyLease = "lease_1",
}
local body = {
    getModData = function() return bodyModData end,
    getPersistentOutfitID = function() return 991 end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    setHealth = function(_, value) engineHealth = value end,
}
local weapon = {
    getFullType = function() return "Base.Axe" end,
    getMaxDamage = function() return 2 end,
    isRanged = function() return false end,
}
local player = {
    getOnlineID = function() return 12 end,
    getUsername = function() return "tester" end,
    getPrimaryHandItem = function() return weapon end,
    getSecondaryHandItem = function() return nil end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

records.neutral_1 = makeRecord("neutral_1", "neutral")
bodies.neutral_1 = body
local applied, reason = PNC.PlayerDamage.HandleClientReport(player, {
    id = "neutral_1",
    attackerOnlineID = 12,
    bodyOnlineID = 77,
    bodyInstanceID = 991,
    bodyLease = "lease_1",
    weaponFullType = "Base.Axe",
    damage = 1.5,
})
assertEqual(applied, true, "neutral damage applied")
assertEqual(reason, "damaged", "neutral damage reason")
assertEqual(records.neutral_1.health.current, 85, "scaled neutral custom HP")
assertEqual(engineHealth, 1000, "engine buffer restored")
assertEqual(broadcasts, 1, "damage broadcast")

local colonist = makeRecord("colonist_1", "colonist")
local legacyCompanion = makeRecord("legacy_1", "companion")
local hostile = makeRecord("hostile_1", "hostile")
assertEqual(PNC.PlayerDamage.CanDamageRecord(colonist), false, "colonist protection")
assertEqual(PNC.PlayerDamage.CanDamageRecord(legacyCompanion), false, "legacy colonist protection")
assertEqual(PNC.PlayerDamage.CanDamageRecord(hostile), true, "hostile damage enabled")

bodyModData.PNC_UUID = "hostile_1"
assertEqual(PNC.PlayerDamage.Apply(hostile, body, player, weapon, 1, "test"), true, "hostile hit applied")
assertEqual(hostile.health.current, 90, "hostile custom HP")

bodyModData.PNC_UUID = "colonist_1"
assertEqual(PNC.PlayerDamage.Apply(colonist, body, player, weapon, 2, "test"), false, "colonist hit rejected")
assertEqual(colonist.health.current, 100, "colonist HP unchanged")

now = 1200
bodyModData.PNC_UUID = "neutral_1"
local rejected, rejectedReason = PNC.PlayerDamage.HandleClientReport(player, {
    id = "neutral_1",
    attackerOnlineID = 999,
    weaponFullType = "Base.Axe",
    damage = 2,
})
assertEqual(rejected, false, "spoofed attacker rejected")
assertEqual(rejectedReason, "attacker_mismatch", "spoofed attacker reason")

print("pnc_player_damage_smoke: ok")
