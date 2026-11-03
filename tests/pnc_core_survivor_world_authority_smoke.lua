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
    Factions = {
        Registry = {
            byID = {
                faction_legacy = {
                    id = "faction_legacy",
                    name = "Legacy Faction",
                    archetypeID = "survivor",
                    memberIDs = {
                        actor_legacy = true,
                    },
                },
            },
        },
        EnsureLoaded = function() return true end,
    },
    Communities = {
        Registry = {
            byID = {
                community_legacy = {
                    id = "community_legacy",
                    factionID = "faction_legacy",
                    name = "Legacy Camp",
                    home = {
                        x = 100, y = 200, z = 0, radius = 20,
                    },
                    memberIDs = {
                        actor_legacy = true,
                    },
                },
            },
        },
        EnsureLoaded = function() return true end,
    },
    AbstractWorldStore = {
        Registry = {
            revision = 4,
            locationsByID = {
                aloc_legacy = {
                    id = "aloc_legacy",
                    type = "SETTLEMENT",
                    x = 100, y = 200, z = 0,
                },
            },
            groupsByID = {
                agroup_legacy = {
                    id = "agroup_legacy",
                    factionId = "faction_legacy",
                    homeCommunityId = "community_legacy",
                    groupType = "CARAVAN",
                    memberIds = { "actor_legacy" },
                    leaderId = "actor_legacy",
                    location = {
                        id = "aloc_legacy",
                        type = "SETTLEMENT",
                        x = 100, y = 200, z = 0,
                    },
                },
            },
            population = {
                worldSeed = 5150,
                sectors = {},
            },
        },
        EnsureLoaded = function() return true end,
    },
    WorldDiscovery = {
        Registry = {
            revision = 1,
            players = {
                player_legacy = {
                    revision = 1,
                    entities = {
                        settlement = {
                            community_legacy = {
                                phase = 3,
                                source = "visit",
                                x = 100, y = 200, z = 0,
                            },
                        },
                        mobile_group = {},
                    },
                },
            },
        },
        EnsureLoaded = function() return true end,
    },
}

local before = deepCopy({
    factions = PNC.Factions.Registry,
    communities = PNC.Communities.Registry,
    abstractWorld = PNC.AbstractWorldStore.Registry,
    discovery = PNC.WorldDiscovery.Registry,
})

local Authority = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_CoreSurvivorWorldAuthority.lua"
)

T.truthy(Authority.Registry,
    "Hoomans must activate Core SurvivorWorld runtime")
T.equal(next(roots), nil,
    "activation must not allocate ModData before init")

local preview, source = Authority.PreviewLegacyImport()
T.truthy(preview and source, "legacy preview must succeed")
T.equal(preview.worldSeed, 5150, "legacy world seed")
T.truthy(preview.factions.faction_legacy, "faction preview")
T.truthy(preview.communities.community_legacy, "community preview")
T.truthy(preview.groups.agroup_legacy, "group preview")
T.truthy(
    preview.discovery.players.player_legacy,
    "discovery preview"
)

local status = Authority.RefreshStatus()
T.truthy(status.coreEmpty, "Core begins empty")
T.truthy(status.needsMigration,
    "legacy-only world must report pending migration")

for _, callback in ipairs(initCallbacks) do callback() end
status = Authority.RefreshStatus()
T.truthy(status.needsMigration,
    "init must not auto-import or dual-write legacy state")

local registry, reason = Authority.ImportLegacy({
    reason = "test_cutover",
})
T.truthy(registry, reason)
T.truthy(registry:GetFaction("faction_legacy"),
    "imported faction missing")
T.truthy(registry:GetCommunity("community_legacy"),
    "imported community missing")
T.truthy(registry:GetGroup("agroup_legacy"),
    "imported group missing")

local root = roots["PsychopatzCore.SurvivorWorld"]
T.truthy(root and type(root.registry) == "string",
    "migration must persist only the Core world root")

T.equal(
    PNC.Core.DeepCopy(PNC.Factions.Registry).byID.faction_legacy.name,
    before.factions.byID.faction_legacy.name,
    "legacy faction store must remain read-only during import"
)
T.equal(
    PNC.AbstractWorldStore.Registry.revision,
    before.abstractWorld.revision,
    "legacy abstract store must remain read-only during import"
)

local duplicate, duplicateReason = Authority.ImportLegacy()
T.falsy(duplicate,
    "non-empty Core world must reject accidental re-import")
T.equal(
    duplicateReason,
    "core_survivor_world_not_empty",
    "re-import rejection reason"
)

status = Authority.RefreshStatus()
T.falsy(status.coreEmpty, "Core should now be authoritative candidate")
T.falsy(status.needsMigration,
    "completed import should clear migration need")

T.finish("pnc_core_survivor_world_authority_smoke")
