local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "Layers/PNC_MapLayer_PlayerSettlement.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end

local registered
local requests = 0
local lineCalls = {}
local popupLines = {}
local label
local markerBlocksSettlement = false
local basesVisible = true
local emblemDraw

ISWorldMap = {}
UIFont = { Small = "small" }
getText = function(key)
    local values = {
        UI_PNC_MapPlayerSettlement_Label = "Home Base",
        UI_PNC_MapPlayerSettlement_Status = "YOUR SETTLEMENT",
        UI_PNC_MapPlayerSettlement_HQ = "HQ LEVEL",
        UI_PNC_MapPlayerSettlement_Coverage = "COVERAGE",
        UI_PNC_MapPlayerSettlement_Population = "POPULATION",
        UI_PNC_MapPlayerSettlement_Facilities = "FACILITIES",
        UI_PNC_MapPlayerSettlement_Stockpile = "STOCKPILE NODES",
        UI_PNC_MapPlayerSettlement_Coordinates = "COORDINATES",
        UI_PNC_MapPlayerSettlement_Faction = "FACTION",
        UI_PNC_MapPlayerSettlement_Unknown = "Unknown",
    }
    return values[key] or key
end
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 6 end,
        getFontHeight = function() return 14 end,
    }
end

PNC = {
    Core = { Now = function() return 1000 end },
    MapDisplay = {
        AreBasesVisible = function() return basesVisible end,
    },
    MapLayers = {
        Register = function(id, definition)
            registered = { id = id, definition = definition }
            return true
        end,
    },
    MapTravelLayer = {
        FindMarkerAt = function()
            return markerBlocksSettlement and { id = "npc" } or nil
        end,
    },
    FactionEmblemRenderer = {
        Draw = function(target, emblem, x, y, size)
            emblemDraw = { target = target, emblem = emblem, size = size }
        end,
    },
    ColonyManagementClient = {
        RequestSnapshot = function()
            requests = requests + 1
            return true
        end,
    },
    Network = { ClientState = { colonyManagement = nil } },
}

T.load(FILE)

T.equal(registered.id, "pnc_player_settlement",
    "player settlement layer registered")
T.equal(registered.definition.order, 95,
    "player settlement renders before NPC travel dots")
T.truthy(registered.definition.isVisible(),
    "player settlement is visible without debug authorization")

local map = {
    width = 800,
    height = 600,
    mapAPI = {
        worldToUIX = function(_, x) return x end,
        worldToUIY = function(_, _, y) return y end,
        uiToWorldX = function(_, x) return x end,
        uiToWorldY = function(_, _, y) return y end,
    },
    javaObject = {
        DrawLine = function(_, _, x1, y1, x2, y2)
            lineCalls[#lineCalls + 1] = {
                x1 = x1, y1 = y1, x2 = x2, y2 = y2,
            }
        end,
    },
    getMouseX = function() return 101 end,
    getMouseY = function() return 201 end,
    drawRect = function() end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, value) label = value end,
    drawText = function(_, value) popupLines[#popupLines + 1] = value end,
}

registered.definition.render(map)
T.equal(requests, 1, "map requested the settlement snapshot")
T.equal(#lineCalls, 0, "missing settlement did not render a border")

local settlement = {
    id = "base_one",
    hqLevel = 2,
    territory = { claimedArea = 9, territoryCapacity = 16 },
    facilities = { { id = "farm" } },
    stockpileNodes = { { id = "node" } },
    geometry = {
        tileCount = 9,
        bounds = { minX = 100, minY = 200, maxX = 102, maxY = 202 },
        region = { levels = { [0] = { rows = {
            [200] = { 100, 102 },
            [201] = { 100, 102 },
            [202] = { 100, 102 },
        } } } },
    },
}
PNC.Network.ClientState.colonyManagement = {
    colony = { name = "Hearthwatch", currentPopulation = 3 },
    faction = { name = "Hearthwatchers", emblem = { layers = {} } },
    people = { {}, {}, {} },
    settlement = settlement,
}
lineCalls, popupLines, label = {}, {}, nil
registered.definition.render(map)
T.equal(#lineCalls, 4, "settlement border rendered")
T.equal(lineCalls[1].x2, 103,
    "border uses the outside edge of the inclusive max tile")
T.equal(lineCalls[2].y2, 203,
    "border height follows the settlement bounds")
T.equal(label, "Hearthwatch", "settlement label rendered")
T.equal(popupLines[1], "Hearthwatch", "hover title rendered")
T.contains(table.concat(popupLines, "|"), "YOUR SETTLEMENT",
    "hover identifies the player settlement")
T.contains(table.concat(popupLines, "|"), "COVERAGE: 9 / 16",
    "hover reports settlement coverage")
T.contains(table.concat(popupLines, "|"), "COORDINATES: 100, 200 - 102, 202",
    "hover reports settlement coordinates")
T.truthy(emblemDraw and emblemDraw.target == map,
    "hover renders the faction emblem")
T.truthy(PNC.PlayerSettlementMapLayer.FindAt(map, 101, 201),
    "settlement hit testing uses the canonical region")
T.falsy(PNC.PlayerSettlementMapLayer.FindAt(map, 105, 201),
    "outside settlement point did not hit")

settlement.geometry.bounds.maxX = 104
settlement.geometry.bounds.maxY = 204
settlement.geometry.region.levels[0].rows[203] = { 100, 104 }
settlement.geometry.region.levels[0].rows[204] = { 100, 104 }
lineCalls = {}
registered.definition.render(map)
T.equal(lineCalls[1].x2, 105,
    "expanded settlement border grew with the new max X")
T.equal(lineCalls[2].y2, 205,
    "expanded settlement border grew with the new max Y")

markerBlocksSettlement = true
popupLines = {}
registered.definition.render(map)
T.equal(#popupLines, 0,
    "NPC travel marker retains hover priority over the settlement")

basesVisible = false
lineCalls = {}
registered.definition.render(map)
T.equal(#lineCalls, 0, "BASES toggle hides the player settlement layer")

T.finish("pnc_player_settlement_map_layer_smoke")
