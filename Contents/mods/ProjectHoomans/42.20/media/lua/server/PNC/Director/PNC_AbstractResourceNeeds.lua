-- Normalized strategic shortages derived from canonical group needs and reserves.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractResourceNeeds = PNC.AbstractResourceNeeds or {}

local ResourceNeeds = PNC.AbstractResourceNeeds
local Groups = PNC.AbstractGroups
local Config = PNC.DirectorConfig

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

function ResourceNeeds.Get(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local canonical = Groups.GetNeeds(group) or {}
    local resources = group.resources or {}
    local memberCount = math.max(1, #(group.memberIds or {}))
    local targets = Config.ResourceNeeds.TARGET_PER_MEMBER
    local output = {
        food = clamp01(tonumber(canonical.hunger) or 0),
        water = clamp01(tonumber(canonical.hydration) or 0),
    }
    for _, category in ipairs({ "ammo", "medical", "materials" }) do
        local target = math.max(1, (tonumber(targets[category]) or 1) * memberCount)
        output[category] = clamp01(1 - (tonumber(resources[category]) or 0) / target)
    end
    -- Stored supplies matter even before physiological reserves have decayed.
    for _, category in ipairs({ "food", "water" }) do
        local target = math.max(1, (tonumber(targets[category]) or 1) * memberCount)
        local reserveShortage = clamp01(1 - (tonumber(resources[category]) or 0) / target)
        output[category] = math.max(output[category], reserveShortage * 0.65)
    end
    return output, "normalized"
end

function ResourceNeeds.ValuePotential(groupOrID, potential)
    local needs = ResourceNeeds.Get(groupOrID) or {}
    potential = type(potential) == "table" and potential or {}
    local components, total = {}, 0
    for _, category in ipairs(Config.RESOURCE_CATEGORIES) do
        local shortage = clamp01(needs[category])
        local base = tonumber(Config.ResourceNeeds.DESTINATION_BASE_WEIGHT[category]) or 0
        local weight = base * (Config.ResourceNeeds.MIN_DESTINATION_WEIGHT + shortage)
        local value = math.max(0, tonumber(potential[category]) or 0) * weight
        components[category] = { potential = tonumber(potential[category]) or 0,
            need = shortage, weight = weight, value = value }
        total = total + value
    end
    return total, components
end

return ResourceNeeds
