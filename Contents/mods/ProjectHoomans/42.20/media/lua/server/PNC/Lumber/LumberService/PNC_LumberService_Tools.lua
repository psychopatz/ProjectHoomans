-- Lumber tool discovery, diagnostics, and condition synchronization.
-- Loaded by PNC_LumberService.lua after the shared service context exists.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local CoreInventory = Internal.CoreInventory

local function resolveAbstractTool(record)
    local runtime = record and record.runtime or {}
    if type(runtime.lumberTool) == "table" then
        local override = runtime.lumberTool
        if override.canChop ~= false then
            return {
                canChop = true,
                fullType = tostring(override.fullType or ""),
                treeDamage = math.max(1, tonumber(override.treeDamage) or 10),
                itemID = override.itemID,
                condition = tonumber(override.condition),
            }
        end
        return nil, "tool_cannot_chop"
    end
    local inventory = record and record.inventory
    local item
    if inventory and inventory.equipped and inventory.items then
        item = inventory.items[inventory.equipped.primary]
    end
    local fullType = item and item.type
        or record and record.equipment and record.equipment.primaryFullType
    fullType = tostring(fullType or "")
    local lower = string.lower(fullType)
    if not string.find(lower, "axe", 1, true)
        and not string.find(lower, "hatchet", 1, true)
        and not string.find(lower, "chopper", 1, true)
    then return nil, "lumber_tool_missing" end
    if item and tonumber(item.cond) and tonumber(item.cond) <= 0 then
        return nil, "lumber_tool_broken"
    end
    local damage = string.find(lower, "woodaxe", 1, true)
        and 40 or string.find(lower, "hatchet", 1, true)
        and 15 or 35
    return {
        canChop = true, fullType = fullType, treeDamage = damage,
        itemID = item and item.id or nil,
        condition = item and tonumber(item.cond) or nil,
    }
end

local function readLivePrimary(body)
    if not body or type(body.getPrimaryHandItem) ~= "function" then
        return nil
    end
    local ok, item = pcall(body.getPrimaryHandItem, body)
    return ok and item or nil
end

local function inspectLiveTool(item)
    if not item then return nil, "lumber_tool_missing" end
    local broken = false
    if type(item.isBroken) == "function" then
        local ok, value = pcall(item.isBroken, item)
        broken = ok and value == true
    end
    if broken then return nil, "lumber_tool_broken" end
    local tagged = false
    if ItemTag and type(item.hasTag) == "function" then
        local ok, value = pcall(item.hasTag, item, ItemTag.CHOP_TREE)
        tagged = ok and value == true
    end
    local damage
    if type(item.getTreeDamage) == "function" then
        local ok, value = pcall(item.getTreeDamage, item)
        if ok then damage = tonumber(value) end
    end
    if not tagged and not damage then return nil, "tool_cannot_chop" end
    return { item = item, canChop = true, treeDamage = math.max(1, damage or 10) }
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
    local ok
    ok, container = pcall(body.getInventory, body)
    if not ok or not container then
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

local function materializeLiveTool(record)
    local equipment = PNC.Equipment
    local fullType = workToolFullType(record)
    if fullType == "" then return nil, "lumber_tool_missing" end
    if not equipment or type(equipment.CreateItem) ~= "function" then
        return nil, "lumber_tool_materialization_unavailable"
    end
    local ok, item, reason = pcall(equipment.CreateItem, fullType)
    if not ok or not item then
        return nil, "lumber_tool_materialize_failed:" .. tostring(reason)
    end
    local internal = equipment.Internal
    if internal and type(internal.applyPrimaryInventoryState) == "function" then
        pcall(internal.applyPrimaryInventoryState, item, record)
    end
    return item
end

local function resolveLiveTool(record, body)
    if not body then return nil, "live_body_missing" end
    local item = readLivePrimary(body)
    local tool, reason = inspectLiveTool(item)
    if tool then return tool end

    -- Prefer a real inventory item over creating a presentation copy from
    -- canonical metadata.
    tool, reason = findLiveInventoryTool(body)
    if tool then
        local equipment = PNC.Equipment
        local networked = equipment and equipment.Internal
            and type(equipment.Internal.isNetworkedGame) == "function"
            and equipment.Internal.isNetworkedGame() == true
        if not networked and type(body.setPrimaryHandItem) == "function" then
            pcall(body.setPrimaryHandItem, body, tool.item)
            item = readLivePrimary(body)
            local equippedTool = inspectLiveTool(item)
            if equippedTool then return equippedTool end
        end
        return tool
    end

    local equipment = PNC.Equipment
    local ensureHands = equipment and type(equipment.EnsureCombatHands) == "function"
        and equipment.EnsureCombatHands
        or equipment and type(equipment.ApplyHands) == "function"
        and equipment.ApplyHands or nil
    if ensureHands then
        pcall(ensureHands, body, record)
        item = readLivePrimary(body)
        tool, reason = inspectLiveTool(item)
        if tool then return tool end
    end

    item, reason = materializeLiveTool(record)
    tool, reason = inspectLiveTool(item)
    if tool then
        tool.materialized = true
        return tool
    end
    return nil, reason or "lumber_tool_missing"
