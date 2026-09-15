-- Shared, engine-free presentation helpers for the faction debug model.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

function Model.ShortenID(value, maximum)
    value = tostring(value or "")
    maximum = math.max(12, tonumber(maximum) or 36)
    if #value <= maximum then return value end
    local side = math.floor((maximum - 3) / 2)
    return string.sub(value, 1, side) .. "..."
        .. string.sub(value, -side)
end

function Internal.Row(label, value, tone)
    return {
        label = tostring(label or ""),
        value = tostring(value == nil and "" or value),
        tone = tone or "text",
    }
end

function Internal.EnabledKeys(values)
    local keys = {}
    for key, value in pairs(values or {}) do
        if value == true then
            keys[#keys + 1] = tostring(key)
        elseif type(value) == "string" then
            keys[#keys + 1] = tostring(key)
                .. "=" .. value
        end
    end
    table.sort(keys)
    return #keys > 0 and table.concat(keys, ", ") or "(none)"
end

function Internal.EmblemText(emblem)
    if type(emblem) ~= "table" then return "(generated on load)" end
    local layers = {}
    local index
    for index = 1, #(emblem.layers or {}) do
        local layer = emblem.layers[index]
        layers[#layers + 1] = tostring(layer.symbolID)
            .. "/" .. tostring(layer.colorID)
    end
    return tostring(emblem.backgroundColorID or "unknown")
        .. " | " .. (
            #layers > 0 and table.concat(layers, " + ")
                or "(no layers)"
        )
end
return Model
