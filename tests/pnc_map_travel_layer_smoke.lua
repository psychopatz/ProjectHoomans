local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/Map/"
    .. "Layers/PNC_MapLayer_Travel.lua"

local layer
local dots = 0
local labels = {}

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
                    state = "idle",
                    x = 10,
                    y = 20,
                },
                {
                    id = "moving",
                    name = "Moving NPC",
                    faction = "colonist",
                    state = "en_route",
                    x = 30,
                    y = 40,
                    remainingWorldHours = 0.5,
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
    getMouseX = function() return -100 end,
    getMouseY = function() return -100 end,
    drawRect = function() dots = dots + 1 end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, text)
        labels[#labels + 1] = text
    end,
}

assert(layer and layer.render, "travel map layer did not register")
layer.render(map)
assert(dots == 2, "idle and travelling NPC dots were not both rendered")
assert(labels[1] == "Idle NPC" and labels[2] == "Moving NPC",
    "NPC map labels were not rendered intact")

print("pnc_map_travel_layer_smoke: ok")
