-- Small capability projection used by gift scoring.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Capabilities = Foundation.MarketSenseCapabilities or {}
Foundation.MarketSenseCapabilities = Capabilities

local function normalized(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[^%w]", "")
end

local function entries(value, output, seen, depth)
    local index
    local key
    local child
    depth = tonumber(depth) or 0
    if depth > 3 or #output >= 64 then return end
    if type(value) == "string" or type(value) == "number" then
        local item = normalized(value)
        if item ~= "" and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
        return
    end
    if type(value) ~= "table" then return end
    for index = 1, #value do
        entries(value[index], output, seen, depth + 1)
    end
    for key, child in pairs(value) do
        if type(key) ~= "number" and child == true then
            local item = normalized(key)
            if item ~= "" and not seen[item] then
                seen[item] = true
                output[#output + 1] = item
            end
        end
    end
end

function Capabilities.Fallback(primary, category, tags, role)
    local values = {}
    local seen = {}
    entries(primary, values, seen, 0)
    entries(category, values, seen, 0)
    entries(tags, values, seen, 0)
    local combined = table.concat(values, " ")
    role = normalized(role)
    local output = {}
    if role == "edible" or string.find(combined, "food", 1, true) then
        output.edible = true
        output.consumable = true
    end
    if role == "drinkable"
        or string.find(combined, "beverage", 1, true)
        or string.find(combined, "water", 1, true) then
        output.drinkable = true
        output.consumable = true
    end
    if string.find(combined, "containerliquid", 1, true) then
        output.refillable = true
    end
    return output
end

function Capabilities.Copy(value)
    local output = {}
    local key
    if type(value) ~= "table" then return output end
    for key in pairs(value) do
        if type(key) == "string" and value[key] == true then
            output[normalized(key)] = true
        end
    end
    return output
end

function Capabilities.HasEntries(value)
    local key
    if type(value) ~= "table" then return false end
    for key in pairs(value) do return true end
    return false
end

return Capabilities
