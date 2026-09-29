local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "Layers/PNC_MapLayer_AbstractGroups.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end
ISWorldMap = {}
UIFont = { Small = "small" }

local registered, requests = nil, 0
local receivedAt = 2000
-- Marker coordinates the layer asked the map to project.
local positions = {}
PNC = {
    WorldDiscoveryDebugMap = { ShowRawEntities = false },
    Core = { Now = function() return receivedAt end },
    MapDisplay = {
        AreBasesVisible = function() return true end,
        AreNamesVisible = function() return true end,
    },
    MapLayers = { Register = function(id, definition)
        registered = { id = id, definition = definition }
        return true
    end },
    Client = {
        CanUseDebug = function() return true end,
        RequestDirectorDebug = function()
            requests = requests + 1
            return true
        end,
    },
    Network = { ClientState = {
        directorDebugAuthorized = true,
        lastDirectorDebugReceiveAt = receivedAt,
        directorDebug = { groups = { {
            id = "agroup_population_map", groupType = "LOOTER",
            memberIds = { "npc_1", "npc_2", "npc_3" },
            factionId = "faction_population_map", mission = "SCAVENGE",
            state = "IDLE", location = { x = 100, y = 120, z = 0 },
        } } },
    } },
}

local worldHour = 100
getGameTime = function()
    return { getWorldAgeHours = function() return worldHour end }
end

T.load(FILE)
T.truthy(registered and registered.id == "pnc_abstract_groups",
    "abstract group layer was not registered")
T.truthy(registered.definition.order > 90,
    "group markers should render above community geometry")
T.truthy(registered.definition.isVisible() == false,
    "raw group overlay must be hidden by default")
PNC.WorldDiscoveryDebugMap.ShowRawEntities = true

