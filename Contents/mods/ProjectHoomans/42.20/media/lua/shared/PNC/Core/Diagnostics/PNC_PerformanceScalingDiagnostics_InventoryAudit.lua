-- Inventory audit text is a bounded event sink; it never stores runtime data.
local Diagnostics = PNC.PerformanceScalingDiagnostics
local MAX_FIELDS = 16
local MAX_EVENT_BYTES = 64
local MAX_FIELD_BYTES = 256

local function boundedText(value, maxBytes)
    local valueType = type(value)
    local text
    if valueType == "string" or valueType == "number"
        or valueType == "boolean"
    then
        text = tostring(value)
    elseif value == nil then
        text = "nil"
    else
        text = "<" .. valueType .. ">"
    end
    text = string.gsub(text, "%c", " ")
    if #text > maxBytes then
        text = string.sub(text, 1, maxBytes - 3) .. "..."
    end
    return text
end

function Diagnostics.LogInventoryAudit(eventName, fields)
    local output
    local fieldCount = 0
    if Diagnostics.InventoryAuditEnabled ~= true then return false end
    output = {
        "inventory_audit",
        "event=" .. boundedText(eventName or "unknown", MAX_EVENT_BYTES),
    }
    for _, field in ipairs(type(fields) == "table" and fields or {}) do
        if fieldCount >= MAX_FIELDS then
            output[#output + 1] = "fields_truncated=true"
            break
        end
        fieldCount = fieldCount + 1
        output[#output + 1] = boundedText(field, MAX_FIELD_BYTES)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

return Diagnostics
