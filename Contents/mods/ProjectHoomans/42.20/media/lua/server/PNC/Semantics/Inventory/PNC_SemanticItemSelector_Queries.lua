if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Selector = PNC.Semantics.ItemSelector
local Internal = Selector.Internal

local function sortedItemIDs(items)
    local ids = {}
    for id in pairs(items or {}) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
    return ids
end

function Selector.Find(record, request, options)
    request = type(request) == "table" and request or {}
    options = type(options) == "table" and options or {}
    local inventory = options.inventory
    if not inventory and record and record.inventory then
        inventory = record.inventory
    end
    if not inventory and PNC.Inventory
        and type(PNC.Inventory.EnsureRecordInventory) == "function"
    then
        inventory = PNC.Inventory.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        })
    end
    local items = inventory and inventory.items or nil
    if type(items) ~= "table" then return nil, "inventory_unavailable" end
    local ids = sortedItemIDs(items)
    local limit = math.max(1, math.floor(tonumber(options.maxItems)
        or Selector.MAX_ITEMS))
    local candidates = {}
    local classificationReason
    for index = 1, math.min(#ids, limit) do
        local item = items[ids[index]]
        if item and (options.includeLocked == true
            or item.interactionLocked ~= true)
        then
            local matched, reason, details = Selector.Matches(item, request)
            if matched then
                candidates[#candidates + 1] = {
                    item = item,
                    details = details,
                    score = Internal.Score(item, request, details),
                }
            elseif reason == "classification_unavailable"
                or reason == "classification_failed"
            then
                classificationReason = reason
            end
        end
    end
    if #candidates < 1 then
        return nil, classificationReason or "item_not_found"
    end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        local leftType = Internal.ItemType(left.item)
        local rightType = Internal.ItemType(right.item)
        if leftType ~= rightType then return leftType < rightType end
        return tostring(left.item.id) < tostring(right.item.id)
    end)
    local selected = candidates[1].item
    local available = math.max(1, math.floor(tonumber(selected.stack) or 1))
    local quantity = math.max(1, math.floor(tonumber(
        request.quantity or options.quantity) or 1))
    return {
        itemID = tostring(selected.id),
        fullType = Internal.ItemType(selected),
        available = available,
        quantity = math.min(quantity, available),
        score = candidates[1].score,
        classification = candidates[1].details,
    }, "matched"
end

return Selector
