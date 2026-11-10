local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end

local roots = {}
ModData = {
    get = function(key) return roots[key] end,
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

PNC = {}
require "PNC/Core/Base/PNC_Core"
require "PNC/Core/Persistence/PNC_ModDataStore"
require "PNC/Core/Factions/PNC_FactionConstants"
require "PNC/Core/Factions/PNC_FactionArchetypes"
require "PNC/Core/Factions/PNC_FactionEmblems"
require "PNC/Core/Factions/PNC_FactionDiplomacyMath"
require "PNC/Core/Factions/PNC_FactionIncidentDefinitions"
require "PNC/Core/Factions/PNC_FactionTypes"
require "PNC/Core/Communities/PNC_CommunityConstants"
require "PNC/Core/Communities/PNC_CommunityMath"
require "PNC/Core/Communities/PNC_CommunityProfiles"
require "PNC/Core/Communities/PNC_CommunityTypes"
require "PNC/Core/Director/PNC_DirectorConfig"
require "PNC/Core/Director/PNC_AbstractWorldTypes"

local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
World.RuntimeStore.ResetForTests()
local core = assert(World.ActivateRuntime({ worldSeed = 5150 }))

assert(core:UpsertFaction({
    id = "faction_ext",
    name = "Core Traders",
    archetypeID = "settler",
    status = "inactive",
    leaderActorID = "npc_ext_leader",
    memberActorIDs = { "npc_ext_leader", "npc_ext_guard" },
    relations = {
        faction_rival = {
            standing = -20,
            trust = -10,
            fear = 15,
            grievance = 30,
            state = "wary",
        },
    },
}))
assert(core:UpsertFaction({
    id = "faction_rival",
    name = "Rivals",
    archetypeID = "looter",
}))
assert(core:UpsertCommunity({
    id = "community_ext",
    factionID = "faction_ext",
    name = "Core Camp",
    mode = "settled",
    status = "active",
    home = { x = 100, y = 200, z = 0, radius = 25 },
    siteID = "community_site_ext",
    leaderActorID = "npc_ext_leader",
    memberActorIDs = { "npc_ext_leader", "npc_ext_guard" },
    security = 55,
    morale = -12,
    resources = {
        food = 30,
        medical = 7,
        ammo = 11,
        materials = 19,
    },
}))
assert(core:UpsertLocation({
    id = "aloc_ext",
    kind = "SETTLEMENT",
    x = 100, y = 200, z = 0,
    tags = { settlement = true },
    resources = { food = 9, ammo = 3 },
    danger = 8,
    scavengedLevel = 4,
}))
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
local journey = assert(GroupJourney.New(
    "agroup_ext",
    {
        origin = { x = 100, y = 200, z = 0 },
        destination = { x = 500, y = 200, z = 0 },
        speed = 40,
        startAt = 10,
    },
    10
))
assert(core:UpsertGroup({
    id = "agroup_ext",
    factionID = "faction_ext",
    homeCommunityID = "community_ext",
    groupType = "TRADER",
    memberActorIDs = { "npc_ext_leader", "npc_ext_guard" },
    leaderActorID = "npc_ext_leader",
    mission = "TRADE",
    state = "TRAVELING",
    location = {
        id = "aloc_ext", kind = "SETTLEMENT",
        x = 100, y = 200, z = 0,
    },
    targetLocation = {
        id = "aloc_target", kind = "TEMPORARY",
        x = 500, y = 200, z = 0,
    },
    journey = journey,
    resources = { food = 5, ammo = 2 },
    morale = 0.75,
}))
assert(World.RuntimeStore.MarkDirty("extension_fixture"))

PNC.Factions = {
    Registry = PNC.FactionTypes.NormalizeFactionRegistry({
        schemaVersion = PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
        revision = 9,
        byID = {
            faction_ext = {
                id = "faction_ext",
                name = "Legacy Traders",
                archetypeID = "settler",
                status = "inactive",
                leaderNPCID = "npc_ext_leader",
                memberIDs = {
                    npc_ext_leader = true,
                    npc_ext_guard = true,
                },
                policy = {
                    aggression = 0.2,
                    outsiderPolicy = "commercial",
                },
                emblem = {
                    symbol = "trade",
                },
                relations = {
                    faction_rival = {
                        standing = -20,
                        trust = -10,
                        fear = 15,
                        grievance = 30,
                        state = "wary",
                        warReason = "scripted",
                        lastEvaluatedAt = 77,
                    },
                },
            },
            faction_rival = {
                id = "faction_rival",
                name = "Legacy Rivals",
                archetypeID = "looter",
            },
        },
    }),
    Loaded = true,
    Dirty = true,
    Internal = {},
}

PNC.Communities = {
    Registry = PNC.CommunityTypes.NormalizeRegistry({
        schemaVersion = PNC.CommunityConstants.REGISTRY_SCHEMA_VERSION,
        revision = 8,
        byID = {
            community_ext = {
                id = "community_ext",
                factionID = "faction_ext",
                name = "Legacy Camp",
                mode = "settled",
                status = "active",
                home = { x = 100, y = 200, z = 0, radius = 25 },
                siteID = "community_site_ext",
                leaderNPCID = "npc_ext_leader",
                memberIDs = {
                    npc_ext_leader = true,
                    npc_ext_guard = true,
                },
                capacity = {
                    population = 40,
                    beds = 30,
                    storage = 900,
                },
                security = 55,
                morale = -12,
                supplies = {
                    food = 30,
                    medicine = 7,
                    ammunition = 11,
                    tools = 6,
                    materials = 19,
                },
            },
        },
        sitesByID = {
            community_site_ext = {
                id = "community_site_ext",
                kind = "radius",
                home = {
                    x = 100, y = 200, z = 0, radius = 25,
                },
                bounds = {
                    minX = 80, minY = 180,
                    maxX = 120, maxY = 220,
                    minZ = 0, maxZ = 0,
                },
                occupantCommunityID = "community_ext",
                createdAt = 10,
                revision = 2,
            },
        },
    }),
    Loaded = true,
    Dirty = true,
    Internal = {},
}

PNC.HoomansWorldView = {
    Registry = PNC.AbstractWorldTypes.NormalizeRegistry({
        revision = 12,
        locationsByID = {
            aloc_ext = {
                id = "aloc_ext",
                type = "SETTLEMENT",
                x = 100, y = 200, z = 0,
                tags = { settlement = true },
                resourcePotential = {
                    food = 9, ammo = 3,
                },
                danger = 8,
                scavengedLevel = 4,
                occupants = {
                    groups = {
                        agroup_ext = {
                            arrivedAt = 5,
                            plannedDepartureAt = 30,
                        },
                    },
                },
                visitHistory = {
                    { groupId = "agroup_ext", arrivedAt = 5 },
                },
                sourceSite = {
                    id = "community_site_ext",
                    kind = "radius",
                },
            },
        },
        groupsByID = {
            agroup_ext = {
                id = "agroup_ext",
                factionId = "faction_ext",
                homeCommunityId = "community_ext",
                groupType = "TRADER",
                memberIds = {
                    "npc_ext_leader",
                    "npc_ext_guard",
                },
                leaderId = "npc_ext_leader",
                mission = "TRADE",
                state = "TRAVELING",
                location = {
                    id = "aloc_ext",
                    type = "SETTLEMENT",
                    x = 100, y = 200, z = 0,
                },
                targetLocation = {
                    id = "aloc_target",
                    type = "TEMPORARY",
                    x = 500, y = 200, z = 0,
                },
                journey = journey,
                resources = { food = 5, ammo = 2 },
                morale = 0.75,
                behaviorProfile = {
                    aggression = 0.25,
                },
                combatProfile = {
                    overallPower = 44,
                },
                diagnostics = {
                    lastReason = "fixture",
                },
            },
        },
        encounters = {
            {
                id = "encounter_ext",
                outcome = "RESOLVED",
            },
        },
        encounterCooldowns = {
            ["agroup_ext:faction_rival"] = 88,
        },
        nextEncounterSerial = 4,
        uniqueNPCsByID = {
            unique_fixture = {
                status = "alive",
                runtimeNpcId = "npc_ext_guard",
                definitionVersion = 1,
            },
        },
        population = {
            worldSeed = 5150,
            sectors = {},
        },
    }),
    Loaded = true,
    Dirty = true,
}
local rebuiltLocationIndex = 0
PNC.AbstractLocations = {
    RebuildIndex = function()
        rebuiltLocationIndex = rebuiltLocationIndex + 1
    end,
}

roots["PNC_Factions"] = {
    schemaVersion = PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
    importFixture = true,
}
roots["PNC_Communities"] = {
    schemaVersion = PNC.CommunityConstants.REGISTRY_SCHEMA_VERSION,
    importFixture = true,
}
roots["PNC_AbstractWorld_v1"] = {
    schemaVersion = PNC.DirectorConfig.SCHEMA_VERSION,
    importFixture = true,
}

PNC.CoreSurvivorWorldAuthority = {
    Registry = core,
    World = World,
    RefreshStatus = function()
        return {
            active = true,
            needsImport = false,
        }
    end,
}

local Extensions = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_SurvivorWorldExtensions.lua"
)
local activated, activationReason =
    Extensions.ActivateCutover()
