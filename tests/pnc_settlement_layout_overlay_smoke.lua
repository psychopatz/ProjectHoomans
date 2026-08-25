local T = require "tests/support/test"

T.addPackagePaths()

local tickCallback
local resetCallback
Events = {
    OnPreUIDraw = { Add = function() end },
    OnTick = { Add = function(callback) tickCallback = callback end },
    OnMainMenuEnter = { Add = function(callback) resetCallback = callback end },
}

local Overlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
local region = { levels = { [0] = { rows = { [4] = { 2, 5 } } } } }
local layers = Overlay.BuildLayers({
    id = "base_a", geometry = { region = region },
    facilities = {{
        id = "facility_a", definitionId = "farm",
        constructionState = "BUILT", components = {
            { id = "field_a", kind = "region", role = "growing.plot",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.anchor",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
}, true)

T.equal(#layers, 4, "base, facility, anchor, and stockpile layers")
T.equal(layers[2].componentId, "field_a", "component identity retained")
T.equal(layers[3].region.levels[0].rows[4][1], 3, "anchor tile region")
T.equal(layers[4].kind, "stockpile", "stockpile overlay kind")
T.equal(layers[1].color.a < layers[2].color.a, true,
    "base territory is less distracting than built rooms")
T.equal(layers[2].color.g < layers[3].color.g, true,
    "built room is darker than its anchor component")
T.equal(layers[2].color.a > layers[1].color.a, true,
    "built room remains lightly more opaque than home territory")

local markers = Overlay.BuildMarkers({
    facilities = {{
        id = "facility_a", definitionId = "farm",
        constructionRegion = region,
        components = {
            { id = "field_a", kind = "region", role = "growing.plot",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.research",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
})
T.equal(#markers, 3, "room, anchor, and stockpile markers")
T.equal(markers[1].kind, "room", "room marker kind")
T.equal(markers[1].x, 4, "room marker dynamic horizontal center")
T.equal(markers[1].y, 4.5, "room marker dynamic vertical center")
T.equal(markers[2].role, "work.research", "component marker role")
T.equal(markers[1].tileScale, 1, "room marker fills one tile")
T.equal(markers[2].tileScale, 1, "component marker fills one tile")

local stockpileMarkers = Overlay.BuildMarkers({ facilities = {{
    id = "stockpile_1", definitionId = "stockpile", level = 1,
    constructionRegion = region, components = {{
        id = "stockpile_zone", kind = "region", role = "work.zone",
        region = region,
    }},
}} })
T.equal(stockpileMarkers[1].label, "Stockpile Lv 1",
    "stockpile marker includes its storage level")

local workRegion = { levels = { [0] = { rows = { [6] = { 6, 6 } } } } }
local zonedSettlement = { facilities = {
    { id = "forge_1", definitionId = "forge", constructionRegion = workRegion,
        components = {{ id = "zone_1", kind = "region", role = "work.zone",
            region = workRegion }} },
    { id = "forge_2", definitionId = "forge", constructionRegion = workRegion,
        components = {{ id = "zone_2", kind = "region", role = "work.zone",
            region = workRegion }} },
} }
local workLayers = Overlay.BuildLayers(zonedSettlement, false)
T.equal(#workLayers, 2, "each facility exposes its work-zone overlay")
T.equal(workLayers[1].kind, "work_zone", "work-zone layer kind")
T.equal(workLayers[1].color.a < 0.30, true,
    "work-zone highlight stays translucent over the native workstation")
local workMarkers = Overlay.BuildMarkers(zonedSettlement)
T.equal(#workMarkers, 2, "each facility exposes a work-zone marker")
T.equal(workMarkers[1].label, "Forge #1", "first duplicate facility is numbered")
T.equal(workMarkers[2].label, "Forge #2", "second duplicate facility is numbered")

local constructionLayers = Overlay.BuildLayers({ facilities = {{
    id = "facility_building", definitionId = "research_facility",
    constructionState = "UNDER_CONSTRUCTION",
    constructionRegion = region, components = {},
}} }, false)
T.equal(#constructionLayers, 1, "construction footprint layer")
T.equal(constructionLayers[1].color.r, 1,
    "active construction uses its dynamic state color")

local renderedIcons = 0
local renderedIconSizes = {}
local renderedAreas = 0
local hoverLabel
ISUIElement = {}
function ISUIElement:new(x, y, width, height)
    return {
        x = x, y = y, width = width, height = height,
        initialise = function() end,
        setCapture = function() end,
        setX = function(self, value) self.x = value end,
        setY = function(self, value) self.y = value end,
        setWidth = function(self, value) self.width = value end,
        setHeight = function(self, value) self.height = value end,
        drawTextureScaledAspect = function(_, _, _, _, width, height)
            renderedIcons = renderedIcons + 1
            renderedIconSizes[#renderedIconSizes + 1] = {
                width = width, height = height,
            }
        end,
        drawText = function(_, text)
            hoverLabel = text
        end,
    }
end
getSpecificPlayer = function()
    return { getPlayerNum = function() return 0 end }
end
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 1280 end
getPlayerScreenHeight = function() return 720 end
isoToScreenX = function(_, x) return x * 20 end
isoToScreenY = function(_, _, y) return y * 20 end
getTexture = function(path) return { path = path } end
addAreaHighlightForPlayer = function()
    renderedAreas = renderedAreas + 1
end
Overlay.SetSettlement({
    id = "base_a", geometry = { region = region },
    facilities = {{
        id = "facility_a", definitionId = "farm",
        constructionState = "BUILT", constructionRegion = region,
        components = {
            { id = "field_a", kind = "region", role = "growing.plot",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.research",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
})
Overlay.SetEnabled(true)
Overlay.Render()
T.equal(renderedAreas, 3, "room areas stay hidden until their icon is hovered")
T.equal(renderedIcons, 0, "overlay uses ground highlights without icons")
for _, size in ipairs(renderedIconSizes) do
    T.equal(size.width, 40, "overlay icon tracks full projected tile width")
    T.equal(size.height, 40, "overlay icon remains square")
end

getMouseX = function() return 80 end
getMouseY = function() return 90 end
Overlay.Render()
T.equal(renderedAreas, 7, "hovering a room icon reveals its room area")
T.equal(hoverLabel, "Farm", "hovering a room icon shows its facility name")

local groundMarkers = Overlay.BuildMarkers({ facilities = {{
    id = "forge_1", definitionId = "forge", constructionRegion = region,
    components = {
        { id = "station_1", kind = "anchor", role = "work.craft",
            managedByFacility = true, x = 3, y = 4, z = 0 },
        { id = "zone_1", kind = "region", role = "work.zone",
            region = region },
    },
}} })
T.equal(groundMarkers[1].texturePath, nil,
    "workstation marker has no image")
T.equal(groundMarkers[2].texturePath, nil,
    "work-zone marker has no image and remains a ground spot")

local resetSettlement = { id = "base_reset", revision = 4,
    geometry = { region = region }, facilities = {}, stockpileNodes = {
        { id = "stock_reset", x = 4, y = 4, z = 0 },
    } }
PNC.Network = { ClientState = {
    colonyManagement = { settlement = resetSettlement },
    colonyManagementRevision = 10,
} }
Overlay.SetSettlement(resetSettlement)
Overlay.SetEnabled(true)
T.truthy(resetCallback, "overlay installs a reset callback")
T.truthy(tickCallback, "overlay installs a snapshot sync tick")
resetCallback()
T.falsy(Overlay.IsEnabled(), "reset temporarily hides the old overlay")
tickCallback()
T.falsy(Overlay.IsEnabled(), "stale snapshot does not restore the overlay")
PNC.Network.ClientState.colonyManagementRevision = 11
tickCallback()
T.truthy(Overlay.IsEnabled(), "fresh snapshot restores the previous overlay state")
T.equal(Overlay.settlementId, "base_reset",
    "fresh snapshot rebuilds the settlement overlay")

T.finish("pnc_settlement_layout_overlay_smoke")

T.finish("pnc_settlement_layout_overlay_smoke")
