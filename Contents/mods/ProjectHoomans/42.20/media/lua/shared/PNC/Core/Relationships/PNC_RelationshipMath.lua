-- Engine-independent relationship recalculation, decay, and pruning.

PNC = PNC or {}
PNC.RelationshipMath = PNC.RelationshipMath or {}

local Math = PNC.RelationshipMath
local Constants = PNC.RelationshipConstants
local Types = PNC.RelationshipTypes
local States = PNC.RelationshipStates

function Math.Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value ~= value or value == math.huge or value == -math.huge then
        value = minimum
    end
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function Math.CalculateMemoryStrengthAtTime(memory, worldAgeHours)
    local normalized = Types.NormalizeMemory(memory)
    local elapsedDays
    if not normalized then
        return 0
    end
    if normalized.permanent then
        return normalized.strength
    end
    worldAgeHours = tonumber(worldAgeHours) or normalized.createdAt
    if worldAgeHours ~= worldAgeHours
        or worldAgeHours == math.huge
        or worldAgeHours == -math.huge
    then
        worldAgeHours = normalized.createdAt
    end
    elapsedDays = math.max(
        0,
        (worldAgeHours - normalized.createdAt) / 24
    )
    return math.max(
        0,
        normalized.strength - (normalized.decayPerDay * elapsedDays)
    )
end

function Math.RecalculateRelationship(value, targetKey, worldAgeHours)
    local relationship = Types.NormalizeRelationship(value, targetKey)
    local approval
    local respect
    local _
    local memory
    local strength
    local resolvedState
    if not relationship then
        return nil, false
    end
    worldAgeHours = tonumber(worldAgeHours)
    if worldAgeHours == nil
        or worldAgeHours ~= worldAgeHours
        or worldAgeHours == math.huge
        or worldAgeHours == -math.huge
    then
        worldAgeHours = relationship.lastEvaluatedAt
    end
    worldAgeHours = math.max(0, worldAgeHours)
    approval = relationship.baselineApproval
    respect = relationship.baselineRespect
    for _, memory in pairs(relationship.memories) do
        strength = Math.CalculateMemoryStrengthAtTime(
            memory,
            worldAgeHours
        )
        approval = approval + (memory.approvalEffect * strength)
        respect = respect + (memory.respectEffect * strength)
        memory.lastEvaluatedAt = worldAgeHours
    end
    relationship.approval = Math.Clamp(
        approval,
        Constants.APPROVAL_MIN,
        Constants.APPROVAL_MAX
    )
    relationship.respect = Math.Clamp(
        respect,
        Constants.RESPECT_MIN,
        Constants.RESPECT_MAX
    )
    relationship.familiarity = Math.Clamp(
        relationship.familiarity,
        Constants.FAMILIARITY_MIN,
        Constants.FAMILIARITY_MAX
    )
    resolvedState = States.ResolveState(relationship)
    if resolvedState ~= relationship.state then
        relationship.previousState = relationship.state
        relationship.state = resolvedState
    end
    relationship.lastEvaluatedAt = worldAgeHours
    return relationship, not Types.AreEqual(value, relationship)
end

function Math.PruneMemories(value, targetKey, worldAgeHours, maximum)
    local relationship = Types.NormalizeRelationship(value, targetKey)
    local kept = {}
    local removable = {}
    local _
    local memory
    local removed = 0
    local removeCount
    if not relationship then
        return nil, 0, false
    end
    maximum = math.max(
        0,
        math.floor(tonumber(maximum) or Constants.MEMORY_LIMIT)
    )
    for _, memory in pairs(relationship.memories) do
        if memory.permanent
            or Math.CalculateMemoryStrengthAtTime(memory, worldAgeHours) > 0
        then
            kept[#kept + 1] = memory
            if not memory.permanent then
                removable[#removable + 1] = memory
            end
        else
            removed = removed + 1
        end
    end
    table.sort(removable, function(left, right)
        local leftStrength =
            Math.CalculateMemoryStrengthAtTime(left, worldAgeHours)
        local rightStrength =
            Math.CalculateMemoryStrengthAtTime(right, worldAgeHours)
        if leftStrength ~= rightStrength then
            return leftStrength < rightStrength
        end
        if left.createdAt ~= right.createdAt then
            return left.createdAt < right.createdAt
        end
        return left.id < right.id
    end)
    removeCount = math.max(0, #kept - maximum)
    local removeIDs = {}
    for index = 1, math.min(removeCount, #removable) do
        removeIDs[removable[index].id] = true
    end
    relationship.memories = {}
    for _, memory in pairs(kept) do
        if removeIDs[memory.id] then
            removed = removed + 1
        else
            relationship.memories[#relationship.memories + 1] = memory
        end
    end
    table.sort(relationship.memories, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt < right.createdAt
        end
        return left.id < right.id
    end)

    -- Future consolidation may replace weak temporary memories with baseline
    -- traits here. Phase 1 only performs deterministic pruning.
    return relationship, removed, #relationship.memories <= maximum
end

return Math
