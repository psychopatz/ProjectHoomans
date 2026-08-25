local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local CLIENT = T.path("ProjectHoomans", "client", "PNC/")

local worldHour = 0.5
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end
getSpecificPlayer = function()
    return {
        getUsername = function() return "Alice" end,
    }
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        ORDER_FOLLOW = "follow",
        TRAVEL_SCHEMA_VERSION = 1,
        TRAVEL_ROUTE_MAX_POINTS = 128,
        TRAVEL_METADATA_MAX_DEPTH = 3,
        TRAVEL_METADATA_MAX_ENTRIES = 64,
        TRAVEL_SPEED_WALK_TILES_PER_HOUR = 100,
        TRAVEL_SPEED_RUN_TILES_PER_HOUR = 200,
        TRAVEL_SPEED_VEHICLE_TILES_PER_HOUR = 500,
        TRAVEL_ARRIVAL_RADIUS = 1,
        MAP_PRESENTATION_MAX_KNOWN_PLAYERS = 64,
        MAP_PRESENTATION_ROLE_MAX_LENGTH = 32,
        MAP_PRESENTATION_ICON_MAX_LENGTH = 64,
    },
    Core = {
        IsClientOnly = function() return true end,
        GenerateID = function() return "journey:directory" end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Network = {
        ClientState = {
            snapshots = {},
            npcKnowledge = {
                ["idle:1"] = {
                    categories = {
                        {
                            descriptors = {
                                {
                                    descriptorID = "identity.name",
                                    status = "known",
                                    value = "Idle NPC",
                                },
                            },
                        },
                    },
                },
            },
        },
    },
    MapCommands = {
        IsSelected = function(id) return id == "selected:hidden" end,
    },
}

T.load(SHARED .. "Map/PNC_MapPresentation.lua")
T.load(SHARED .. "Travel/PNC_Travel_Route.lua")
T.load(SHARED .. "Travel/PNC_Travel_Providers.lua")
T.load(SHARED .. "Travel/PNC_Travel_Model.lua")
T.load(SHARED .. "Travel/PNC_Travel_Projection.lua")
T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(CLIENT .. "Travel/PNC_TravelDirectory.lua")

local record = {
    id = "directory:1",
    x = 0,
    y = 0,
    z = 0,
    presenceState = "abstract",
}
local journey = PNC.Travel.Model.New(record, {
    journeyId = "journey:directory",
    destination = { x = 100, y = 0, z = 0 },
    speedTilesPerWorldHour = 100,
}, 0)
local summary = PNC.Travel.Model.BuildSummary(journey, true)
T.truthy(summary.route.segments == nil,
    "network summary leaked derived route segments")

PNC.Network.ClientState.snapshots[record.id] = {
    id = record.id,
    name = "Directory Walker",
    faction = "colonist",
    presenceState = "abstract",
    x = 0,
    y = 0,
    z = 0,
    travel = summary,
}

local projected = T.truthy(PNC.TravelDirectory.GetProjected(record.id))
T.truthy(math.abs(projected.x - 50) < 0.001,
    "client directory did not extrapolate abstract movement")
T.truthy(math.abs(projected.percent - 0.5) < 0.001,
    "client directory progress is incorrect")
T.truthy(type(summary.route.segments) == "table",
    "client route geometry was not compiled into the cache")
local cachedRoute = summary.route
PNC.TravelDirectory.GetProjected(record.id)
T.truthy(summary.route == cachedRoute,
    "client route geometry was rebuilt on a subsequent frame")

summary.state = "cancelled"
T.truthy(PNC.TravelDirectory.GetProjected(record.id) ~= nil,
    "cancelled journey hid the NPC's current location")
summary.state = "en_route"
summary.visibility = "hidden"
T.truthy(PNC.TravelDirectory.GetProjected(record.id) == nil,
    "hidden journey remained visible")
summary.visibility = "all"

