local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
    get = function(key)
        return roots[key]
    end,
}

local initCallbacks = {}
local saveCallbacks = {}
Events = {
    OnInitGlobalModData = {
        Add = function(callback)
            initCallbacks[#initCallbacks + 1] = callback
        end,
    },
    OnSave = {
        Add = function(callback)
            saveCallbacks[#saveCallbacks + 1] = callback
        end,
    },
}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(child, seen)
    end
    return output
end

PNC = {
    Core = { DeepCopy = deepCopy },
}

roots.PNC_Factions = {
    schemaVersion = 6,
    revision = 1,
    byID = {
        faction_import = {
            id = "faction_import",
            name = "Imported Faction",
            archetypeID = "survivor",
            memberIDs = {
                actor_import = true,
            },
        },
    },
}
roots.PNC_Communities = {
    schemaVersion = 2,
    revision = 1,
    byID = {
        community_import = {
            id = "community_import",
            factionID = "faction_import",
            name = "Imported Camp",
            mode = "settled",
            status = "active",
            home = {
                x = 100, y = 200, z = 0, radius = 20,
            },
            memberIDs = {
                actor_import = true,
            },
        },
    },
    sitesByID = {},
}
roots.PNC_AbstractWorld_v1 = {
    schemaVersion = 1,
    revision = 4,
    locationsByID = {
        aloc_import = {
            id = "aloc_import",
            type = "SETTLEMENT",
            x = 100, y = 200, z = 0,
        },
    },
    groupsByID = {
        agroup_import = {
            id = "agroup_import",
            factionId = "faction_import",
            homeCommunityId = "community_import",
            groupType = "CARAVAN",
            memberIds = { "actor_import" },
            leaderId = "actor_import",
            location = {
                id = "aloc_import",
                type = "SETTLEMENT",
                x = 100, y = 200, z = 0,
            },
        },
    },
    encounters = {},
    encounterCooldowns = {},
    population = {
        worldSeed = 5150,
        sectors = {},
    },
}
roots.PNC_WorldDiscovery_v1 = {
    schemaVersion = 2,
    revision = 1,
    players = {
        player_import = {
            revision = 1,
            entities = {
                settlement = {
                    community_import = {
                        phase = 3,
                        source = "visit",
                        x = 100, y = 200, z = 0,
                    },
                },
                mobile_group = {},
            },
        },
    },
}

local before = deepCopy({
    factions = roots.PNC_Factions,
    communities = roots.PNC_Communities,
    abstractWorld = roots.PNC_AbstractWorld_v1,
    discovery = roots.PNC_WorldDiscovery_v1,
})

local Authority = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_CoreSurvivorWorldAuthority.lua"
)

T.truthy(Authority.Registry,
    "Hoomans must activate Core SurvivorWorld runtime")
T.equal(roots["PsychopatzCore.SurvivorWorld"], nil,
    "activation must not allocate Core ModData before init")

local preview, source = Authority.PreviewImport()
T.truthy(preview and source, "import preview must succeed")
T.equal(preview.worldSeed, 5150, "imported world seed")
T.truthy(preview.factions.faction_import, "faction preview")
T.truthy(preview.communities.community_import, "community preview")
T.truthy(preview.groups.agroup_import, "group preview")
T.truthy(
    preview.discovery.players.player_import,
    "discovery preview"
)

local status = Authority.RefreshStatus()
T.truthy(status.coreEmpty, "Core begins empty")
T.truthy(status.needsImport,
    "pre-SurvivorWorld data must report pending import")

for _, callback in ipairs(initCallbacks) do callback() end
status = Authority.RefreshStatus()
T.truthy(status.needsImport,
    "init must not auto-import or dual-write source data")

local registry, reason = Authority.ImportPreSurvivorWorld({
    reason = "test_cutover",
})
T.truthy(registry, reason)
T.truthy(registry:GetFaction("faction_import"),
    "imported faction missing")
T.truthy(registry:GetCommunity("community_import"),
    "imported community missing")
T.truthy(registry:GetGroup("agroup_import"),
    "imported group missing")

local root = roots["PsychopatzCore.SurvivorWorld"]
T.truthy(root and type(root.registry) == "string",
    "import must persist the Core world root")

T.equal(
    roots.PNC_Factions.byID.faction_import.name,
    before.factions.byID.faction_import.name,
    "faction import source must remain read-only"
)
T.equal(
    roots.PNC_AbstractWorld_v1.revision,
    before.abstractWorld.revision,
    "abstract-world import source must remain read-only"
)

local duplicate, duplicateReason =
    Authority.ImportPreSurvivorWorld()
T.falsy(duplicate,
    "non-empty Core world must reject accidental re-import")
T.equal(
    duplicateReason,
    "core_survivor_world_not_empty",
    "re-import rejection reason"
)

status = Authority.RefreshStatus()
T.falsy(status.coreEmpty, "Core should now be authoritative candidate")
T.falsy(status.needsImport,
    "completed import should clear import need")

T.finish("pnc_core_survivor_world_authority_smoke")
