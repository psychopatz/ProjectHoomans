local SHARED = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local CLIENT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/"

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
        },
    },
    MapCommands = {
        IsSelected = function(id) return id == "selected:hidden" end,
    },
}

dofile(SHARED .. "Map/PNC_MapPresentation.lua")
dofile(SHARED .. "Travel/PNC_Travel_Route.lua")
dofile(SHARED .. "Travel/PNC_Travel_Providers.lua")
dofile(SHARED .. "Travel/PNC_Travel_Model.lua")
dofile(SHARED .. "Travel/PNC_Travel_Projection.lua")
dofile(CLIENT .. "Travel/PNC_TravelDirectory.lua")

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
assert(summary.route.segments == nil,
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

local projected = assert(PNC.TravelDirectory.GetProjected(record.id))
assert(math.abs(projected.x - 50) < 0.001,
    "client directory did not extrapolate abstract movement")
assert(math.abs(projected.percent - 0.5) < 0.001,
    "client directory progress is incorrect")
assert(type(summary.route.segments) == "table",
    "client route geometry was not compiled into the cache")
local cachedRoute = summary.route
PNC.TravelDirectory.GetProjected(record.id)
assert(summary.route == cachedRoute,
    "client route geometry was rebuilt on a subsequent frame")

summary.state = "cancelled"
assert(PNC.TravelDirectory.GetProjected(record.id) ~= nil,
    "cancelled journey hid the NPC's current location")
summary.state = "en_route"
summary.visibility = "hidden"
assert(PNC.TravelDirectory.GetProjected(record.id) == nil,
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
}
local idle = assert(PNC.TravelDirectory.GetProjected("idle:1"))
assert(idle.name == "Idle NPC" and idle.x == 25 and idle.state == "idle",
    "non-travelling NPC was missing from the map directory")

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
local known = assert(PNC.TravelDirectory.GetProjected("known:alice"))
assert(known.roleTag == "trader" and known.iconID == "trader",
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
assert(PNC.TravelDirectory.GetProjected("known:bob") == nil,
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
assert(PNC.TravelDirectory.GetProjected("selected:hidden") ~= nil,
    "local selection did not override marker visibility")

print("pnc_travel_directory_smoke: ok")