T.truthy(activated, activationReason)
T.truthy(Extensions.Active, "extensions active")
T.equal(rebuiltLocationIndex, 1,
    "location index rebuilt from Core world")

local stored = roots[Extensions.STORAGE_KEY]
T.truthy(stored, "extension root persisted")
local factionExt = stored.factions.faction_ext
T.truthy(factionExt, "faction extension persisted")
T.equal(factionExt.name, nil,
    "generic faction name is not duplicated")
T.equal(factionExt.memberIDs, nil,
    "generic faction members are not duplicated")
T.equal(factionExt.status, nil,
    "generic faction status is not duplicated")
T.equal(
    factionExt.relationDetails.faction_rival.standing,
    nil,
    "generic relation standing is not duplicated"
)
T.equal(
    factionExt.relationDetails.faction_rival.warReason,
    "scripted",
    "Hoomans relation detail is preserved"
)

local communityExt =
    stored.communities.community_ext
T.truthy(communityExt, "community extension persisted")
T.equal(communityExt.name, nil,
    "generic community name is not duplicated")
T.equal(communityExt.memberIDs, nil,
    "generic community members are not duplicated")
T.equal(communityExt.supplies, nil,
    "generic community resources are not duplicated")
T.equal(communityExt.capacity.population, 40,
    "Hoomans capacity remains extension state")
