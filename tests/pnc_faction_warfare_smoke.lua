local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    equal(value == true, true, label)
end

local function saveSafe(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "string"
        or kind == "number" or kind == "boolean"
    then
        return
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        error("unsafe faction warfare value: " .. kind)
    end
    seen = seen or {}
    if seen[value] then error("cycle in faction warfare value") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe faction warfare key")
        end
        saveSafe(item, seen)
    end
    seen[value] = nil
end

local hour = 50
local globalData = {}

-- Project Zomboid's Kahlua runtime does not expose Lua's global next().
-- Keep it absent across the complete faction service/behavior path.
next = nil

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return hour * 3600000 end
function getGameTime()
    return {
        getWorldAgeHours = function() return hour end,
    }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

PNC = {}
dofile(SHARED .. "Base/PNC_Core.lua")
dofile(SHARED .. "Base/PNC_Constants.lua")
dofile(SHARED .. "Relationships/PNC_EntityRef.lua")
dofile(SHARED .. "Factions/PNC_FactionConstants.lua")
dofile(SHARED .. "Factions/PNC_FactionArchetypes.lua")
dofile(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
dofile(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
dofile(SHARED .. "Factions/PNC_FactionIntent.lua")
dofile(SHARED .. "Factions/PNC_FactionTypes.lua")

PNC.Types = {
    NormalizeFaction = function(value)
        value = tostring(value or "neutral")
        if value == "colonist" or value == "hostile" then
            return value
        end
        return "neutral"
    end,
    DefaultHostility = function(value)
        if value == "colonist" then
            return {
                mode = "defend_owner",
                attackPlayers = false,
                attackNPCs = true,
                attackZombies = true,
            }
        end
        return {
            mode = "neutral",
            attackPlayers = false,
            attackNPCs = true,
            attackZombies = false,
        }
    end,
}

local dirty = {}
PNC.Registry = { Data = {} }
function PNC.Registry.Get(id) return PNC.Registry.Data[id] end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    if not dirty[record.id] then
        record.recordRevision =
            (tonumber(record.recordRevision) or 0) + 1
    end
    dirty[record.id] = true
    return true
end

PNC.OrderSystem = {
    SetOrder = function(record, order)
        record.orderSpec = PNC.Core.DeepCopy(order)
    end,
}
PNC.SimulationClock = { Wake = function() end }

local playerKey = "player:Patrick:char_player"
local player = {
    uuid = "char_player",
    getUsername = function() return "Patrick" end,
    getDisplayName = function() return "Patrick" end,
    getOnlineID = function() return 7 end,
}
PNC.PlayerCharacters = {
    RuntimeByUUID = { char_player = player },
    GetCharacterUUID = function(value)
        return value and value.uuid
    end,
    GetEntityKey = function()
        return playerKey, "resolved"
    end,
}

local function npc(id)
    local record = {
        id = id,
        name = id,
        alive = true,
        faction = "colonist",
        recruited = true,
        ownerUsername = "Patrick",
        ownerOnlineID = 7,
        hostility = {
            attackPlayers = false,
            attackNPCs = true,
            attackZombies = true,
        },
        affiliation = PNC.FactionTypes.NewAffiliation(),
        recordRevision = 0,
        presenceRevision = 9,
        runtime = {},
        x = 10,
        y = 20,
        z = 0,
    }
    PNC.Registry.Data[id] = record
    return record
end

local looterNPC = npc("npc_looter")
local playerNPC = npc("npc_player_member")
local traderNPC = npc("npc_trader")

dofile(SERVER .. "PNC_FactionService.lua")
dofile(SERVER .. "PNC_FactionIncidentService.lua")
dofile(SERVER .. "PNC_FactionBehavior.lua")
dofile(SHARED .. "Relationships/PNC_Relationships.lua")
dofile(SHARED .. "Commands/PNC_CompanionCommandRegistry.lua")

local Factions = PNC.Factions
Factions.Load()
local ids = {
    "faction_player",
    "faction_looter",
    "faction_trader",
}
local idIndex = 0
Factions.IDGenerator = function()
    idIndex = idIndex + 1
    return ids[idIndex]
end

-- Stable player-character identity owns a persistent faction.
local ok, reason, playerFaction =
    Factions.CreatePlayerFaction(player, {
        name = "Patrick Survivors",
        createdAt = hour,
    })
truthy(ok, "player faction created")
equal(playerFaction.ownerPlayerKey, playerKey,
    "stable player owner key")
equal(Factions.GetPlayerFaction(player).id,
    playerFaction.id, "player faction lookup")

local _, _, looterFaction = Factions.Create({
    name = "Mill Looters",
    archetypeID = "looter",
    createdAt = hour,
})
local _, _, traderFaction = Factions.Create({
    name = "Knox Traders",
    archetypeID = "trader",
    createdAt = hour,
})

-- Looter assignment strips companion ownership, but archetype alone does
-- not grant lethal intent.
truthy(Factions.AddNPC(
    looterFaction.id,
    looterNPC.id,
    { joinedAt = hour }
), "assign looter")
equal(looterNPC.faction, "neutral", "looter tactical class")
equal(looterNPC.recruited, false, "looter not companion")
equal(looterNPC.ownerUsername, nil, "looter owner cleared")
equal(looterNPC.hostility.attackPlayers, false,
    "looter does not auto-attack outsiders")
equal(looterNPC.orderSpec.kind, PNC.Const.ORDER_ROAM,
    "looter follows nonlethal policy")

-- Player-owned faction membership derives companion ownership.
truthy(Factions.AddNPC(
    playerFaction.id,
    playerNPC.id,
    { joinedAt = hour }
), "assign player faction NPC")
equal(playerNPC.faction, "colonist",
    "player member tactical class")
equal(playerNPC.recruited, true,
    "player member companion")
equal(playerNPC.ownerUsername, "Patrick",
    "player member stable owner")
equal(playerNPC.orderSpec.kind, PNC.Const.ORDER_FOLLOW,
    "player member follows owner")
truthy(PNC.CompanionCommands.IsOwnedByPlayer(
    playerNPC,
    player
), "owner character can command member")
local replacementSurvivor = {
    uuid = "char_replacement",
    getUsername = function() return "Patrick" end,
    getOnlineID = function() return 8 end,
}
equal(PNC.CompanionCommands.IsOwnedByPlayer(
    playerNPC,
    replacementSurvivor
), false, "same account replacement cannot inherit faction")

-- Non-hostile external factions are neutral until war.
truthy(Factions.AddNPC(
    traderFaction.id,
    traderNPC.id,
    { joinedAt = hour }
), "assign trader")
equal(traderNPC.faction, "neutral",
    "trader initially neutral")
equal(traderNPC.recruited, false,
    "trader not companion")
equal(Factions.CanNPCTargetPlayer(traderNPC, player),
    false, "neutral trader ignores player")

-- War is symmetric, revisioned once, and updates every member's behavior.
local beforeWarRevision = Factions.Registry.revision
truthy(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour,
        reason = "manual_debug",
        instigatorFactionID = playerFaction.id,
    }
), "declare war")
truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "forward war")
truthy(Factions.AreAtWar(
    traderFaction.id,
    playerFaction.id
), "reverse war")
equal(traderNPC.faction, "hostile",
    "war activates aggressive behavior")
