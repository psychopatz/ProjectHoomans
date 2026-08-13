local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

local Overlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
local region = { levels = { [0] = { rows = { [4] = { 2, 5 } } } } }
local layers = Overlay.BuildLayers({
    id = "base_a", geometry = { region = region },
    facilities = {{
        id = "facility_a", definitionId = "farm",
        constructionState = "BUILT", components = {
            { id = "field_a", kind = "region", role = "farm.field",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.anchor",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
}, true)

equal(#layers, 4, "base, facility, anchor, and stockpile layers")
equal(layers[2].componentId, "field_a", "component identity retained")
equal(layers[3].region.levels[0].rows[4][1], 3, "anchor tile region")
equal(layers[4].kind, "stockpile", "stockpile overlay kind")
equal(layers[1].color.a < layers[2].color.a, true,
    "base territory is less distracting than built rooms")
equal(layers[2].color.g < layers[3].color.g, true,
    "built room is darker than its anchor component")
equal(layers[2].color.a > layers[1].color.a, true,
    "built room remains lightly more opaque than home territory")

local markers = Overlay.BuildMarkers({
    facilities = {{
        id = "facility_a", definitionId = "farm",
        constructionRegion = region,
        components = {
            { id = "field_a", kind = "region", role = "farm.field",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.research",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
})
equal(#markers, 3, "room, anchor, and stockpile markers")
equal(markers[1].kind, "room", "room marker kind")
equal(markers[1].x, 4, "room marker dynamic horizontal center")
equal(markers[1].y, 4.5, "room marker dynamic vertical center")
equal(markers[2].role, "work.research", "component marker role")
equal(markers[2].size < markers[1].size, true,
    "component marker remains subordinate to room marker")

local constructionLayers = Overlay.BuildLayers({ facilities = {{
    id = "facility_building", definitionId = "research_facility",
    constructionState = "UNDER_CONSTRUCTION",
    constructionRegion = region, components = {},
}} }, false)
equal(#constructionLayers, 1, "construction footprint layer")
equal(constructionLayers[1].color.r, 1,
    "active construction uses its dynamic state color")

local renderedIcons = 0
local renderedAreas = 0
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
        drawTextureScaledAspect = function()
            renderedIcons = renderedIcons + 1
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
            { id = "field_a", kind = "region", role = "farm.field",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.research",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
})
Overlay.SetEnabled(true)
Overlay.Render()
equal(renderedAreas > 0, true, "overlay areas rendered")
equal(renderedIcons, 3, "all placeholder overlay icons rendered")

print("pnc_settlement_layout_overlay_smoke: ok")