local rectangles, labels, hover = {}, {}, {}
local map = {
    width = 600, height = 500,
    mapAPI = {
        worldToUIX = function(_, x) positions[#positions + 1] = x return x end,
        worldToUIY = function(_, _, y) return y end,
    },
    getMouseX = function() return 100 end,
    getMouseY = function() return 120 end,
    drawRect = function(_, ...) rectangles[#rectangles + 1] = { ... } end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, value) labels[#labels + 1] = value end,
    drawText = function(_, value) hover[#hover + 1] = value end,
}
registered.definition.render(map)
T.truthy(requests == 1, "map layer did not refresh Director data")
T.truthy(#rectangles >= 2, "group marker and hover card were not rendered")
T.truthy(labels[1] == "LOOTER", "group archetype label was not rendered")
T.truthy(hover[2] == "Members: 3", "group hover population was not rendered")
T.truthy(rectangles[1][6] == 1 and rectangles[1][7] == 0.22,
    "looter group did not use hostile map color")

local layer = PNC.AbstractGroupMapLayer
local ClientState = PNC.Network.ClientState

-- A non-traveling group keeps its confirmed position exactly.
T.truthy(layer.TrackCount == 0,
    "idle group must not allocate an interpolation track")
T.near(layer.MarkerPosition(ClientState.directorDebug.groups[1]), 100, 1e-9,
    "idle group marker must stay at the confirmed location")

-- Interpolation ------------------------------------------------------------

local GROUP = {
    id = "agroup_mobile_map", groupType = "WANDERER",
    factionId = "faction_mobile_map", mission = "SCAVENGE",
    state = "TRAVELING",
    stateStartedAt = 100, stateEndsAt = 110,
    groupStateStartedAt = 100, groupStateEndsAt = 110,
    location = { x = 0, y = 0, z = 0 },
    targetLocation = { x = 200, y = 400, z = 0 },
    mobile = { active = true, presence = "abstract",
        debugState = "en_route" },
}

local function publish(group, at, received)
    worldHour = at
    receivedAt = received or receivedAt + 1
    ClientState.directorDebug.groups[1] = group
    ClientState.lastDirectorDebugReceiveAt = receivedAt
end

-- Give the snapshot a fresh receive stamp so the layer rebuilds tracks.
worldHour = 100
receivedAt = receivedAt + 1
ClientState.directorDebug.groups[1] = GROUP
ClientState.lastDirectorDebugReceiveAt = receivedAt
positions = {}
registered.definition.render(map)

T.truthy(layer.TrackCount == 1, "traveling group should hold one track")
T.near(layer.MarkerPosition(GROUP), 0, 1e-9,
    "marker must start at the origin")

-- Mid-leg: a fresh snapshot arriving at hour 105 lets the marker glide
-- strictly between origin and target.
publish(GROUP, 105)
registered.definition.render(map)
T.truthy(layer.TrackCount == 1, "track must survive a mid-leg snapshot")
local midX = layer.MarkerPosition(GROUP)
T.truthy(midX > 0 and midX < 200,
    "mid-leg marker must be interpolated, got " .. tostring(midX))
T.near(midX, 100, 1e-9, "mid-leg eased midpoint")
T.near(select(2, layer.MarkerPosition(GROUP)), 200, 1e-9,
    "mid-leg y must be interpolated")

-- The render pass must project the interpolated coordinate, not the raw one.
positions = {}
registered.definition.render(map)
T.truthy(#positions > 0, "render did not project any group")
T.truthy(positions[1] > 0 and positions[1] < 200,
    "render must draw the interpolated x, got " .. tostring(positions[1]))

-- A stale snapshot must not let the marker run past what the server confirmed:
-- the world clock moving on cannot push the marker toward the target until the
-- next snapshot actually arrives.
worldHour = 109
local stale = layer.MarkerPosition(GROUP)
T.near(stale, midX, 1e-9,
    "stale snapshot must pin the marker to the confirmed hour")
T.truthy(stale <= midX + 1e-9,
    "marker must never run ahead of the last confirmed observation")

-- Arrival: back to the confirmed target, and the track is retired.
worldHour = 111
receivedAt = receivedAt + 1
ClientState.lastDirectorDebugReceiveAt = receivedAt
ClientState.directorDebug.groups[1] = {
    id = "agroup_mobile_map", groupType = "WANDERER",
    state = "ARRIVED", location = { x = 200, y = 400, z = 0 },
}
registered.definition.render(map)
T.near(layer.MarkerPosition(ClientState.directorDebug.groups[1]), 200, 1e-9,
    "arrived marker must sit on the confirmed target")
T.truthy(layer.TrackCount == 0, "arrived group track must be retired")

-- Live groups stay authoritative and are never interpolated.
worldHour = 100
receivedAt = receivedAt + 1
ClientState.lastDirectorDebugReceiveAt = receivedAt
ClientState.directorDebug.groups[1] = {
    id = "agroup_live_map", groupType = "WANDERER",
    state = "TRAVELING",
    groupStateStartedAt = 100, groupStateEndsAt = 110,
    location = { x = 0, y = 0, z = 0 },
    targetLocation = { x = 200, y = 400, z = 0 },
    mobile = { active = true, presence = "live" },
}
registered.definition.render(map)
T.truthy(layer.TrackCount == 0, "live group must not be interpolated")
T.near(layer.MarkerPosition(ClientState.directorDebug.groups[1]), 0, 1e-9,
    "live group marker must use its authoritative position")

-- Tracks are released when the layer stops being visible.
ClientState.directorDebug.groups[1] = GROUP
worldHour = 100
receivedAt = receivedAt + 1
ClientState.lastDirectorDebugReceiveAt = receivedAt
registered.definition.render(map)
T.truthy(layer.TrackCount == 1, "track should be rebuilt")
PNC.WorldDiscoveryDebugMap.ShowRawEntities = false
registered.definition.render(map)
T.truthy(layer.TrackCount == 0,
    "hiding the overlay must release interpolation state")

T.finish("pnc_abstract_group_map_layer_smoke")

T.finish("pnc_abstract_group_map_layer_smoke")
