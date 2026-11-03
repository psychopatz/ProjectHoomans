local T = require "tests/support/test"

PsychopatzCore = nil
local legacyWrites = {}
local extensionSaves = 0
local dirtyReasons = {}

local function extensions()
    return {
        Active = true,
        MarkDirty = function(reason)
            dirtyReasons[#dirtyReasons + 1] = tostring(reason)
        end,
        Save = function()
            extensionSaves = extensionSaves + 1
            return true, "extension_saved"
        end,
    }
end

local reset = {
    Read = function() return nil end,
    Check = function() return "empty_state" end,
    Mark = function() end,
    Write = function(key)
        legacyWrites[#legacyWrites + 1] = key
        return true, "written"
    end,
}

-- Faction public Save must delegate once cutover is active.
PNC = {
    Core = {},
    Factions = {
        Internal = {
            authority = function() return true end,
            copy = function(value) return value end,
            rebuildIndexes = function() end,
        },
        Registry = { revision = 1, byID = {} },
        Loaded = true,
        Dirty = true,
    },
    FactionConstants = {
        REGISTRY_MODDATA_KEY = "PNC_Factions",
        REGISTRY_SCHEMA_VERSION = 6,
        ID_GENERATION_RETRIES = 1,
    },
    FactionTypes = {
        NormalizeFactionRegistry = function(value) return value end,
        AreEqual = function() return true end,
        IsValidFactionID = function() return true end,
    },
    FactionArchetypes = {},
    EntityRef = {},
    ModDataStore = reset,
    SurvivorWorldExtensions = extensions(),
}
T.load("ProjectHoomans", "server",
    "PNC/Factions/FactionService/PNC_FactionService_RegistryPersistence.lua")
local saved, reason = PNC.Factions.Save()
T.truthy(saved, reason)
T.equal(reason, "extension_saved", "faction save redirect")

-- Community public Save must delegate too.
PNC = {
    Core = {},
    Communities = {
        Internal = {
            authority = function() return true end,
            copy = function(value) return value end,
            assignTable = function() end,
            rebuildDerivedIndexes = function() end,
            reconcileLeaders = function() end,
            reconcileNPCReferences = function() end,
        },
        Registry = {
            revision = 1, byID = {},
            byFaction = {}, sitesByID = {},
        },
        Loaded = true,
        Dirty = true,
    },
    CommunityConstants = {
        REGISTRY_MODDATA_KEY = "PNC_Communities",
        REGISTRY_SCHEMA_VERSION = 2,
        ID_GENERATION_RETRIES = 1,
    },
    CommunityTypes = {
        NormalizeRegistry = function(value) return value end,
        IsValidCommunityID = function() return true end,
    },
    CommunityMath = {},
    FactionTypes = {},
    ModDataStore = reset,
    SurvivorWorldExtensions = extensions(),
}
T.load("ProjectHoomans", "server",
    "PNC/Communities/CommunityService/PNC_CommunityService_Persistence.lua")
saved, reason = PNC.Communities.Save()
T.truthy(saved, reason)
T.equal(reason, "extension_saved", "community save redirect")

-- Abstract-world public Save follows the same boundary.
PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value) return value end,
    },
    AbstractWorldTypes = {
        NewRegistry = function()
            return {
                revision = 0,
                groupsByID = {},
                locationsByID = {},
                encounters = {},
            }
        end,
        NormalizeRegistry = function(value) return value end,
    },
    DirectorConfig = {
        MODDATA_KEY = "PNC_AbstractWorld_v1",
        SCHEMA_VERSION = 1,
    },
    ModDataStore = reset,
    SurvivorWorldExtensions = extensions(),
}
T.load("ProjectHoomans", "server",
    "PNC/Director/PNC_AbstractWorldStore.lua")
PNC.AbstractWorldStore.Loaded = true
PNC.AbstractWorldStore.Dirty = true
saved, reason = PNC.AbstractWorldStore.Save()
T.truthy(saved, reason)
T.equal(reason, "extension_saved", "abstract save redirect")

T.equal(extensionSaves, 3,
    "all three public legacy saves must delegate")
T.equal(#legacyWrites, 0,
    "active cutover must never rewrite old generic roots")
T.equal(dirtyReasons[1], "factions_save", "faction dirty reason")
T.equal(dirtyReasons[2], "communities_save", "community dirty reason")
T.equal(dirtyReasons[3], "abstract_world_save",
    "abstract dirty reason")

T.finish("pnc_survivor_world_legacy_save_redirect_smoke")
