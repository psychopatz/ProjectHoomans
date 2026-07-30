-- Engine-independent conduct decay, score derivation, and pruning.

PNC = PNC or {}
PNC.ConductMath = PNC.ConductMath or {}

local Math = PNC.ConductMath
local Types = PNC.ConductTypes
local Constants = PNC.ConductConstants

function Math.CalculateEvidenceStrengthAtTime(evidence, at)
    evidence = Types.NormalizeConductEvidence(evidence)
    if not evidence then return 0 end
    if evidence.permanent then return evidence.strength end
    at = tonumber(at)
    if at == nil or at ~= at
        or at == math.huge or at == -math.huge
    then
        at = evidence.createdAt
    end
    return math.max(0, evidence.strength
        - evidence.decayPerDay
        * math.max(0, (at - evidence.createdAt) / 24))
end

function Math.Recalculate(value, at)
    local record = Types.NormalizeConductRecord(value)
    local scores = {}
    at = tonumber(at)
    if at == nil or at ~= at
        or at == math.huge or at == -math.huge or at < 0
    then
        return nil, false
    end
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        scores[dimension] = record.baseline[dimension]
    end
    for _, evidence in ipairs(record.evidence) do
        local strength =
            Math.CalculateEvidenceStrengthAtTime(evidence, at)
        for _, dimension in ipairs(Constants.DIMENSIONS) do
            scores[dimension] = scores[dimension]
                + (evidence.effects[dimension] or 0) * strength
        end
        evidence.lastEvaluatedAt = at
    end
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        scores[dimension] = math.max(
            Constants.SCORE_MIN,
            math.min(Constants.SCORE_MAX, scores[dimension])
        )
    end
    record.scores = scores
    record.lastEvaluatedAt = at
    return record, not Types.AreEqual(value, record)
end

function Math.PruneEvidence(value, at, maximum)
    local record = Types.NormalizeConductRecord(value)
    local kept = {}
    local removable = {}
    local removed = 0
    local selectedForRemoval = 0
    maximum = math.max(0, math.floor(
        tonumber(maximum) or Constants.EVIDENCE_LIMIT
    ))
    for _, evidence in ipairs(record.evidence) do
        local strength =
            Math.CalculateEvidenceStrengthAtTime(evidence, at)
        if evidence.permanent or strength > 0 then
            kept[#kept + 1] = evidence
            if not evidence.permanent then
                removable[#removable + 1] = {
                    evidence = evidence,
                    strength = strength,
                }
            end
        else
            removed = removed + 1
        end
    end
    table.sort(removable, function(left, right)
        if left.strength ~= right.strength then
            return left.strength < right.strength
        end
        if left.evidence.createdAt ~= right.evidence.createdAt then
            return left.evidence.createdAt
                < right.evidence.createdAt
        end
        return left.evidence.id < right.evidence.id
    end)
    local remove = {}
    local index = 1
    while #kept - selectedForRemoval > maximum
        and removable[index]
    do
        remove[removable[index].evidence.id] = true
        removed = removed + 1
        selectedForRemoval = selectedForRemoval + 1
        index = index + 1
    end
    local output = {}
    for _, evidence in ipairs(kept) do
        if not remove[evidence.id] then
            output[#output + 1] = evidence
        end
    end
    record.evidence = output
    return record, removed,
        #output <= maximum, not Types.AreEqual(value, record)
end

return Math
