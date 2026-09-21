local T = require "tests/support/test"

T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")
local ownerKey = "player:mp_account:character_mp"
local identityCalls = 0
local identityMode = "ready"
local fallbackCharacterLookups = 0
local factionLookups = 0
local storageContext

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[key] = deepCopy(child)
    end
    return output
end

local faction = {
    id = "faction_mp",
    name = "Multiplayer Colony",
    archetypeID = "settler",
    revision = 1,
    tags = {},
    ownerPlayerKey = ownerKey,
    playerMemberKeys = { [ownerKey] = true },
}

local player = {
    getUsername = function() return "mp-user" end,
    getOnlineID = function() return 17 end,
}

PNC = {
    Core = { DeepCopy = deepCopy },
    Const = { ORDER_FOLLOW = "follow" },
    NeedsDefinitions = {
        TYPES = { "hunger", "thirst", "fatigue" },
        GetLevel = function(_, value)
            return tonumber(value) and tonumber(value) > 0.8
                and "CRITICAL" or "NORMAL"
        end,
    },
    NeedsUtils = { WorldAgeHours = function() return 100 end },
    WorkPolicy = {
        IsEnabled = function() return true end,
        Snapshot = function() return {} end,
    },
    IndividualNeeds = {
        Ensure = function(record) return record.needs end,
        GetHighestPriority = function() return nil, 0 end,
        GetActivity = function() return "Following" end,
    },
    PlayerCharacters = {
        GetEntityKey = function(_, options)
            identityCalls = identityCalls + 1
            T.equal(options.callback, "colony_management_snapshot",
                "snapshot identity callback")
            if identityMode == "pending" then
                return nil, "binding_context_unavailable"
            end
            return ownerKey, "resolved"
        end,
        GetCharacterUUID = function()
            fallbackCharacterLookups = fallbackCharacterLookups + 1
            return nil, "fallback_lookup_should_not_run"
        end,
    },
    Factions = {
        Get = function(id)
            factionLookups = factionLookups + 1
            return id == faction.id and faction or nil
        end,
        GetFactionForPlayerKey = function(key)
            return key == ownerKey and faction or nil
        end,
        GetPlayerFaction = function()
            error("legacy faction lookup should not run")
        end,
    },
    ColonyStorageService = {
        BuildSnapshot = function(_, _, ownershipContext)
            storageContext = ownershipContext
            if ownershipContext and ownershipContext.unavailable then
                return nil, ownershipContext.reason
            end
            return {
                storageId = "storage_mp",
                access = {
                    hasStockpile = true,
                    insideBase = true,
                    reason = "writable",
                },
            }
        end,
    },
    Registry = { Data = {
        npc_one = {
            id = "npc_one", name = "One", alive = true,
            recruited = true,
            affiliation = { factionID = faction.id },
            needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
            orderSpec = { kind = "follow", ownerUsername = "mp-user" },
        },
        npc_two = {
            id = "npc_two", name = "Two", alive = true,
            recruited = true,
            affiliation = { factionID = faction.id },
            needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
            orderSpec = { kind = "follow", ownerUsername = "mp-user" },
        },
    } },
}

T.load(SHARED .. "PNC/Core/Identity/PNC_Identity_Verifier.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandRegistry.lua")
T.load(SERVER .. "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Core.lua")
T.load(SERVER .. "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots.lua")

local snapshot = PNC.ColonyManagement.BuildSnapshot(player)
T.equal(identityCalls, 1,
    "multiplayer snapshot resolves identity once for all NPCs")
T.equal(factionLookups, 2,
    "each owned NPC is checked once during snapshot construction")
T.equal(fallbackCharacterLookups, 0,
    "snapshot ownership does not repeat character lookups")
T.equal(snapshot.identityStatus.state, "ready",
    "resolved multiplayer identity is reported ready")
T.equal(storageContext.playerKey, ownerKey,
    "storage receives the resolved multiplayer identity context")
T.equal(snapshot.storageStatus.state, "ready",
    "storage status is ready with the resolved identity")
T.equal(#snapshot.people, 2,
    "canonical multiplayer faction members appear in the roster")

identityMode = "pending"
local pending = PNC.ColonyManagement.BuildSnapshot(player)
T.equal(identityCalls, 2,
    "identity is retried on the next snapshot request")
T.equal(pending.identityStatus.state, "pending",
    "identity failure is explicit in the snapshot")
T.equal(pending.identityStatus.reason, "binding_context_unavailable",
    "identity failure reason is preserved")
T.equal(pending.storageStatus.state, "pending",
    "storage remains pending while multiplayer identity is unavailable")
T.equal(#pending.people, 0,
    "unresolved identity cannot expose NPCs")

T.finish("pnc_colony_management_mp_identity_smoke")
