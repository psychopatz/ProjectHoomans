if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local isChoppingFullType = Internal.IsChoppingFullType
local canonicalItemFullType = Internal.CanonicalItemFullType
local ensureCanonicalLumberTool = Internal.EnsureCanonicalLumberTool

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
    local item = ensureCanonicalLumberTool(record)
    local fullType = item and canonicalItemFullType(item)
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


Internal.ResolveAbstractTool = resolveAbstractTool
