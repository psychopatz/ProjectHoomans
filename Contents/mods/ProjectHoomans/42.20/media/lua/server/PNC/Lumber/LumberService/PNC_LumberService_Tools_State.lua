if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal

local function isChoppingFullType(fullType)
    local lower = string.lower(tostring(fullType or ""))
    return string.find(lower, "axe", 1, true) ~= nil
        or string.find(lower, "hatchet", 1, true) ~= nil
        or string.find(lower, "chopper", 1, true) ~= nil
end

local function canonicalItemFullType(item)
    return item and tostring(item.type or item.fullType or "") or ""
end

local function canonicalItemBroken(item)
    return item and tonumber(item.cond) ~= nil and tonumber(item.cond) <= 0
end

local function findCanonicalLumberTool(record)
    local inventory = record and record.inventory
    local items = inventory and inventory.items
    if type(items) ~= "table" then return nil end

    local primaryID = inventory.equipped and inventory.equipped.primary
    local primary = primaryID and items[primaryID] or nil
    if primary and isChoppingFullType(canonicalItemFullType(primary))
        and not canonicalItemBroken(primary)
    then
        primary.id = primary.id or primaryID
        return primary
    end

    for itemID, item in pairs(items) do
        if type(item) == "table"
            and isChoppingFullType(canonicalItemFullType(item))
            and not canonicalItemBroken(item)
        then
            item.id = item.id or itemID
            return item
        end
    end
    return nil
end

local function ensureCanonicalLumberTool(record)
    local item = findCanonicalLumberTool(record)
    if item then
        local inventory = record and record.inventory
        local primaryID = inventory and inventory.equipped
            and inventory.equipped.primary or nil
        if tostring(primaryID or "") ~= tostring(item.id or "")
            and PNC.Inventory
            and type(PNC.Inventory.EquipPrimary) == "function"
        then
            PNC.Inventory.EquipPrimary(record, item.id, "lumber_tool_select")
        end
        return item
    end

    -- Older records may only have the loadout representation. Promote that
    -- configured axe into canonical inventory before materializing it.
    local configured = record and record.equipment
        and record.equipment.primaryFullType or nil
    if isChoppingFullType(configured)
        and PNC.Inventory
        and type(PNC.Inventory.SyncFromEquipment) == "function"
    then
        PNC.Inventory.SyncFromEquipment(record, "lumber_tool_inventory_sync")
        return findCanonicalLumberTool(record)
    end
    return nil
end


Internal.IsChoppingFullType = isChoppingFullType
Internal.CanonicalItemFullType = canonicalItemFullType
Internal.CanonicalItemBroken = canonicalItemBroken
Internal.FindCanonicalLumberTool = findCanonicalLumberTool
Internal.EnsureCanonicalLumberTool = ensureCanonicalLumberTool
