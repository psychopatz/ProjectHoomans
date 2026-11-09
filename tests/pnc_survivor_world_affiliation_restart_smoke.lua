local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end

local roots = {}
local initCallbacks = {}
ModData = {
    get = function(key) return roots[key] end,
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
}
Events = {
    OnInitGlobalModData = {
        Add = function(callback)
            initCallbacks[#initCallbacks + 1] = callback
        end,
    },
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
local core = assert(World.ActivateRuntime({ worldSeed = 7070 }))
assert(core:UpsertFaction({
    id = "faction_player",
    name = "Player Faction",
    archetypeID = "settler",
    status = "active",
    memberActorIDs = { "npc_companion" },
}))
assert(core:UpsertCommunity({
    id = "community_player",
    factionID = "faction_player",
    name = "Player Camp",
    mode = "settled",
    status = "active",
    home = { x = 100, y = 100, z = 0, radius = 25 },
    memberActorIDs = { "npc_companion" },
}))

local record = {
    id = "npc_companion",
    alive = true,
    recruited = true,
    ownerUsername = "Player",
    ownerCharacterUUID = "char_player",
    affiliation = PNC.FactionTypes.NewAffiliation({
        factionID = "faction_player",
        communityID = "community_player",
        membershipStatus = "member",
        role = "member",
        rank = "member",
    }),
}
PNC.Registry = {
    Data = { npc_companion = record },
    Loaded = true,
    EnsureLoaded = function() end,
    Get = function(id) return PNC.Registry.Data[id] end,
    MarkDirty = function() end,
}
PNC.CoreSurvivorWorldAuthority = {
    Registry = core,
    World = World,
}
PNC.HoomansWorldView = {
    Registry = PNC.AbstractWorldTypes.NormalizeRegistry(nil),
    Loaded = false,
    Dirty = false,
}

-- This is the post-cutover save shape: Core and the Hoomans extension root
-- remain, while the retired compatibility roots are empty.
roots["PNC_SurvivorWorldExtensions_v1"] = {
    schemaVersion = 1,
    revision = 1,
    factions = {},
    communities = {},
    sitesByID = {},
    groups = {},
    locations = {},
    abstract = {
        encounters = {},
        encounterCooldowns = {},
        nextEncounterSerial = 1,
        uniqueNPCsByID = {},
    },
}
roots["PNC_Factions"] = {}
roots["PNC_Communities"] = {}

T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionCore.lua")
T.load("ProjectHoomans", "server", "PNC/Communities/PNC_CommunityService.lua")
local Extensions = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_SurvivorWorldExtensions.lua"
)

-- Composition registers the faction and community callbacks before the
-- SurvivorWorld cutover callback. This is the restart order that previously
-- erased valid NPC affiliation.
T.equal(#initCallbacks, 4, "all world-load callbacks registered")
for _, callback in ipairs(initCallbacks) do callback() end
T.truthy(
    Extensions.Active,
    "SurvivorWorld cutover activated"
)
T.truthy(PNC.Factions.Ready, "faction view finalized after cutover")
T.truthy(PNC.Communities.Ready, "community view finalized after cutover")
T.equal(record.affiliation.factionID, "faction_player",
    "restart preserves NPC faction affiliation")
T.equal(record.affiliation.communityID, "community_player",
    "restart preserves NPC community affiliation")
T.equal(record.recruited, true,
    "restart preserves recruited state")
T.equal(record.ownerUsername, "Player",
    "restart preserves companion owner")
T.equal(record.ownerCharacterUUID, "char_player",
    "restart preserves owner survivor identity")
T.truthy(
    PNC.Factions.Registry.byID.faction_player.memberIDs.npc_companion,
    "faction index is rebuilt from the preserved NPC affiliation"
)
T.truthy(
    PNC.Communities.Registry.byID.community_player.memberIDs.npc_companion,
    "community index is rebuilt from the preserved NPC affiliation"
)

T.finish("pnc_survivor_world_affiliation_restart_smoke")
