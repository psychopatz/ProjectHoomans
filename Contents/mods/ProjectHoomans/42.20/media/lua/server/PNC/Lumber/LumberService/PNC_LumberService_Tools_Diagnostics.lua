if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local findCanonicalLumberTool = Internal.FindCanonicalLumberTool
local canonicalItemFullType = Internal.CanonicalItemFullType
local ensureCanonicalLumberTool = Internal.EnsureCanonicalLumberTool
local resolveAbstractTool = Internal.ResolveAbstractTool
local resolveLiveTool = Internal.ResolveLiveTool
local workToolFullType = Internal.WorkToolFullType
local readLivePrimary = Internal.readLivePrimary
local inspectLiveTool = Internal.inspectLiveTool
local findLiveInventoryTool = Internal.findLiveInventoryTool

local function toolFullType(item)
    if not item or type(item.getFullType) ~= "function" then return nil end
    local fullType = item:getFullType()
    return fullType and tostring(fullType) or nil
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
    local canonical = findCanonicalLumberTool(record)
    local canonicalFullType = canonical and canonicalItemFullType(canonical)
        or workToolFullType(record)
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
                diagnostic.condition = tonumber(liveItem:getCondition())
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
            diagnostic.condition = tonumber(inventoryTool.item:getCondition())
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
    local condition = tonumber(item:getCondition())
    if condition == nil or tonumber(state.cond) == condition then return end
    state.cond = condition
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        PNC.Registry.MarkDirty(record, "lumber_tool_wear")
    end
end

local function skillRate(record)
    local level = 0
    if PNC.Skills and type(PNC.Skills.GetLevel) == "function" then
        local value = PNC.Skills.GetLevel(record, "Axe")
        level = math.max(0, tonumber(value) or 0)
    end
    return 1 + math.min(0.75, level * 0.05)
end

Internal.ResolveAbstractTool = resolveAbstractTool
Internal.ResolveLiveTool = resolveLiveTool
Internal.ToolFullType = toolFullType
Internal.ToolDiagnostic = toolDiagnostic
Internal.PersistLiveToolCondition = persistLiveToolCondition
Internal.SkillRate = skillRate


Internal.ResolveAbstractTool = resolveAbstractTool
Internal.ResolveLiveTool = resolveLiveTool
Internal.ToolFullType = toolFullType
Internal.ToolDiagnostic = toolDiagnostic
Internal.PersistLiveToolCondition = persistLiveToolCondition
Internal.SkillRate = skillRate

return Internal
