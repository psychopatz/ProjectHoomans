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

-- Looter assignment immediately strips companion ownership and becomes
-- hostile-hunt behavior.
truthy(Factions.AddNPC(
    looterFaction.id,
    looterNPC.id,
    { joinedAt = hour }
), "assign looter")
equal(looterNPC.faction, "hostile", "looter tactical class")
equal(looterNPC.recruited, false, "looter not companion")
equal(looterNPC.ownerUsername, nil, "looter owner cleared")
equal(looterNPC.hostility.attackPlayers, true,
    "looter attacks outsiders")
equal(looterNPC.orderSpec.kind, PNC.Const.ORDER_HOSTILE_HUNT,
    "looter hunt order")

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
        reason = "test_war",
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

-- Peace restores a non-looter faction to neutral. Looters remain hostile by
-- archetype even without a formal war.
truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1,
        reason = "test_peace",
    }
), "make peace")
equal(traderNPC.faction, "neutral",
    "peace restores neutral behavior")
equal(Factions.CanNPCTargetPlayer(traderNPC, player),
    false, "peace stops player targeting")
truthy(PNC.Relationships.AreNPCsEnemies(
    looterNPC,
    playerNPC
), "looter remains outsider-hostile")

-- An enemy personal relationship and authoritative damage both escalate to
-- faction-wide war.
truthy(Factions.OnRelationshipChanged(
    traderNPC,
    playerKey,
    { state = "enemy", lastEvaluatedAt = hour + 1 }
), "enemy relationship starts war")
truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "relationship war persisted")
truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.5,
        reason = "reset_for_aggression_test",
    }
), "reset relationship war")

hour = hour + 2
truthy(Factions.OnPlayerAggression(
    player,
    traderNPC,
    hour
), "player aggression starts war")
truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "aggression war persisted")
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

-- V1 faction registries deterministically migrate to V2.
local migrated = PNC.FactionTypes.NormalizeFactionRegistry({
    schemaVersion = 1,
    revision = 3,
    byID = Factions.Registry.byID,
    byArchetype = Factions.Registry.byArchetype,
})
equal(migrated.schemaVersion, 2, "registry migrated to V2")
truthy(type(migrated.byPlayerKey) == "table",
    "player index added")
truthy(type(migrated.diplomacy) == "table",
    "diplomacy table added")
saveSafe(Factions.Registry)

print("pnc_faction_warfare_smoke: ok")
