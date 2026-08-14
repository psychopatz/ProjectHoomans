local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
    .. "Layers/PNC_MapLayer_WorldDiscovery.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end

local visibilityFilter
PNC = {
    WorldDiscoveryTypes = {
        KIND_SETTLEMENT = "settlement",
        KIND_MOBILE_GROUP = "mobile_group",
        PHASE_RUMORED = 1,
        PHASE_LOCATED = 2,
        PHASE_CONTACTED = 3,
    },
    Network = { ClientState = { worldDiscovery = { entities = {} } } },
    MapLayers = { Register = function() return true end },
    TravelDirectory = {
        RegisterVisibilityFilter = function(id, callback)
            assert(id == "pnc_world_discovery")
            visibilityFilter = callback
            return true
        end,
    },
}

dofile(FILE)
assert(visibilityFilter, "world discovery did not protect NPC travel markers")

local generated = {
    generation = { source = "WORLD_POPULATION_DIRECTOR" },
    affiliation = { communityID = "home", factionID = "wanderers" },
}
assert(visibilityFilter(generated) == false,
    "new population NPC leaked onto the map before discovery")

PNC.Network.ClientState.worldDiscovery.entities = {
    { kind = "settlement", entityID = "home", phase = 2 },
}
assert(visibilityFilter(generated) == false,
    "located aggregate signal leaked individual NPC identities")

PNC.Network.ClientState.worldDiscovery.entities[1].phase = 3
assert(visibilityFilter(generated) == true,
    "contacted settlement did not reveal its generated NPC markers")
assert(visibilityFilter({ id = "hand-authored" }) == true,
    "discovery filter hid a non-population NPC")

PNC.Network.ClientState.worldDiscovery.entities = {}
PNC.WorldDiscoveryDebugMap = { ShowRawEntities = true }
assert(visibilityFilter(generated) == true,
    "explicit raw debug overlay did not reveal generated NPC markers")

print("pnc_world_discovery_map_visibility_smoke: ok")
