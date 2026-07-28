local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/Map/"
    .. "Layers/PNC_MapLayer_Travel.lua"

local layer
local dots = 0
local labels = {}
local colors = {}
local namesVisible = false
local mouseX = -100
local mouseY = -100

getTexture = function() return nil end
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
    },
    TravelDirectory = {
        ListProjected = function()
            return {
                {
                    id = "idle",
                    name = "Idle NPC",
                    faction = "neutral",
                    state = "live",
                    x = 10,
                    y = 20,
                },
                {
                    id = "moving",
                    name = "Moving NPC",
                    faction = "colonist",
                    recruited = true,
                    state = "en_route",
                    x = 30,
                    y = 40,
                    remainingWorldHours = 0.5,
                    roleTag = "trader",
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
    MapMarkerIcons = {
        Resolve = function() return nil end,
    },
}

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
    drawTextCentre = function(_, text)
        labels[#labels + 1] = text
    end,
}

assert(layer and layer.render, "travel map layer did not register")
layer.render(map)
assert(dots == 2, "idle and travelling NPC dots were not both rendered")
assert(colors[1].r == 0.95 and colors[1].g == 0.75,
    "neutral NPC marker was not yellow")
assert(colors[2].r == 0.15 and colors[2].g == 0.90,
    "companion NPC marker was not green")
assert(labels[1] == "Moving NPC [trader]",
    "selected NPC label or role postfix was not preserved")

labels = {}
mouseX = 10
mouseY = 20
layer.render(map)
assert(labels[#labels] == "Idle NPC",
    "hover tooltip still appended the live presence state")

labels = {}
mouseX = -100
mouseY = -100
namesVisible = true
layer.render(map)
assert(labels[1] == "Idle NPC"
    and labels[2] == "Moving NPC [trader]",
    "NPC name toggle did not reveal ordinary labels")

print("pnc_map_travel_layer_smoke: ok")