T.equal(communityExt.suppliesExtra.tools, 6,
    "Hoomans-only tools supply remains extension state")
T.truthy(stored.sitesByID.community_site_ext,
    "Hoomans site metadata remains extension state")

local groupExt = stored.groups.agroup_ext
T.truthy(groupExt, "group extension persisted")
T.equal(groupExt.state, nil,
    "generic group state is not duplicated")
T.equal(groupExt.journey, nil,
    "Core group journey is not duplicated")
T.equal(groupExt.resources, nil,
    "generic group resources are not duplicated")
T.truthy(groupExt.combatProfile,
    "Hoomans combat profile remains extension state")
T.truthy(groupExt.behaviorProfile,
    "Hoomans behavior profile remains extension state")

local locationExt = stored.locations.aloc_ext
T.truthy(locationExt, "location extension persisted")
T.equal(locationExt.x, nil,
    "generic location position is not duplicated")
T.equal(locationExt.resourcePotential, nil,
    "generic location resources are not duplicated")
T.truthy(locationExt.sourceSite,
    "Hoomans source-site metadata remains extension state")
T.truthy(locationExt.occupants,
    "Hoomans occupancy remains extension state")

T.equal(
    next(roots[
        "PNC_Factions"
    ]),
    nil,
    "faction import source retired"
)
T.equal(
    next(roots[
        "PNC_Communities"
    ]),
    nil,
    "community import source retired"
)
T.equal(
    next(roots["PNC_AbstractWorld_v1"]),
    nil,
    "abstract-world import source retired"
)