equal(traderNPC.hostility.attackPlayers, true,
    "war attacks enemy player faction")
truthy(PNC.Relationships.AreNPCsEnemies(
    traderNPC,
    playerNPC
), "war NPC targeting")
truthy(Factions.CanNPCTargetPlayer(traderNPC, player),
    "war player targeting")
equal(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    { worldAgeHours = hour }
), false, "duplicate war unchanged")
equal(Factions.Registry.revision,
    beforeWarRevision + 1, "duplicate war no revision")

-- Peace restores external factions to nonlethal policy.
truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1,
        reason = "manual_debug",
    }
), "make peace")
equal(traderNPC.faction, "neutral",
    "peace restores neutral behavior")
equal(Factions.CanNPCTargetPlayer(traderNPC, player),
    false, "peace stops player targeting")
equal(PNC.Relationships.AreNPCsEnemies(
    looterNPC,
    playerNPC
), false, "looter policy alone is nonlethal")

-- Personal enemy state is reported only by faction authority and does not
-- immediately declare war under the safe default.
truthy(Factions.SetLeader(
    traderFaction.id,
    traderNPC.id,
    hour + 1
), "set faction leader")
truthy(Factions.OnRelationshipChanged(
    traderNPC,
    playerKey,
    {
        state = "enemy",
        lastEvaluatedAt = hour + 1,
        revision = 1,
    }
), "leader reports personal grievance")
equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "personal enemy does not force war")

hour = hour + 2
truthy(Factions.OnPlayerAggression(
    player,
    traderNPC,
    hour
), "first attack records incident")
equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "minor attack does not force war")
truthy(Factions.OnPlayerAggression(
    player,
    traderNPC,
    hour + 0.001,
    { killed = true }
), "death upgrades attack episode")
truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "member death escalates to war")
truthy(Factions.Archive(
    traderFaction.id,
    "test_archive",
    hour + 1
), "archive warring faction")
equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "archive ends active war")
equal(traderNPC.affiliation.factionID, nil,
    "archive removes membership")
equal(traderNPC.faction, "neutral",
    "archived member becomes neutral")
equal(looterNPC.presenceRevision, 9,
    "looter behavior leaves presence revision")
equal(playerNPC.presenceRevision, 9,
    "player faction behavior leaves presence revision")
equal(traderNPC.presenceRevision, 9,
    "war behavior leaves presence revision")

-- V2 pair diplomacy deterministically migrates to two V3 directions.
local migrated = PNC.FactionTypes.NormalizeFactionRegistry({
    schemaVersion = 2,
    revision = 3,
    byID = {
        faction_old_a = {
            id = "faction_old_a",
            name = "Old A",
            archetypeID = "settler",
        },
        faction_old_b = {
            id = "faction_old_b",
            name = "Old B",
            archetypeID = "looter",
        },
    },
    diplomacy = {
        ["faction_old_a|faction_old_b"] = {
            factionAID = "faction_old_a",
            factionBID = "faction_old_b",
            state = "war",
            changedAt = 20,
            revision = 2,
        },
    },
})
equal(migrated.schemaVersion, 3, "registry migrated to V3")
truthy(type(migrated.byPlayerKey) == "table",
    "player index added")
equal(migrated.diplomacy, nil,
    "legacy pair table removed")
truthy(migrated.byID.faction_old_a
    .relations.faction_old_b.atWar,
    "forward war migrated")
truthy(migrated.byID.faction_old_b
    .relations.faction_old_a.atWar,
    "reverse war migrated")
saveSafe(Factions.Registry)

print("pnc_faction_warfare_smoke: ok")
