local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
    .. "Layers/PNC_MapLayer_Travel.lua"
local PALETTE =
    "Contents/mods/ProjectHoomans/common/media/lua/client/PNC/UI/"
    .. "PNC_NPCTypePalette.lua"

local layer
local dots = 0
local labels = {}
local colors = {}
local iconColors = {}
local namesVisible = false
local mouseX = -100
local mouseY = -100
local hoveredPortrait
local portraitHidden = 0
local clock = 1000
local listProjectedCount = 0

getTexture = function() return nil end
getTimestampMs = function() return clock end
UIFont = { Small = "small" }
getTextManager = function()
    return {
        MeasureStringX = function(_, _, text) return #text * 6 end,
        getFontHeight = function() return 12 end,
    }
end

PNC = {
    Const = {
        TRAVEL_MAP_LABEL_MIN_ZOOM = 10,
        ORDER_FOLLOW = "follow",
    },
    TravelDirectory = {
        ListProjected = function()
            listProjectedCount = listProjectedCount + 1
            return {
                {
                    id = "idle",
                    name = "Idle NPC",
                    faction = "neutral",
                    state = "live",
                    x = 10,
                    y = 20,
                    portrait = {
                        identitySeed = 1,
                        appearance = { hairModel = "Short" },
                    },
                },
                {
                    id = "colonist",
                    name = "Working Colonist",
                    faction = "colonist",
                    recruited = true,
                    state = "live",
                    x = 30,
                    y = 40,
                },
                {
                    id = "moving",
                    name = "Moving Follower",
                    faction = "colonist",
                    recruited = true,
                    orderKind = "follow",
                    state = "en_route",
                    x = 50,
                    y = 60,
                    remainingWorldHours = 0.5,
                    roleTag = "trader",
                },
                {
                    id = "dead",
                    name = "Dead NPC",
                    alive = false,
                    colonist = false,
                    iconID = "dead_icon",
                    state = "corpse",
                    x = 70,
                    y = 80,
                },
                {
                    id = "dead_colonist",
                    name = "Dead Colonist",
                    deathMarker = true,
                    colonist = true,
                    state = "corpse",
                    x = 90,
                    y = 100,
                },
            }
        end,
    },
    MapLayers = {
        Register = function(_, definition)
            layer = definition
            return true
        end,
    },
    MapCommands = {
        IsSelected = function(id) return id == "moving" end,
    },
    MapDisplay = {
        AreNamesVisible = function() return namesVisible end,
        EnsureButton = function() end,
    },
    MapHoverPortrait = {
        Update = function(_, entry)
            hoveredPortrait = entry
            return entry and entry.portrait ~= nil
        end,
        Hide = function()
            portraitHidden = portraitHidden + 1
        end,
    },
    MapMarkerIcons = {
        Resolve = function(iconID)
            if iconID == "dead_icon" then
                return {
                    glyph = "X",
                    size = 10,
                    color = { r = 1, g = 0, b = 0 },
                }
            end
            return nil
        end,
    },
}

dofile(PALETTE)
package.preload["PNC/UI/PNC_NPCTypePalette"] =
    function() return PNC.NPCTypePalette end
dofile(FILE)

local map = {
    width = 500,
    height = 500,
    mapAPI = {
        getZoomF = function() return 12 end,
        worldToUIX = function(_, x) return x end,
        worldToUIY = function(_, _, y) return y end,
    },
    getMouseX = function() return mouseX end,
    getMouseY = function() return mouseY end,
    drawRect = function(_, _, _, _, _, _, r, g, b)
        dots = dots + 1
        colors[#colors + 1] = { r = r, g = g, b = b }
    end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, text, _, _, r, g, b)
        if text == "X" then
            iconColors[#iconColors + 1] = {
                r = r,
                g = g,
                b = b,
            }
        else
            labels[#labels + 1] = text
        end
    end,
}

assert(layer and layer.render, "travel map layer did not register")
layer.render(map)
assert(listProjectedCount == 1,
    "travel map entries were not loaded for the first frame")
assert(dots == 5, "live and deceased NPC dots were not all rendered")
assert(colors[1].r == 0.95 and colors[1].g == 0.75,
    "neutral NPC marker was not yellow")
assert(colors[2].r == 0.08 and colors[2].g == 0.42,
    "working colonist marker was not dark green")
assert(colors[3].r == 0.15 and colors[3].g == 0.90,
    "following colonist marker was not green")
assert(colors[4].r == 0.55 and colors[4].g == 0.55,
    "dead NPC marker was not grey")
assert(colors[5].r == 0.55 and colors[5].g == 0.55,
    "dead colonist marker was not grey")
assert(iconColors[1].r == 0.55 and iconColors[1].g == 0.55,
    "dead NPC icon was not greyed out")
assert(labels[1] == "Moving Follower [trader]",
    "selected NPC label or role postfix was not preserved")

labels = {}
mouseX = 10
mouseY = 20
layer.render(map)
assert(listProjectedCount == 1,
    "travel map rebuilt all projected NPC entries inside the refresh window")
assert(labels[1] == "Moving Follower [trader]" and labels[2] == nil,
    "map layer duplicated the name owned by the visible portrait card")
assert(hoveredPortrait and hoveredPortrait.id == "idle",
    "hovered map marker was not sent to the portrait presenter")

labels = {}
mouseX = -100
mouseY = -100
namesVisible = true
layer.render(map)
assert(portraitHidden > 0,
    "map hover portrait was not hidden after leaving NPC dots")
assert(labels[1] == "Idle NPC"
    and labels[2] == "Working Colonist"
    and labels[3] == "Moving Follower [trader]"
    and labels[4] == "Dead NPC"
    and labels[5] == "Dead Colonist",
    "NPC name toggle did not reveal ordinary labels")
clock = 1100
layer.render(map)
assert(listProjectedCount == 2,
    "travel map did not refresh projected NPC entries after its throttle")

print("pnc_map_travel_layer_smoke: ok")
