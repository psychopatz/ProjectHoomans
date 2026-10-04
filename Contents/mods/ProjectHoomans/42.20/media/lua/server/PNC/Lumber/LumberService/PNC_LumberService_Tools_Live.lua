if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local CoreInventory = Internal.CoreInventory
local canonicalItemFullType = Internal.CanonicalItemFullType
local isChoppingFullType = Internal.IsChoppingFullType
local ensureCanonicalLumberTool = Internal.EnsureCanonicalLumberTool
local findCanonicalLumberTool = Internal.FindCanonicalLumberTool

local function readLivePrimary(body)
    if not body or type(body.getPrimaryHandItem) ~= "function" then
        return nil
    end
    return body:getPrimaryHandItem()
end

local function inspectLiveTool(item)
    if not item then return nil, "lumber_tool_missing" end
    local broken = false
    if type(item.isBroken) == "function" then
        broken = item:isBroken() == true
    end
    if broken then return nil, "lumber_tool_broken" end
    local damage
    if type(item.getTreeDamage) == "function" then
        damage = tonumber(item:getTreeDamage())
    end
    -- ItemTag.CHOP_TREE is useful metadata, but it cannot make a native item
    -- damage a tree. IsoTree:WeaponHit() reads the weapon's actual
    -- getTreeDamage() value, and Base.Hammer (among other tools) returns 0.
    -- Lua considers numeric zero truthy, so the old `not damage` check let
    -- zero-damage tools reach the live hit boundary and play an animation
    -- forever without changing the tree.
    if damage == nil or damage <= 0 then
        return nil, "tool_cannot_chop"
    end
    return { item = item, canChop = true, treeDamage = damage }
end

local function findLiveInventoryTool(body)
    local container
    local physical
    local items
    local tool
    if not body or type(body.getInventory) ~= "function"
        or not CoreInventory
        or type(CoreInventory.wrapPhysicalInventory) ~= "function"
    then
        return nil, "physical_inventory_unavailable"
    end
    container = body:getInventory()
    if not container then
        return nil, "physical_inventory_unavailable"
    end
    physical = CoreInventory.wrapPhysicalInventory(container, {
        recursive = true,
    })
    if not physical or type(physical.query) ~= "function" then
        return nil, "physical_inventory_unavailable"
    end
    items = physical:query(function(candidate)
        return inspectLiveTool(candidate) ~= nil
    end)
    for index = 1, #items do
        tool = inspectLiveTool(items[index])
        if tool then return tool end
    end
    return nil, "lumber_tool_missing"
end

local function addLiveItemToInventory(body, item)
    local container
    local physical
    local added
    if not body or not item or type(body.getInventory) ~= "function"
        or not CoreInventory
        or type(CoreInventory.wrapPhysicalInventory) ~= "function"
    then
        return nil, "physical_inventory_unavailable"
    end
    container = body:getInventory()
    if not container then
        return nil, "physical_inventory_unavailable"
    end
    physical = CoreInventory.wrapPhysicalInventory(container, {
        recursive = true, syncOnMutation = true,
    })
    if not physical or type(physical.add) ~= "function" then
        return nil, "physical_inventory_unavailable"
    end
    added = physical:add(item)
    if added ~= false then
        return type(added) == "table" and added[1] or item
    end

    -- Keep a native-engine fallback for older/mock containers whose item
    -- codec cannot inspect a freshly-created weapon. The live body still
    -- owns the exact item, and the next physical query verifies it.
    if type(container.AddItem) == "function" then
        local nativeAdded = container:AddItem(item)
        if nativeAdded ~= false then
            return nativeAdded or item
        end
    end
    return nil, "lumber_tool_inventory_add_failed"
end

local function equipLiveTool(body, item)
    if not body or not item or type(body.setPrimaryHandItem) ~= "function" then
        return nil, "lumber_tool_equip_unavailable"
    end
    body:setPrimaryHandItem(item)

    local bothHands = false
    if type(item.isRequiresEquippedBothHands) == "function" then
        bothHands = item:isRequiresEquippedBothHands() == true
    end
    if bothHands and type(body.setSecondaryHandItem) ~= "function" then
        return nil, "lumber_tool_secondary_equip_unavailable"
    end
    if bothHands and type(body.setSecondaryHandItem) == "function" then
        body:setSecondaryHandItem(item)
    end

    local equipped = inspectLiveTool(readLivePrimary(body))
    if not equipped then return nil, "lumber_tool_equip_not_applied" end
    equipped.equipped = true
    return equipped
