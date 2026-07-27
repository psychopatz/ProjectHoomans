local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local dirty = {}
local assignedOrder

PNC = {
    Const = {
        FACTION_COLONIST = "colonist",
        FACTION_NEUTRAL = "neutral",
        FACTION_HOSTILE = "hostile",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
        DEFAULT_HP_MAX = 100,
        UNARMED_DAMAGE = 4,
        UNARMED_GROUND_DAMAGE = 6,
        UNARMED_COOLDOWN_MS = 900,
    },
    Core = {
        Now = function() return now end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = item end
            return output
        end,
        LogInfo = function() end,
    },
    Identity = {},
    Registry = {
        MarkDirty = function(_, field) dirty[field] = true end,
    },
    OrderSystem = {
        SetOrder = function(record, order)
            assignedOrder = order
            record.orderSpec = order
        end,
    },
}

dofile(ROOT .. "Base/PNC_Types.lua")
dofile(ROOT .. "Relationships/PNC_Relationships.lua")

local neutralDefaults = PNC.Types.DefaultHostility("neutral")
assertEqual(neutralDefaults.attackPlayers, false, "neutral does not initiate on players")
assertEqual(neutralDefaults.attackNPCs, true, "neutral recognizes hostile NPCs")
assertEqual(neutralDefaults.attackZombies, false, "neutral does not initiate on zombies")
assertEqual(PNC.Types.NormalizeHostility("neutral", {
    attackNPCs = false,
}).attackNPCs, true, "legacy neutral hostility migrated")

local companion = { id = "companion", faction = "colonist" }
local neutral = {
    id = "neutral",
    faction = "neutral",
    hostility = neutralDefaults,
    alive = true,
    x = 2,
    y = 3,
    z = 0,
    runtime = {},
    ownerUsername = "stale-owner",
    ownerOnlineID = 42,
}
local hostile = {
    id = "hostile",
    faction = "hostile",
    hostility = PNC.Types.DefaultHostility("hostile"),
}
assertEqual(PNC.Relationships.AreNPCsEnemies(hostile, companion), true,
    "hostile attacks companion")
assertEqual(PNC.Relationships.AreNPCsEnemies(hostile, neutral), true,
    "hostile attacks neutral")
assertEqual(PNC.Relationships.AreNPCsEnemies(companion, hostile), true,
    "companion attacks hostile")
assertEqual(PNC.Relationships.AreNPCsEnemies(neutral, hostile), true,
    "neutral attacks hostile")
assertEqual(PNC.Relationships.AreNPCsEnemies(companion, neutral), false,
    "companion and neutral remain peaceful")
assertEqual(PNC.Relationships.AreNPCsEnemies(hostile, {
    id = "hostile_two",
    faction = "hostile",
}), false, "hostiles do not attack each other")

local changed, reason = PNC.Relationships.ProvokeNeutralByPlayer(neutral)
assertEqual(changed, true, "player provocation transitions neutral")
assertEqual(reason, "changed", "player provocation result")
assertEqual(neutral.faction, "hostile", "provoked neutral becomes hostile")
assertEqual(neutral.hostility.attackPlayers, true, "provoked neutral targets players")
assertEqual(neutral.hostility.attackNPCs, true, "provoked neutral targets companions")
assertEqual(neutral.hostility.attackZombies, true, "provoked neutral uses hostile defaults")
assertEqual(neutral.ownerUsername, nil, "provoked neutral owner cleared")
assertEqual(neutral.ownerOnlineID, nil, "provoked neutral owner id cleared")
assertEqual(neutral.nextThinkAt, now, "provoked neutral reassesses immediately")
assertEqual(assignedOrder.kind, "hostile_hunt", "provoked neutral hostile order")
assertEqual(dirty.faction, true, "faction persistence dirtied")
assertEqual(dirty.hostility, true, "hostility persistence dirtied")

print("pnc_relationship_foundation_smoke: ok")
