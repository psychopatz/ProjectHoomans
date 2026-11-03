-- Hoomans compatibility facade over the shared PsychopatzCore map host.
-- Hoomans layers keep their existing registration API while Core owns the
-- single production ISWorldMap hook.

local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PNC = PNC or {}
PNC.MapLayers = PNC.MapLayers or {}

local Layers = PNC.MapLayers
local CoreOverlays = Host.Overlays or PsychopatzCore.MapOverlayRegistry

Layers.ByID = Layers.ByID or {}
Layers.Ordered = Layers.Ordered or {}

local function coreID(id)
    return "ProjectHoomans:" .. tostring(id or "")
end

local function rebuildOrder()
    local output = {}
    for _, definition in pairs(Layers.ByID) do
        output[#output + 1] = definition
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
    definition.order = tonumber(definition.order) or 100
    Layers.ByID[id] = definition
    rebuildOrder()

    return CoreOverlays.Register(coreID(id), {
        order = definition.order,
        enabled = definition.enabled,
        isVisible = definition.isVisible,
        render = function(map)
            local ok, err = pcall(definition.render, map)
            if not ok then
                if PNC.Core and PNC.Core.LogWarn then
                    PNC.Core.LogWarn(
                        "PNC map layer failed id=" .. tostring(id)
                            .. " error=" .. tostring(err)
                    )
                end
                return false
            end
            return true
        end,
        owner = "ProjectHoomans",
    })
end

function Layers.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Layers.ByID[id] then return false end
    Layers.ByID[id] = nil
    rebuildOrder()
    CoreOverlays.Unregister(coreID(id))
    return true
end

-- Retained for focused Hoomans tests and callers that explicitly ask the
-- facade to render. Production ISWorldMap rendering is owned by Core.
function Layers.Render(map)
    for index = 1, #Layers.Ordered do
        local layer = Layers.Ordered[index]
        local visible = layer.enabled ~= false
        if visible and type(layer.isVisible) == "function" then
            local ok, result = pcall(layer.isVisible, map)
            visible = ok and result ~= false
        end
        if visible then
            local ok, err = pcall(layer.render, map)
            if not ok and PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn(
                    "PNC map layer failed id=" .. tostring(layer.id)
                        .. " error=" .. tostring(err)
                )
            end
        end
    end
end

return Layers
