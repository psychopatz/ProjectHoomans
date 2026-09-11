local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "Layers/PNC_MapLayer_WorldDiscovery.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end

local visibilityFilter
local registered
PNC = {
    WorldDiscoveryTypes = {
        KIND_SETTLEMENT = "settlement",
        KIND_MOBILE_GROUP = "mobile_group",
        PHASE_RUMORED = 1,
        PHASE_LOCATED = 2,
        PHASE_CONTACTED = 3,
    },
    Network = { ClientState = { worldDiscovery = { entities = {} } } },
    MapLayers = { Register = function(id, definition)
        registered = { id = id, definition = definition }
        return true
    end },
    TravelDirectory = {
        RegisterVisibilityFilter = function(id, callback)
            T.truthy(id == "pnc_world_discovery")
            visibilityFilter = callback
            return true
        end,
    },
}

T.load(FILE)
T.truthy(visibilityFilter, "world discovery did not protect NPC travel markers")

local generated = {
    generation = { source = "WORLD_POPULATION_DIRECTOR" },
    affiliation = { communityID = "home", factionID = "wanderers" },
}
T.truthy(visibilityFilter(generated) == false,
    "new population NPC leaked onto the map before discovery")

PNC.Network.ClientState.worldDiscovery.entities = {
    { kind = "settlement", entityID = "home", phase = 2 },
}
T.truthy(visibilityFilter(generated) == false,
    "located aggregate signal leaked individual NPC identities")

PNC.Network.ClientState.worldDiscovery.entities[1].phase = 3
T.truthy(visibilityFilter(generated) == true,
    "contacted settlement did not reveal its generated NPC markers")
T.truthy(visibilityFilter({ id = "hand-authored" }) == true,
    "discovery filter hid a non-population NPC")

PNC.Network.ClientState.worldDiscovery.entities = {}
PNC.WorldDiscoveryDebugMap = { ShowRawEntities = true }
T.truthy(visibilityFilter(generated) == true,
    "explicit raw debug overlay did not reveal generated NPC markers")

local map = {
    mapAPI = {
        worldToUIX = function(_, x) return x end,
        worldToUIY = function(_, _, y) return y end,
    },
}
PNC.Network.ClientState.worldDiscovery.entities = {
    { kind = "mobile_group", entityID = "mobile", x = 10, y = 10 },
    { kind = "settlement", entityID = "home", x = 11, y = 11 },
}
T.equal(PNC.WorldDiscoveryMapLayer.FindAt(map, 10, 10, 12).kind,
    "mobile_group", "mobile discovery has a map hit target")
PNC.Network.ClientState.worldDiscovery.entities = {
    { kind = "mobile_group", entityID = "mobile", x = 10, y = 10 },
}
PNC.MapDisplay = { AreBasesVisible = function() return true end }
T.equal(registered.definition.isVisible(), true,
    "earned discovery remains visible with the raw NPC map toggle on")
T.equal(PNC.WorldDiscoveryMapLayer.FindAt(map, 10, 10, 12).kind,
    "mobile_group", "mobile discovery renders a map marker")
PNC.Network.ClientState.worldDiscovery.entities = {
    { kind = "mobile_group", entityID = "searched", x = 10, y = 10,
        phase = 2, arrivalState = "searched" },
}
T.falsy(registered.definition.isVisible(),
    "searched signal does not keep the discovery layer open")
T.equal(PNC.WorldDiscoveryMapLayer.FindAt(map, 10, 10, 12), nil,
    "searched signal no longer has a map hit target")
T.finish("pnc_world_discovery_map_visibility_smoke")

T.finish("pnc_world_discovery_map_visibility_smoke")
