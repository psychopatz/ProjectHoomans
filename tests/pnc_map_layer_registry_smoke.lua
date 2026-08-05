local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
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

dofile(FILE)
local patchedRender = ISWorldMap.render

assert(PNC.MapLayers.Register("late", {
    order = 200,
    render = function() calls[#calls + 1] = "late" end,
}))
assert(PNC.MapLayers.Register("early", {
    order = 10,
    render = function() calls[#calls + 1] = "early" end,
}))
assert(PNC.MapLayers.Register("broken", {
    order = 100,
    render = function() error("fixture failure") end,
}))

local map = {}
setmetatable(map, { __index = ISWorldMap })
map:render()

assert(calls[1] == "vanilla", "map layers rendered before vanilla map content")
assert(calls[2] == "early" and calls[3] == "late",
    "map layers did not use stable order or isolate a failed layer")
assert(warnings == 1, "failed map layer was not reported exactly once")

-- Re-loading the registry must not stack another monkey patch.
dofile(FILE)
assert(ISWorldMap.render == patchedRender,
    "map layer registry patched ISWorldMap more than once")
assert(PNC.MapLayers.Unregister("broken"), "map layer unregister failed")

print("pnc_map_layer_registry_smoke: ok")
