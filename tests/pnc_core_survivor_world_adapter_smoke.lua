local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return false end

local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local registry = assert(World.NewRegistry({ worldSeed = 7007 }))

local dirtyReasons = {}
local migrationCalls = 0
local fakeWorld = {
    RuntimeStore = {
        MarkDirty = function(reason)
            dirtyReasons[#dirtyReasons + 1] = tostring(reason)
            return true
        end,
    },
}

PNC = PNC or {}
PNC.CoreSurvivorWorldAuthority = {
    Registry = registry,
    World = fakeWorld,
    Activate = function()
        return registry
    end,
    RefreshStatus = function()
        return {
            needsImport = migrationCalls == 0,
        }
    end,
    ImportPreSurvivorWorld = function()
        migrationCalls = migrationCalls + 1
        assert(registry:UpsertFaction({
            factionID = "faction_import",
            name = "Imported Faction",
            archetypeID = "survivor",
        }))
        return registry, "imported"
    end,
}

local Adapter = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_CoreSurvivorWorldAdapter.lua"
)

local faction = assert(Adapter.CommitFaction({
    id = "faction_new",
    name = "New Faction",
    archetypeID = "trader",
    status = "active",
    leaderNPCID = "actor_leader",
    memberIDs = {
        actor_leader = true,
        actor_guard = true,
    },
}, "test_faction"))

T.equal(migrationCalls, 1,
    "first canonical mutation must import pre-SurvivorWorld data once")
T.truthy(registry:GetFaction("faction_import"),
    "imported faction must survive cutover")
T.equal(faction.leaderActorID, "actor_leader",
    "PNC leader alias must normalize into Core")
T.equal(#faction.memberActorIDs, 2,
    "PNC member set must normalize into Core")

local memberAdded = assert(Adapter.AddFactionMember(
    "faction_new", "actor_extra", "test_member_add"))
T.equal(#memberAdded.memberActorIDs, 3,
    "adapter delegates member add to Core")
local leaderChanged = assert(Adapter.SetFactionLeader(
    "faction_new", "actor_extra", "test_leader"))
T.equal(leaderChanged.leaderActorID, "actor_extra",
    "adapter delegates leader change to Core")
local memberRemoved = assert(Adapter.RemoveFactionMember(
    "faction_new", "actor_extra", "test_member_remove"))
T.equal(#memberRemoved.memberActorIDs, 2,
    "adapter delegates member removal to Core")
T.equal(memberRemoved.leaderActorID, nil,
    "Core clears the removed leader through the adapter")

local community = assert(Adapter.CommitCommunity({
    id = "community_new",
    factionID = "faction_new",
    name = "New Camp",
    mode = "settled",
    status = "active",
    home = { x = 100, y = 200, z = 0, radius = 20 },
    memberIDs = {
        actor_leader = true,
        actor_guard = true,
    },
    capacity = { population = 50 },
    supplies = { food = 12, water = 8 },
}, "test_community"))
T.equal(community.population, 2,
    "Core population must be member count, not Hoomans capacity")
T.equal(community.resources.food, 12,
    "generic resource summary must normalize from supplies")

local location = assert(Adapter.CommitLocation({
    id = "aloc_new",
    type = "SETTLEMENT",
    x = 100, y = 200, z = 0,
    resourcePotential = { food = 5 },
    danger = 3,
}, "test_location"))
T.equal(location.kind, "SETTLEMENT",
    "PNC location type must normalize into Core kind")

local group = assert(Adapter.CommitGroup({
    id = "agroup_new",
    factionId = "faction_new",
    homeCommunityId = "community_new",
    groupType = "TRADER",
    memberIds = { "actor_leader", "actor_guard" },
    leaderId = "actor_leader",
    mission = "TRADE",
    state = "IDLE",
    location = {
        id = "aloc_new",
        type = "SETTLEMENT",
        x = 100, y = 200, z = 0,
    },
}, "test_group"))
T.equal(group.factionID, "faction_new", "group faction alias")
T.equal(group.homeCommunityID, "community_new",
    "group community alias")
T.equal(#group.memberActorIDs, 2, "group members")

T.truthy(#dirtyReasons >= 4,
    "every canonical mutation must dirty Core persistence")
T.equal(migrationCalls, 1,
    "later mutations must not repeat import")

T.truthy(Adapter.RemoveGroup("agroup_new", "test_remove"))
T.equal(registry:GetGroup("agroup_new"), nil,
    "group removal must remove Core canonical record")

T.equal(Adapter.GetFaction("faction_new").name, "New Faction",
    "adapter faction query")
T.equal(Adapter.GetCommunity("community_new").name, "New Camp",
    "adapter community query")
T.equal(Adapter.GetLocation("aloc_new").id, "aloc_new",
    "adapter location query")

PNC.Factions = {
    List = function()
        return {
            {
                id = "faction_repaired",
                name = "Repaired Faction",
                archetypeID = "trader",
                memberIDs = { actor_leader = true },
            },
        }
    end,
}
PNC.AbstractLocations = {
    List = function()
        return {
            {
                id = "aloc_repaired",
                type = "SETTLEMENT",
                x = 300, y = 400, z = 0,
            },
        }
    end,
}
PNC.Communities = {
    List = function()
        return {
            {
                id = "community_repaired",
                factionID = "faction_repaired",
                name = "Repaired Camp",
                home = { x = 300, y = 400, z = 0, radius = 12 },
                memberIDs = { actor_leader = true },
            },
        }
    end,
}
PNC.AbstractGroups = {
    List = function()
        return {
            {
                id = "agroup_repaired",
                factionId = "faction_repaired",
                homeCommunityId = "community_repaired",
                groupType = "TRADER",
                memberIds = { "actor_leader" },
                location = {
                    id = "aloc_repaired",
                    type = "SETTLEMENT",
                    x = 300, y = 400, z = 0,
                },
            },
        }
    end,
}

local repair, repairReason = Adapter.ReconcileExistingWorld()
T.truthy(repair, repairReason)
T.equal(repair.added, 4,
    "repair imports missing provider world records")
T.equal(repair.factions, 1, "repair imports the missing faction")
T.equal(repair.locations, 1, "repair imports the missing location")
T.equal(repair.communities, 1, "repair imports the missing community")
T.equal(repair.groups, 1, "repair imports the missing group")
T.truthy(registry:GetGroup("agroup_repaired"),
    "repaired group is available in Core")

local repeatRepair, repeatReason = Adapter.ReconcileExistingWorld()
T.truthy(repeatRepair, repeatReason)
T.equal(repeatRepair.added, 0,
    "world repair is idempotent for already-canonical records")

T.finish("pnc_core_survivor_world_adapter_smoke")
