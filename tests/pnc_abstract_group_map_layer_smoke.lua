local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
    .. "Layers/PNC_MapLayer_AbstractGroups.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end
ISWorldMap = {}
UIFont = { Small = "small" }

local registered, requests = nil, 0
PNC = {
    WorldDiscoveryDebugMap = { ShowRawEntities = false },
    Core = { Now = function() return 2000 end },
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
        directorDebug = { groups = { {
            id = "agroup_population_map", groupType = "LOOTER",
            memberIds = { "npc_1", "npc_2", "npc_3" },
            factionId = "faction_population_map", mission = "SCAVENGE",
            state = "IDLE", location = { x = 100, y = 120, z = 0 },
        } } },
    } },
}

dofile(FILE)
assert(registered and registered.id == "pnc_abstract_groups",
    "abstract group layer was not registered")
assert(registered.definition.order > 90,
    "group markers should render above community geometry")
assert(registered.definition.isVisible() == false,
    "raw group overlay must be hidden by default")
PNC.WorldDiscoveryDebugMap.ShowRawEntities = true

local rectangles, labels, hover = {}, {}, {}
local map = {
    width = 600, height = 500,
    mapAPI = {
        worldToUIX = function(_, x) return x end,
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
assert(requests == 1, "map layer did not refresh Director data")
assert(#rectangles >= 2, "group marker and hover card were not rendered")
assert(labels[1] == "LOOTER", "group archetype label was not rendered")
assert(hover[2] == "Members: 3", "group hover population was not rendered")
assert(rectangles[1][6] == 1 and rectangles[1][7] == 0.22,
    "looter group did not use hostile map color")

print("pnc_abstract_group_map_layer_smoke: ok")