end

local function workToolFullType(record)
    local inventory = record and record.inventory
    local item
    if inventory and inventory.equipped and inventory.items then
        item = inventory.items[inventory.equipped.primary]
    end
    return tostring(item and item.type
        or record and record.equipment and record.equipment.primaryFullType
        or "")
end

local function materializeLiveTool(record, body)
    local equipment = PNC.Equipment
    local canonical = ensureCanonicalLumberTool(record)
    local fullType = canonical and canonicalItemFullType(canonical)
        or workToolFullType(record)
    if fullType == "" or not isChoppingFullType(fullType) then
        return nil, "lumber_tool_missing"
    end

    -- Prefer the canonical item path so condition/visual state and the
    -- persisted inventory ID stay associated with the physical axe.
    if canonical and canonical.id and PNC.Inventory
        and type(PNC.Inventory.MaterializeItem) == "function"
    then
        PNC.Inventory.MaterializeItem(record, body, canonical.id)
        local inventoryTool = findLiveInventoryTool(body)
        if inventoryTool then return inventoryTool.item end
    end

    if not equipment or type(equipment.CreateItem) ~= "function" then
        return nil, "lumber_tool_materialization_unavailable"
    end
    local item, reason = equipment.CreateItem(fullType)
    if not item then
        return nil, "lumber_tool_materialize_failed:" .. tostring(reason)
    end
    local internal = equipment.Internal
    if internal and type(internal.applyPrimaryInventoryState) == "function" then
        internal.applyPrimaryInventoryState(item, record)
    end
    local added, addReason = addLiveItemToInventory(body, item)
    if not added then return nil, addReason end
    return added
end

local function resolveLiveTool(record, body)
    if not body then return nil, "live_body_missing" end
    ensureCanonicalLumberTool(record)
    local item = readLivePrimary(body)
    local tool, reason = inspectLiveTool(item)
    if tool then
        -- A presentation-only primary item is not enough for lumber. Make
        -- sure the same usable axe is owned by the live inventory first.
        local inventoryTool = findLiveInventoryTool(body)
        if not inventoryTool then
            local added, addReason = addLiveItemToInventory(body, item)
            if not added then return nil, addReason end
            inventoryTool = findLiveInventoryTool(body)
        end
        local equipped, equipReason = equipLiveTool(body,
            inventoryTool and inventoryTool.item or item)
        if equipped then return equipped end
        return nil, equipReason
    end

    -- Prefer a real inventory item over creating a presentation copy from
    -- canonical metadata.
    tool, reason = findLiveInventoryTool(body)
    if tool then
        local equipped, equipReason = equipLiveTool(body, tool.item)
        if equipped then return equipped end
        return nil, equipReason
    end

    local equipment = PNC.Equipment
    local ensureHands = equipment and type(equipment.EnsureCombatHands) == "function"
        and equipment.EnsureCombatHands
        or equipment and type(equipment.ApplyHands) == "function"
        and equipment.ApplyHands or nil
    if ensureHands then
        ensureHands(body, record)
        item = readLivePrimary(body)
        tool, reason = inspectLiveTool(item)
        if tool then
            local inventoryTool = findLiveInventoryTool(body)
            if not inventoryTool then
                local added, addReason = addLiveItemToInventory(body, item)
                if not added then return nil, addReason end
                inventoryTool = findLiveInventoryTool(body)
            end
            local equipped, equipReason = equipLiveTool(body,
                inventoryTool and inventoryTool.item or item)
            if equipped then return equipped end
            return nil, equipReason
        end
    end

    item, reason = materializeLiveTool(record, body)
    tool, reason = inspectLiveTool(item)
    if tool then
        local equipped, equipReason = equipLiveTool(body, item)
        if equipped then
            equipped.materialized = true
            return equipped
        end
        return nil, equipReason
    end
    return nil, reason or "lumber_tool_missing"
end


Internal.ResolveLiveTool = resolveLiveTool
Internal.WorkToolFullType = workToolFullType
Internal.readLivePrimary = readLivePrimary
Internal.inspectLiveTool = inspectLiveTool
Internal.findLiveInventoryTool = findLiveInventoryTool
