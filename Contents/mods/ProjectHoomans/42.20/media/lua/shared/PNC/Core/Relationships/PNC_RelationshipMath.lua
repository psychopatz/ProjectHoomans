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

function Math.NextMemorySequence(relationship)
    local memories = relationship and relationship.memories or {}
    local sequence = math.max(tonumber(relationship and relationship.revision) or 0,
        math.min(#memories, Constants.MEMORY_LIMIT))
    for index = 1, math.min(#memories, Constants.MEMORY_LIMIT) do
        sequence = math.max(sequence, tonumber(memories[index].eventSequence) or 0)
    end
    return math.min(2147483646, sequence + 1)
end

local function calculateMemoryStrengthFast(normalized, worldAgeHours)
    local coreSocial = PsychopatzCore and PsychopatzCore.Actors
        and PsychopatzCore.Actors.Social or nil
    if not normalized then
        return 0
    end
    if coreSocial and type(coreSocial.CalculateMemoryStrength) == "function" then
        return coreSocial.CalculateMemoryStrength(normalized, worldAgeHours)
    end
    if normalized.permanent or normalized.retentionClass == "ANCHOR" then
        return normalized.strength
    end
    worldAgeHours = tonumber(worldAgeHours) or normalized.createdAt
    if worldAgeHours ~= worldAgeHours
        or worldAgeHours == math.huge
        or worldAgeHours == -math.huge
    then
        worldAgeHours = normalized.createdAt
    end
    if normalized.retentionClass == "SCENE" then
        return worldAgeHours <= normalized.createdAt and normalized.strength or 0
    end
    local elapsedDays = math.max(
        0,
        (worldAgeHours - normalized.createdAt) / 24
    )
    return math.max(
        0,
        normalized.strength - (normalized.decayPerDay * elapsedDays)
    )
end

function Math.CalculateMemoryStrengthAtTime(memory, worldAgeHours)
    local normalized = Types.NormalizeMemory(memory)
    return calculateMemoryStrengthFast(normalized, worldAgeHours)
end

function Math.RecalculateRelationship(value, targetKey, worldAgeHours, alreadyNormalized)
    local isFast = alreadyNormalized == true and type(value) == "table" and type(value.memories) == "table"
    local relationship = isFast and value or Types.NormalizeRelationship(value, targetKey)
    local approval
    local respect
    local _
    local memory
    local strength
    local resolvedState
    if not relationship then
        return nil, false
    end
    local beforeApproval = relationship.approval
    local beforeRespect = relationship.respect
    local beforeFamiliarity = relationship.familiarity
    local beforeState = relationship.state
    local beforePrevState = relationship.previousState
    local beforeLastEval = relationship.lastEvaluatedAt
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
        strength = isFast
            and calculateMemoryStrengthFast(memory, worldAgeHours)
            or Math.CalculateMemoryStrengthAtTime(memory, worldAgeHours)
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
    if isFast then
        local changed = beforeApproval ~= relationship.approval
            or beforeRespect ~= relationship.respect
            or beforeFamiliarity ~= relationship.familiarity
            or beforeState ~= relationship.state
            or beforePrevState ~= relationship.previousState
            or beforeLastEval ~= relationship.lastEvaluatedAt
        return relationship, changed
    end
    return relationship, not Types.AreEqual(value, relationship)
end

function Math.PruneMemories(value, targetKey, worldAgeHours, maximum, alreadyNormalized)
    local isFast = alreadyNormalized == true and type(value) == "table" and type(value.memories) == "table"
    local relationship = isFast and value or Types.NormalizeRelationship(value, targetKey)
    local kept = {}
    local removable = {}
    local strengthByID = {}
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
        local strength = isFast
            and calculateMemoryStrengthFast(memory, worldAgeHours)
            or Math.CalculateMemoryStrengthAtTime(memory, worldAgeHours)
        if memory.permanent or strength > 0 then
            kept[#kept + 1] = memory
            strengthByID[memory.id] = strength
            if not memory.permanent then
                removable[#removable + 1] = memory
            end
        else
            removed = removed + 1
        end
    end
    table.sort(removable, function(left, right)
        local leftStrength = strengthByID[left.id] or 0
        local rightStrength = strengthByID[right.id] or 0
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
