--[[
    Ordered transient world-map layer registry.

    Travel is only the first consumer. Jobs, threats, colonies, trade routes,
    and encounter areas can register independent renderers without stacking
    additional ISWorldMap monkey patches.
]]

require "ISUI/Maps/ISWorldMap"

PNC = PNC or {}
PNC.MapLayers = PNC.MapLayers or {}

local Layers = PNC.MapLayers
local Core = PNC.Core

Layers.ByID = Layers.ByID or {}
Layers.Ordered = Layers.Ordered or {}

local function rebuildOrder()
    local output = {}
    local _, layer
    for _, layer in pairs(Layers.ByID) do
        output[#output + 1] = layer
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    Layers.Ordered = output
end

function Layers.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.render) ~= "function"
    then
        return false
    end
    definition.id = id
    Layers.ByID[id] = definition
    rebuildOrder()
    return true
end

function Layers.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Layers.ByID[id] then return false end
    Layers.ByID[id] = nil
    rebuildOrder()
    return true
end

function Layers.Render(map)
    local i
    local layer
    local visible
    local ok
    local layerError
    for i = 1, #Layers.Ordered do
        layer = Layers.Ordered[i]
        visible = layer.enabled ~= false
        if visible and type(layer.isVisible) == "function" then
            ok, visible = pcall(layer.isVisible, map)
            visible = ok and visible ~= false
        end
        if visible then
            ok, layerError = pcall(layer.render, map)
            if not ok and Core and Core.LogWarn then
                Core.LogWarn(
                    "PNC map layer failed id=" .. tostring(layer.id)
                        .. " error=" .. tostring(layerError)
                )
            end
        end
    end
end

if ISWorldMap and not ISWorldMap._pncMapLayersPatched then
    ISWorldMap._pncMapLayersPatched = true
    local originalRender = ISWorldMap.render
    function ISWorldMap:render()
        originalRender(self)
        -- UIWorldMap paints its terrain after prerender. Transient markers must
        -- be drawn here or the Java map surface covers them completely.
        Layers.Render(self)
    end
end

return Layers
