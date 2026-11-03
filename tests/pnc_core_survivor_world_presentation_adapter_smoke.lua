local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = {
    AllowsServerCode = function() return true end,
}

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"

local world = assert(World.NewRegistry({ worldSeed = 8181 }))
local actorRegistry = Actors.NewRegistry()

local faction = assert(world:UpsertFaction({
    id = "faction:adapter",
    name = "Adapter Faction",
    archetypeID = "neutral",
}))
local community = assert(world:UpsertCommunity({
    id = "community:adapter",
    factionID = faction.id,
    name = "Adapter Camp",
    status = "active",
    home = { x = 100, y = 200, z = 0 },
}))
local actor = assert(actorRegistry:Create({
    actorId = "actor:adapter",
    identitySeed = "adapter",
    world = { position = { x = 100, y = 200, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = {
            factionID = faction.id,
            groupID = "group:adapter",
            role = "leader",
        },
    },
}))
local group = assert(world:UpsertGroup({
    id = "group:adapter",
    factionID = faction.id,
    homeCommunityID = community.id,
    groupType = "CARAVAN",
    leaderActorID = actor.actorId,
    memberActorIDs = { actor.actorId },
    location = { x = 100, y = 200, z = 0 },
}))

local body = {
    getX = function() return 321 end,
    getY = function() return 654 end,
    getZ = function() return 1 end,
}

PNC = {
    Registry = {
        GetLiveZombie = function(id)
            if id == actor.actorId then return body end
        end,
    },
}

local Adapter = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_CoreSurvivorWorldPresentationAdapter.lua"
)
T.truthy(Adapter.Registered,
    Adapter.LastRegistrationReason or "position provider not registered")

local entry = assert(World.Presentation.BuildActorEntry(
    world,
    actorRegistry:Get(actor.actorId),
    group,
    5
))
T.equal(entry.position.x, 321,
    "Core projection ignored live Hoomans body X")
T.equal(entry.position.y, 654,
    "Core projection ignored live Hoomans body Y")
T.equal(entry.position.z, 1,
    "Core projection ignored live Hoomans body Z")
T.equal(entry.positionSource, Adapter.PROVIDER_ID,
    "Core projection did not report Hoomans position provider")

PNC.Registry.GetLiveZombie = function() return nil end
local abstractEntry = assert(World.Presentation.BuildActorEntry(
    world,
    actorRegistry:Get(actor.actorId),
    group,
    5
))
T.equal(abstractEntry.position.x, 100,
    "missing live body did not fall back to canonical group position")
T.equal(abstractEntry.positionSource, "group",
    "abstract fallback source changed")

T.finish("pnc_core_survivor_world_presentation_adapter_smoke")
