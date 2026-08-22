local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapLayerRegistry.lua"

local calls = {}
local warnings = 0

package.preload["ISUI/Maps/ISWorldMap"] = function()
    ISWorldMap = {
        render = function()
            calls[#calls + 1] = "vanilla"
        end,
    }
    return ISWorldMap
end

PNC = {
    Core = {
        LogWarn = function() warnings = warnings + 1 end,
    },
}

T.load(FILE)
local patchedRender = ISWorldMap.render

T.truthy(PNC.MapLayers.Register("late", {
    order = 200,
    render = function() calls[#calls + 1] = "late" end,
}))
T.truthy(PNC.MapLayers.Register("early", {
    order = 10,
    render = function() calls[#calls + 1] = "early" end,
}))
T.truthy(PNC.MapLayers.Register("broken", {
    order = 100,
    render = function() error("fixture failure") end,
}))

local map = {}
setmetatable(map, { __index = ISWorldMap })
map:render()

T.truthy(calls[1] == "vanilla", "map layers rendered before vanilla map content")
T.truthy(calls[2] == "early" and calls[3] == "late",
    "map layers did not use stable order or isolate a failed layer")
T.truthy(warnings == 1, "failed map layer was not reported exactly once")

-- Re-loading the registry must not stack another monkey patch.
T.load(FILE)
T.truthy(ISWorldMap.render == patchedRender,
    "map layer registry patched ISWorldMap more than once")
T.truthy(PNC.MapLayers.Unregister("broken"), "map layer unregister failed")
T.finish("pnc_map_layer_registry_smoke")

T.finish("pnc_map_layer_registry_smoke")