end

local function toolFullType(item)
    if not item or type(item.getFullType) ~= "function" then return nil end
    local ok, fullType = pcall(item.getFullType, item)
    return ok and fullType and tostring(fullType) or nil
end

local function requiredToolTypes()
    local registry = PNC.JobRequirements
    local definition = registry and registry.Get
        and registry.Get("LUMBER") or nil
    local requirement = definition and definition.requirements
        and definition.requirements[1] or nil
    local candidates = requirement and requirement.candidates or nil
    if type(candidates) ~= "table" or #candidates < 1 then
        candidates = { "Base.Axe", "Base.HandAxe", "Base.WoodAxe" }
    end
    local output = {}
    for index = 1, #candidates do output[index] = tostring(candidates[index]) end
    return output
end

local function toolDiagnostic(record, body)
    local diagnostic = {
        requiredItems = requiredToolTypes(),
        available = false,
        usable = false,
        source = "none",
    }
    local canonicalFullType = workToolFullType(record)
    diagnostic.canonicalPrimaryFullType = canonicalFullType ~= ""
        and canonicalFullType or nil
    local liveItem = body and readLivePrimary(body) or nil
    diagnostic.livePrimaryFullType = toolFullType(liveItem)
    if liveItem then
        local liveTool, liveReason = inspectLiveTool(liveItem)
        if liveTool then
            diagnostic.available = true
            diagnostic.usable = true
            diagnostic.source = "live_primary"
            diagnostic.selectedFullType = diagnostic.livePrimaryFullType
            diagnostic.treeDamage = liveTool.treeDamage
            if type(liveItem.getCondition) == "function" then
                local ok, condition = pcall(liveItem.getCondition, liveItem)
                if ok then diagnostic.condition = tonumber(condition) end
            end
            return diagnostic
        end
        diagnostic.reason = liveReason
    end

    local inventoryTool = body and findLiveInventoryTool(body) or nil
    if inventoryTool then
        diagnostic.available = true
        diagnostic.usable = true
        diagnostic.source = "live_inventory"
        diagnostic.selectedFullType = toolFullType(inventoryTool.item)
        diagnostic.treeDamage = inventoryTool.treeDamage
        if type(inventoryTool.item.getCondition) == "function" then
            local ok, condition = pcall(
                inventoryTool.item.getCondition, inventoryTool.item)
            if ok then diagnostic.condition = tonumber(condition) end
        end
        return diagnostic
    end

    local abstractTool, abstractReason = resolveAbstractTool(record)
    if not body and abstractTool then
        diagnostic.available = true
        diagnostic.usable = true
        diagnostic.source = "canonical_inventory"
        diagnostic.selectedFullType = canonicalFullType
        diagnostic.treeDamage = abstractTool.treeDamage
        diagnostic.condition = abstractTool.condition
        return diagnostic
    end
    if abstractTool then
        diagnostic.available = true
        diagnostic.source = "canonical_inventory"
        diagnostic.fallbackAvailable = true
        diagnostic.selectedFullType = canonicalFullType
        diagnostic.treeDamage = abstractTool.treeDamage
        diagnostic.condition = abstractTool.condition
        diagnostic.reason = diagnostic.reason or "live_primary_missing"
    else
        diagnostic.reason = diagnostic.reason or abstractReason
    end
    return diagnostic
end

function Service.GetToolDiagnostic(record, body)
    return toolDiagnostic(record, body)
end

local function persistLiveToolCondition(record, item)
    local inventory = record and record.inventory
    local itemID = inventory and inventory.equipped
        and inventory.equipped.primary or nil
    local state = itemID and inventory.items and inventory.items[itemID] or nil
    if not state or type(item.getCondition) ~= "function" then return end
    local ok, condition = pcall(item.getCondition, item)
    condition = ok and tonumber(condition) or nil
    if condition == nil or tonumber(state.cond) == condition then return end
    state.cond = condition
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        pcall(PNC.Registry.MarkDirty, record, "lumber_tool_wear")
    end
end

local function skillRate(record)
    local level = 0
    if PNC.Skills and type(PNC.Skills.GetLevel) == "function" then
        local ok, value = pcall(PNC.Skills.GetLevel, record, "Axe")
        if ok then level = math.max(0, tonumber(value) or 0) end
    end
    return 1 + math.min(0.75, level * 0.05)
end

Internal.ResolveAbstractTool = resolveAbstractTool
Internal.ResolveLiveTool = resolveLiveTool
Internal.ToolFullType = toolFullType
Internal.ToolDiagnostic = toolDiagnostic
Internal.PersistLiveToolCondition = persistLiveToolCondition
Internal.SkillRate = skillRate

return Internal
