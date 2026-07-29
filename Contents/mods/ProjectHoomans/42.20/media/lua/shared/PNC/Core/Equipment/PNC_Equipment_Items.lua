PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment

function Equipment.CreateItem(fullType)
    local ok
    local item
    local script
    local scriptManager

    if not fullType or fullType == "" then
        return nil, "no_full_type"
    end

    -- Validate before calling instanceItem. The engine logs every invalid
    -- lookup, so a bad descriptor otherwise floods the console whenever
    -- inventory/corpse reconciliation retries.
    scriptManager = getScriptManager and getScriptManager() or nil
    if scriptManager and scriptManager.FindItem then
        ok, script = pcall(scriptManager.FindItem, scriptManager, fullType)
        if not ok or not script then
            return nil, "invalid_full_type"
        end
    elseif scriptManager and scriptManager.getItem then
        ok, script = pcall(scriptManager.getItem, scriptManager, fullType)
        if not ok or not script then
            return nil, "invalid_full_type"
        end
    end

    if instanceItem then
        ok, item = pcall(instanceItem, fullType)
        if ok and item then
            return item, "instance_item"
        end
    end

    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then
            return item, "item_factory"
        end
    end

    script = script or getScriptManager and getScriptManager():getItem(fullType) or nil
    if script then
        return nil, "script_found_no_instance"
    end

    return nil, "invalid_full_type"
end
