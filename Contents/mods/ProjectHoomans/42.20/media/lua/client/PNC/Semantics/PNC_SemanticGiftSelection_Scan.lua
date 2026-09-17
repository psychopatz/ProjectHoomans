-- Client-side inventory traversal for semantic gifts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Selection = PNC.Semantics.GiftSelection or {}
PNC.Semantics.GiftSelection = Selection
local Internal = Selection.Internal or {}
Selection.Internal = Internal
Selection.MAX_ITEMS = Selection.MAX_ITEMS or 256
Selection.MAX_DEPTH = Selection.MAX_DEPTH or 4

local function safeCall(object, method, fallback, ...)
    if not object or type(object[method]) ~= "function" then
        return fallback
    end
    local ok, value = pcall(object[method], object, ...)
    if not ok or value == nil then return fallback end
    return value
end

local function listSize(list)
    if not list then return 0 end
    local size = safeCall(list, "size", nil)
    if size ~= nil then return math.max(0, math.floor(tonumber(size) or 0)) end
    return type(list) == "table" and #list or 0
end

local function listGet(list, index)
    local value = safeCall(list, "get", nil, index)
    if value ~= nil then return value end
    if type(list) == "table" then return list[index + 1] or list[index] end
    return nil
end

local function addField(fields, value, kind, priority)
    value = tostring(value or "")
    if value == "" then return end
    fields[#fields + 1] = { value = value, kind = kind,
        priority = tonumber(priority) or 0 }
end

local function factsFor(fullType, item)
    local foundation = PNC.Gifts and PNC.Gifts.Foundation
    local adapter = foundation and foundation.MarketSenseAdapter
    if not adapter or type(adapter.BuildFacts) ~= "function" then return nil end
    local ok, facts = pcall(adapter.BuildFacts, fullType, item)
    return ok and type(facts) == "table" and facts or nil
end

local function fieldsFor(item, fullType, facts)
    local fields = {}
    addField(fields, safeCall(item, "getDisplayName", nil), "display_name", 3)
    addField(fields, safeCall(item, "getName", nil), "custom_name", 4)
    addField(fields, fullType, "full_type", 1)
    if type(facts) == "table" then
        addField(fields, facts.leaf, "leaf", 8)
        addField(fields, facts.subcategory, "subcategory", 7)
        addField(fields, facts.category, "category", 5)
        addField(fields, facts.primary, "primary", 4)
        for index = 1, #(facts.preferenceCandidates or {}) do
            local entry = facts.preferenceCandidates[index]
            addField(fields, entry and entry.value, entry and entry.type,
                entry and entry.priority or 0)
        end
        for index = 1, #(facts.marketSenseTags or {}) do
            addField(fields, facts.marketSenseTags[index], "tag", 3)
        end
    end
    return fields
end

local function blocked(item, player)
    local model = PNC.InventoryUIModel
    if model and type(model.GetPlayerItemTransferBlockReason) == "function" then
        local ok, reason = pcall(
            model.GetPlayerItemTransferBlockReason,
            item,
            player
        )
        if ok and reason ~= nil then return true end
    end
    return safeCall(item, "isFavorite", false) == true
        or safeCall(item, "isEquipped", false) == true
end

local function inspectItem(item, player, output, seen, path, depth)
    depth = tonumber(depth) or 0
    if not item or #output >= Selection.MAX_ITEMS
        or depth > Selection.MAX_DEPTH then return end
    local id = tostring(safeCall(item, "getID", ""))
    local fullType = tostring(safeCall(item, "getFullType", ""))
    if id == "" or fullType == "" or seen[id] then return end
    seen[id] = true
    if not blocked(item, player) then
        local gifts = PNC.Gifts
        local valid = gifts and type(gifts.IsValidItemType) == "function"
            and gifts.IsValidItemType(fullType, item) == true
        if valid then
            local facts = factsFor(fullType, item)
            output[#output + 1] = { item = item, itemID = id,
                fullType = fullType, displayName = safeCall(
                    item, "getDisplayName", nil), facts = facts,
                fields = fieldsFor(item, fullType, facts), path = path }
        end
    end
    local nested = safeCall(item, "getItemContainer", nil)
        or safeCall(item, "getInventory", nil)
    local items = nested and safeCall(nested, "getItems", nil) or nil
    local count = math.min(listSize(items), Selection.MAX_ITEMS)
    for index = 0, count - 1 do
        inspectItem(listGet(items, index), player, output, seen,
            tostring(path or "root") .. "/" .. tostring(index), depth + 1)
        if #output >= Selection.MAX_ITEMS then break end
    end
end

function Internal.ScanPlayer(player)
    local output = {}
    local seen = {}
    local inventory = safeCall(player, "getInventory", nil)
    local items = inventory and safeCall(inventory, "getItems", nil) or nil
    local count = math.min(listSize(items), Selection.MAX_ITEMS)
    for index = 0, count - 1 do
        inspectItem(listGet(items, index), player, output, seen,
            "root/" .. tostring(index), 0)
        if #output >= Selection.MAX_ITEMS then break end
    end
    return output
end

return Selection