PNC.Network.ClientState.snapshots["idle:1"] = {
    id = "idle:1",
    name = "Idle NPC",
    faction = "neutral",
    presenceState = "abstract",
    x = 25,
    y = 35,
    z = 0,
    portrait = {
        identitySeed = 3,
        faceOnly = true,
        appearance = { hairModel = "Short" },
        equipment = { worn = {} },
    },
    organizationalFaction = {
        id = "faction_idle",
        name = "Idle Survivors",
        archetypeID = "settler",
        emblem = {
            schemaVersion = 1,
            backgroundColorID = "green",
            layers = {
                {
                    symbolID = "House",
                    colorID = "white",
                    scale = 0.76,
                    offsetX = 0,
                    offsetY = 0,
                },
            },
            revision = 2,
        },
    },
}
local idle = T.truthy(PNC.TravelDirectory.GetProjected("idle:1"))
T.truthy(idle.name == "Idle NPC" and idle.x == 25 and idle.state == "idle",
    "non-travelling NPC was missing from the map directory")
T.truthy(idle.portrait and idle.portrait.appearance.hairModel == "Short",
    "map projection dropped compact portrait metadata")
T.truthy(idle.organizationalFaction
    and idle.organizationalFaction.emblem
    and idle.organizationalFaction.emblem.revision == 2,
    "map projection dropped layered faction emblem")

PNC.Network.ClientState.snapshots["dead:neutral"] = {
    id = "dead:neutral",
    name = "Dead NPC",
    faction = "dead",
    presenceState = "corpse",
    alive = false,
    deathMarker = true,
    colonist = false,
    x = 45,
    y = 55,
    z = 0,
}
local deadNeutral = PNC.TravelDirectory.GetProjected("dead:neutral")
T.equal(deadNeutral, nil,
    "unowned compact death marker leaked onto the map")

PNC.Network.ClientState.snapshots["dead:colonist"] = {
    id = "dead:colonist",
    name = "Dead Colonist",
    faction = "dead",
    presenceState = "corpse",
    alive = false,
    deathMarker = true,
    colonist = true,
    x = 65,
    y = 75,
    z = 0,
}
local deadColonist =
    T.truthy(PNC.TravelDirectory.GetProjected("dead:colonist"))
T.truthy(deadColonist.deathMarker == true and deadColonist.colonist == true,
    "compact dead colonist marker lost its classification")

PNC.Network.ClientState.snapshots["dead:legacy"] = {
    id = "dead:legacy",
    name = "Legacy Dead Record",
    presenceState = "corpse",
    alive = false,
    x = 85,
    y = 95,
    z = 0,
}
T.truthy(PNC.TravelDirectory.GetProjected("dead:legacy") == nil,
    "non-marker dead record leaked onto the map")

PNC.Network.ClientState.snapshots["known:alice"] = {
    id = "known:alice",
    name = "Known NPC",
    faction = "neutral",
    presenceState = "abstract",
    x = 1,
    y = 1,
    z = 0,
    mapPresentation = {
        visibility = "known",
        knownBy = { Alice = true },
        roleTag = "trader",
        iconID = "trader",
    },
}
local known = T.truthy(PNC.TravelDirectory.GetProjected("known:alice"))
T.truthy(known.roleTag == "trader" and known.iconID == "trader",
    "map presentation metadata was not exposed by the directory")

PNC.Network.ClientState.snapshots["known:bob"] = {
    id = "known:bob",
    name = "Unknown NPC",
    faction = "neutral",
    presenceState = "abstract",
    x = 2,
    y = 2,
    z = 0,
    mapPresentation = {
        visibility = "known",
        knownBy = { Bob = true },
    },
}
T.truthy(PNC.TravelDirectory.GetProjected("known:bob") == nil,
    "another player's known NPC leaked onto this player's map")

PNC.Network.ClientState.snapshots["selected:hidden"] = {
    id = "selected:hidden",
    name = "Selected Hidden NPC",
    faction = "neutral",
    presenceState = "abstract",
    x = 3,
    y = 3,
    z = 0,
    mapPresentation = { visibility = "hidden" },
}
T.truthy(PNC.TravelDirectory.GetProjected("selected:hidden") ~= nil,
    "local selection did not override marker visibility")
T.finish("pnc_travel_directory_smoke")

T.finish("pnc_travel_directory_smoke")
