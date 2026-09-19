-- Pure bounded response formatting for server inventory projections.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local InventoryResponses = {}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function queryLabel(query)
    query = type(query) == "table" and query or {}
    local concept = string.upper(tostring(query.concept
        or query.category or ""))
    if concept == "SEAFOOD" then return "seafood" end
    if concept == "FOOD" then return "food" end
    if concept == "WATER" then return "water" end
    if concept == "MEDICINE" then return "medicine" end
    local value = tostring(query.text or query.category
        or query.concept or "that")
    return value ~= "" and value or "that"
end

local function itemLabel(item)
    item = type(item) == "table" and item or {}
    local label = tostring(item.displayName or item.customName
        or item.fullType or "item")
    local withoutModule = string.match(label, "^[^%.]+%.(.+)$")
    label = withoutModule or label
    label = string.gsub(label, "_", " ")
    return label
end

function InventoryResponses.ForResult(payload, pending)
    payload = type(payload) == "table" and payload or {}
    local query = payload.query
        or pending and pending.query or {}
    local label = queryLabel(query)
    local status = tostring(payload.status or "failed")
    if status == "pending" then
        return {
            key = "semantic.inventory.query.pending",
            fallback = "Let me check what I have.",
            args = { query = label },
        }
    end
    if status == "found" then
        local items = type(payload.items) == "table"
            and payload.items or {}
        local names = {}
        for index = 1, math.min(#items, 4) do
            local item = items[index]
            local quantity = math.max(1, math.floor(
                tonumber(item and item.quantity) or 1))
            names[#names + 1] = itemLabel(item)
                .. " (" .. tostring(quantity) .. ")"
        end
        local more = math.max(0, (tonumber(payload.distinctItems) or 0)
            - #names)
        local suffix = table.concat(names, ", ")
        if more > 0 then
            suffix = suffix .. (suffix ~= "" and ", " or "")
                .. tostring(more) .. " more"
        end
        local count = tonumber(payload.totalCount) or 0
        local text = "I have " .. tostring(count) .. " " .. label
            .. (count == 1 and " item" or " items")
        if suffix ~= "" then text = text .. ": " .. suffix end
        return {
            key = "semantic.inventory.found",
            fallback = text .. ".",
            args = {
                query = label,
                totalCount = count,
                distinctItems = payload.distinctItems,
                items = copyValue(items),
            },
        }
    end
    if status == "empty" then
        return {
            key = "semantic.inventory.empty",
            fallback = "I don't have any " .. label .. ".",
            args = { query = label },
        }
    end
    return {
        key = "semantic.inventory.failed",
        fallback = "I can't check my inventory right now.",
        args = { query = label, reason = payload.reason },
    }
end

return InventoryResponses