T.equal(PNC.Factions.Registry.byID.faction_ext.name,
    "Core Traders",
    "PNC faction view rebuilt from Core generic state")
T.equal(PNC.Factions.Registry.byID.faction_ext.status,
    "inactive",
    "inactive status survives Core cutover")
T.equal(
    PNC.Factions.Registry.byID.faction_ext
        .relations.faction_rival.warReason,
    "scripted",
    "relation extension merged into Core relation view"
)

local rebuiltCommunity =
    PNC.Communities.Registry.byID.community_ext
T.equal(rebuiltCommunity.name, "Core Camp",
    "PNC community view rebuilt from Core generic state")
T.equal(rebuiltCommunity.capacity.population, 40,
    "community capacity restored from extension")
T.equal(rebuiltCommunity.supplies.food, 30,
    "generic food restored from Core")
T.equal(rebuiltCommunity.supplies.medicine, 7,
    "generic medical resource restored from Core")
T.equal(rebuiltCommunity.supplies.ammunition, 11,
    "generic ammo resource restored from Core")
T.equal(rebuiltCommunity.supplies.tools, 6,
    "tools restored from Hoomans extension")
T.equal(rebuiltCommunity.morale, -12,
    "community morale scale preserved")

local rebuiltGroup =
    PNC.HoomansWorldView.Registry.groupsByID.agroup_ext
T.truthy(rebuiltGroup.journey,
    "Core group journey restored to PNC view")
T.truthy(rebuiltGroup.combatProfile,
    "group combat extension restored")
T.truthy(rebuiltGroup.behaviorProfile,
    "group behavior extension restored")

local rebuiltLocation =
    PNC.HoomansWorldView.Registry.locationsByID.aloc_ext
T.equal(rebuiltLocation.x, 100,
    "generic location position restored from Core")
T.truthy(rebuiltLocation.sourceSite,
    "location extension restored")

T.truthy(
    roots["PsychopatzCore.SurvivorWorld"]
        and roots["PsychopatzCore.SurvivorWorld"].registry,
    "canonical Core world persisted before import-source retirement"
)
T.falsy(PNC.Factions.Dirty, "faction view clean after cutover")
T.falsy(PNC.Communities.Dirty,
    "community view clean after cutover")
T.falsy(PNC.HoomansWorldView.Dirty,
    "abstract view clean after cutover")

-- Simulate the next server load: pre-SurvivorWorld import sources are empty, Core and the
-- bounded Hoomans extension root remain. The compatibility views must rebuild
-- entirely from those two authorities without recapturing stale PNC state.
PNC.Factions.Registry =
    PNC.FactionTypes.NormalizeFactionRegistry(nil)
PNC.Communities.Registry =
    PNC.CommunityTypes.NormalizeRegistry(nil)
PNC.HoomansWorldView.Registry =
    PNC.AbstractWorldTypes.NormalizeRegistry(nil)
Extensions.Active = false
Extensions.Dirty = false
Extensions.Registry = Extensions.NewRegistry()

local reactivated, reactivateReason =
    Extensions.ActivateCutover()
T.truthy(reactivated, reactivateReason)
T.equal(
    PNC.Factions.Registry.byID.faction_ext.name,
    "Core Traders",
    "reload rebuilds generic faction state from Core"
)
T.equal(
    PNC.Factions.Registry.byID.faction_ext
        .relations.faction_rival.warReason,
    "scripted",
    "reload restores faction extension state"
)
T.equal(
    PNC.Communities.Registry.byID.community_ext
        .capacity.population,
    40,
    "reload restores community extension state"
)
T.truthy(
    PNC.HoomansWorldView.Registry.groupsByID
        .agroup_ext.combatProfile,
    "reload restores group extension state"
)
T.equal(
    next(roots[
        "PNC_Factions"
    ]),
    nil,
    "reload does not resurrect retired faction root"
)

T.finish("pnc_survivor_world_extensions_cutover_smoke")
