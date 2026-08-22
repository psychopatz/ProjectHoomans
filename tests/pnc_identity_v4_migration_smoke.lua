local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = deepCopy(item) end
    return result
end

local store = {}
local globalSaves = 0
ModData = {
    getOrCreate = function(key)
        store[key] = store[key] or {}
        return store[key]
    end,
}
GlobalModData = { save = function() globalSaves = globalSaves + 1 end }
getGameTime = function()
    return { getWorldAgeHours = function() return 500 end }
end
getTimeInMillis = function() return 500000 end
ZombRand = function() return 7 end

PNC = { Core = {
    DeepCopy = deepCopy,
    GenerateID = function(prefix) return prefix .. "_new" end,
    Now = function() return 500000 end,
    IsAuthority = function() return true end,
} }
T.load(SHARED .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Identity/PNC_PlayerCharacterTypes.lua")

local records = {}
for index = 1, 6 do
    local uuid = "char_legacy_" .. index
    records[uuid] = {
        uuid = uuid,
        accountIdentity = index % 2 == 0 and "Psychopatz" or "Bob",
        status = "active",
        createdAt = 100 + index,
        firstSeenAt = 100 + index,
        lastSeenAt = 200 + index,
        forename = "Psychopatz",
        surname = "Survivor",
        displayName = index % 2 == 0 and "Psychopatz" or "Bob",
        lastKnownX = 1000 + index,
        lastKnownY = 2000 + index,
        lastKnownZ = 0,
        revision = index,
    }
end
store.PNC_PlayerCharacters = {
    schemaVersion = 3,
    revision = 8,
    byUUID = records,
}

local oldRelationshipKey = "player:Bob:char_legacy_3"
local npc = {
    id = "npc_doyle",
    social = { relationships = {
        [oldRelationshipKey] = {
            familiarity = 45,
            memories = {
                { id = "met_doyle", type = "met", aboutKey = oldRelationshipKey,
                    createdAt = 150, strength = 1 },
            },
        },
    } },
}
PNC.Registry = {
    Data = { npc_doyle = npc },
    Get = function(id) return PNC.Registry.Data[tostring(id)] end,
    ForEach = function(callback)
        for id, value in pairs(PNC.Registry.Data) do callback(value, id) end
    end,
    MarkDirty = function(record) record.dirty = true end,
    FlushDirty = function() return 1 end,
}
PNC.RelationshipMath = {
    RecalculateRelationship = function(value, key)
        value.targetID = key
        return value, true
    end,
}

PNC.NPCKnowledge = {
    Registry = { schemaVersion = 1, revision = 2, byCharacter = {
        char_legacy_5 = { byNPC = { npc_doyle = {
            npcID = "npc_doyle", firstMetAt = 120,
            lastInteractionAt = 240, revision = 2,
            discovered = { ["identity.name"] = {
                descriptorID = "identity.name", status = "confirmed",
                value = "Doyle Wild", discoveredAt = 120,
                lastUpdatedAt = 240, revision = 2,
            } },
            evidence = { { id = "doyle_intro", createdAt = 120 } },
            journalEntries = {}, manualNotes = {},
        } } },
    } },
    EnsureLoaded = function() return true end,
    NormalizeRegistry = function(value) return deepCopy(value) end,
    Save = function()
        if not PNC.NPCKnowledge.Dirty then return false, "not_dirty" end
        store.PNC_NPCKnowledge = deepCopy(PNC.NPCKnowledge.Registry)
        PNC.NPCKnowledge.Dirty = false
        return true, "saved"
    end,
}

local function faction(id, key, member)
    return {
        id = id, status = "active", revision = 1,
        ownerPlayerKey = key, playerMemberKeys = { [key] = true },
        memberIDs = member and { [member] = true } or {},
        playerPacifications = {}, relations = {}, tags = {},
    }
end
PNC.Factions = {
    Registry = { revision = 1, byID = {
        faction_one = faction("faction_one", "player:Bob:char_legacy_3"),
        faction_two = faction("faction_two", "player:Psychopatz:char_legacy_6", "npc_doyle"),
    }, byPlayerKey = {} },
    EnsureLoaded = function() return true end,
    RebuildIndexes = function()
        PNC.Factions.Registry.byPlayerKey = {}
        for id, value in pairs(PNC.Factions.Registry.byID) do
            for key in pairs(value.playerMemberKeys) do
                PNC.Factions.Registry.byPlayerKey[key] = id
            end
        end
    end,
    Save = function()
        if not PNC.Factions.Dirty then return false, "not_dirty" end
        PNC.Factions.Dirty = false
        return true, "saved"
    end,
}

T.load(SERVER .. "PNC_PlayerCharacterService.lua")
PNC.PlayerCharacters.Load()
T.load(SERVER .. "PNC_PersistenceCoordinator.lua")
T.load(SERVER .. "PNC_PlayerIdentityMigration.lua")

local username = "Bob"
local mirror = { PNC_CharacterUUID = "char_legacy_6" }
local player = {
    getPlayerNum = function() return 0 end,
    getUsername = function() return username end,
    getOnlineID = function() return -1 end,
    getModData = function() return mirror end,
    getDisplayName = function() return username end,
    getDescriptor = function()
        return {
            getForename = function() return "Psychopatz" end,
            getSurname = function() return "Survivor" end,
        }
    end,
    getX = function() return 1006 end,
    getY = function() return 2006 end,
    getZ = function() return 0 end,
}

local context, reason = PNC.PlayerContext.Resolve(player, "fixture_bootstrap")
T.equal(reason, "reused", "migration binds canonical mirror")
T.equal(context.accountKey, "sp_slot_0", "SP account key ignores username")
T.equal(context.characterUUID, "char_legacy_6", "valid mirror wins canonical choice")
T.equal(PNC.PlayerCharacters.Registry.migration.status, "complete",
    "migration completes")
T.truthy(store.PNC_PlayerCharacters_v3_Backup.created,
    "v3 registry backup retained")
T.equal(globalSaves, 1, "migration flushes GlobalModData once")

local active = 0
for uuid, record in pairs(PNC.PlayerCharacters.Registry.byUUID) do
    if record.status == "active" then active = active + 1 end
    if uuid ~= "char_legacy_6" then
        T.equal(record.supersededBy, "char_legacy_6", "duplicate tombstone alias")
        T.equal(PNC.PlayerCharacters.Registry.uuidAliases[uuid],
            "char_legacy_6", "UUID alias retained")
    end
end
T.equal(active, 1, "one active SP survivor remains")
T.equal(PNC.NPCKnowledge.Registry.byCharacter.char_legacy_6.byNPC
    .npc_doyle.discovered["identity.name"].value,
    "Doyle Wild", "Doyle knowledge merged into canonical survivor")
local canonicalKey = "player:sp_slot_0:char_legacy_6"
T.truthy(npc.social.relationships[canonicalKey] ~= nil,
    "relationship rekeyed to canonical entity")
T.equal(npc.social.relationships[oldRelationshipKey], nil,
    "legacy relationship key removed")
T.equal(PNC.Factions.Registry.byPlayerKey[canonicalKey], "faction_two",
    "canonical player faction retained")
T.equal(PNC.Factions.Registry.byID.faction_one.status, "archived",
    "duplicate player faction archived")

username = "Psychopatz"
local second = PNC.PlayerContext.Resolve(player, "username_changed")
T.equal(second.characterUUID, context.characterUUID,
    "username change cannot invalidate runtime binding")
local again, againReason = PNC.PlayerIdentityMigration.RunForPlayer(
    player, "sp_slot_0", 501
)
T.equal(again, "char_legacy_6", "idempotent migration canonical UUID")
T.equal(againReason, "already_migrated", "migration is idempotent")

PNC.PlayerCharacters.Unbind(player, "fixture_restart", 502, true)
local restarted = setmetatable({
    getModData = function() return {} end,
    getUsername = function() return "Bob" end,
}, { __index = player })
local restartContext = PNC.PlayerContext.Resolve(
    restarted, "restart_without_mirror"
)
T.equal(restartContext.characterUUID, "char_legacy_6",
    "restart without player mirror recovers canonical SP survivor")

T.truthy(PNC.PlayerCharacters.MarkDead(restarted, 503, "fixture_death"),
    "genuine death retires canonical survivor")
local successor = setmetatable({
    getModData = function() return {} end,
    getUsername = function() return "Psychopatz" end,
}, { __index = player })
local successorContext = PNC.PlayerContext.Resolve(successor, "post_death_survivor")
T.equal(successorContext.characterUUID, "char_new",
    "genuine post-death survivor receives new UUID")
T.equal(PNC.NPCKnowledge.Registry.byCharacter[successorContext.characterUUID], nil,
    "new survivor does not inherit canonical knowledge")
T.finish("pnc_identity_v4_migration_smoke")

T.finish("pnc_identity_v4_migration_smoke")
