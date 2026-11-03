local T = require "tests/support/test"

PsychopatzCore = nil
local calls = {}

local function adapter()
    return {
        CommitFaction = function(value, reason)
            calls[#calls + 1] = { "faction", value.id, reason }
            return { id = value.id }
        end,
        CommitCommunity = function(value, reason)
            calls[#calls + 1] = { "community", value.id, reason }
            return { id = value.id }
        end,
        CommitGroup = function(value, reason)
            calls[#calls + 1] = { "group", value.id, reason }
            return { id = value.id }
        end,
        CommitLocation = function(value, reason)
            calls[#calls + 1] = { "location", value.id, reason }
            return { id = value.id }
        end,
    }
end

-- Faction shared mutation choke point.
PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value) return value end,
        GenerateID = function(kind) return kind .. "_generated" end,
        LogWarn = function() end,
    },
    Factions = { Internal = {} },
    FactionConstants = {},
    FactionTypes = {
        NewFactionRegistry = function()
            return { revision = 0, byID = {} }
        end,
    },
    FactionArchetypes = {},
    EntityRef = {},
    CoreSurvivorWorldAdapter = adapter(),
}
T.load("ProjectHoomans", "server",
    "PNC/Factions/FactionService/PNC_FactionService_State.lua")
local faction = { id = "faction_hook", revision = 3 }
PNC.Factions.Internal.touchFaction(faction)
T.equal(faction.revision, 4, "faction revision")
T.equal(calls[#calls][1], "faction", "faction hook domain")
T.equal(calls[#calls][2], "faction_hook", "faction hook id")

-- Community shared mutation choke point.
PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value) return value end,
        GenerateID = function(kind) return kind .. "_generated" end,
        LogWarn = function() end,
    },
    Communities = { Internal = {} },
    CommunityConstants = {},
    CommunityTypes = {
        NewRegistry = function()
            return {
                revision = 0,
                byID = {},
                byFaction = {},
                sitesByID = {},
            }
        end,
    },
    CommunityMath = {
        Clamp = function(value, _, _, fallback)
            return tonumber(value) or tonumber(fallback) or 0
        end,
    },
    FactionTypes = {},
    CoreSurvivorWorldAdapter = adapter(),
}
T.load("ProjectHoomans", "server",
    "PNC/Communities/CommunityService/PNC_CommunityService_Core.lua")
local community = { id = "community_hook", revision = 8 }
PNC.Communities.Internal.touchCommunity(community)
T.equal(community.revision, 9, "community revision")
T.equal(calls[#calls][1], "community", "community hook domain")
T.equal(calls[#calls][2], "community_hook", "community hook id")

-- Abstract group shared mutation choke point.
PNC = {
    Core = {
        IsAuthority = function() return true end,
        LogWarn = function() end,
    },
    Const = {},
    AbstractGroups = {},
    AbstractGroupManagerInternal = {},
    AbstractWorldStore = {
        Touch = function(reason)
            calls[#calls + 1] = { "legacy_group_touch", reason }
        end,
    },
    AbstractWorldTypes = {},
    DirectorConfig = {},
    AbstractLocations = {},
    CoreSurvivorWorldAdapter = adapter(),
}
T.load("ProjectHoomans", "server",
    "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_Core.lua")
local group = { id = "agroup_hook", revision = 2 }
PNC.AbstractGroupManagerInternal.Touch(group, "group_test")
T.equal(group.revision, 3, "group revision")
T.equal(calls[#calls - 1][1], "group", "group hook domain")
T.equal(calls[#calls - 1][2], "agroup_hook", "group hook id")
T.equal(calls[#calls][1], "legacy_group_touch",
    "legacy extension view still receives temporary dirty marker")

-- Location registration commits Core before inserting the PNC compatibility
-- view, so a Core rejection cannot leave a new PNC-only generic location.
PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value) return value end,
    },
    AbstractLocations = {},
    AbstractLocationManagerInternal = {
        Authority = function() return true end,
        Index = function() end,
        SiteLocationID = function() return nil end,
    },
    AbstractWorldStore = {
        Registry = { locationsByID = {} },
        EnsureLoaded = function() return true end,
        Touch = function() end,
        Emit = function() end,
    },
    AbstractWorldTypes = {
        NormalizeLocation = function(spec)
            return {
                id = spec.id,
                type = spec.type,
                x = spec.x, y = spec.y, z = spec.z,
            }
        end,
    },
    DirectorConfig = {},
    CoreSurvivorWorldAdapter = adapter(),
}
T.load("ProjectHoomans", "server",
    "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Registration.lua")
local location, reason = PNC.AbstractLocations.Register({
    id = "aloc_hook",
    type = "BUILDING",
    x = 10, y = 20, z = 0,
})
T.truthy(location, reason)
T.equal(calls[#calls][1], "location", "location hook domain")
T.equal(calls[#calls][2], "aloc_hook", "location hook id")
T.truthy(PNC.AbstractWorldStore.Registry.locationsByID.aloc_hook,
    "PNC compatibility view receives accepted Core location")

T.finish("pnc_core_survivor_world_mutation_hooks_smoke")
