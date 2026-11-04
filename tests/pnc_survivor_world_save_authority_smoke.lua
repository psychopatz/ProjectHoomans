local T = require "tests/support/test"

PsychopatzCore = nil
local retiredRootWrites = {}
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
        retiredRootWrites[#retiredRootWrites + 1] = key
        return true, "written"
    end,
}

-- Faction view commit must delegate once cutover is active.
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
    "PNC/Factions/FactionService/PNC_FactionService_WorldView.lua")
local saved, reason = PNC.Factions.Commit()
T.truthy(saved, reason)
T.equal(reason, "extension_saved", "faction save redirect")

-- Community view commit must delegate too.
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
    "PNC/Communities/CommunityService/PNC_CommunityService_WorldView.lua")
saved, reason = PNC.Communities.Commit()
T.truthy(saved, reason)
T.equal(reason, "extension_saved", "community save redirect")

T.equal(extensionSaves, 2,
    "faction and community view commits must delegate")
T.equal(#retiredRootWrites, 0,
    "active cutover must never rewrite old generic roots")
T.equal(dirtyReasons[1], "faction_view_commit",
    "faction view commit reason")
T.equal(dirtyReasons[2], "community_view_commit",
    "community view commit reason")

-- A missing cutover must fail closed even in a detached/partial runtime; there
-- is no supported standalone generic-world writer anymore.
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
}
T.load("ProjectHoomans", "server",
    "PNC/Factions/FactionService/PNC_FactionService_WorldView.lua")
saved, reason = PNC.Factions.Commit()
T.falsy(saved,
    "partial runtime must not fall back to retired faction writes")
T.equal(reason, "survivor_world_cutover_unavailable",
    "missing cutover fails closed")
T.equal(#retiredRootWrites, 0,
    "fail-closed save still writes no retired generic root")

T.finish("pnc_survivor_world_save_authority_smoke")
