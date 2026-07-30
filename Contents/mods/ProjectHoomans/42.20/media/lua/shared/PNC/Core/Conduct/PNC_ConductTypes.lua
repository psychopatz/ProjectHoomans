-- Pure serialization-safe constructors and normalizers for conduct.

PNC = PNC or {}
PNC.ConductTypes = PNC.ConductTypes or {}

local Types = PNC.ConductTypes
local Constants = PNC.ConductConstants
local EntityRef = PNC.EntityRef

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = tonumber(fallback)
    end
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return 0
    end
    return value
end

local function clamp(value, minimum, maximum, fallback)
    return math.max(minimum, math.min(maximum,
        finite(value, fallback)))
end

local function timestamp(value, fallback)
    return math.max(0, finite(value, fallback))
end

local function revision(value)
    return math.max(0, math.floor(finite(value, 0)))
end

local function validString(value, prefix, maximum)
    return type(value) == "string"
        and value ~= ""
        and #value <= (maximum or 512)
        and not string.find(value, "%c")
        and (not prefix
            or string.sub(value, 1, #prefix) == prefix)
end

local function normalizeTags(value)
    local output = {}
    local key
    if type(value) ~= "table" then return output end
    for key, enabled in pairs(value) do
        if enabled == true and type(key) == "string"
            and key ~= "" and #key <= 128
            and not string.find(key, "%c")
        then
            output[key] = true
        end
    end
    return output
end

function Types.IsValidConductDimension(value)
    return type(value) == "string"
        and Constants.VALID_DIMENSIONS[value] == true
end

function Types.NormalizeConductScores(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        output[dimension] = clamp(
            source[dimension],
            Constants.SCORE_MIN,
            Constants.SCORE_MAX,
            0
        )
    end
    return output
end

local function normalizeEffects(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local nonzero = false
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        if source[dimension] ~= nil then
            output[dimension] = clamp(
                source[dimension],
                Constants.EFFECT_MIN,
                Constants.EFFECT_MAX,
                0
            )
            nonzero = nonzero or output[dimension] ~= 0
        end
    end
    return output, nonzero
end

function Types.NormalizeConductEvidence(value)
    local source = type(value) == "table" and value or {}
    local effects
    local nonzero
    if not validString(source.id, "conduct:", 1024)
        or not validString(source.eventID, "social:")
        or not validString(source.eventType)
        or not EntityRef.IsValid(source.actorKey)
        or not EntityRef.IsValid(source.subjectKey)
    then
        return nil
    end
    effects, nonzero = normalizeEffects(source.effects)
    if not nonzero then return nil end
    return {
        id = source.id,
        eventID = source.eventID,
        eventType = source.eventType,
        actorKey = source.actorKey,
        subjectKey = source.subjectKey,
        createdAt = timestamp(source.createdAt, 0),
        lastEvaluatedAt = timestamp(
            source.lastEvaluatedAt,
            source.createdAt
        ),
        effects = effects,
        strength = clamp(
            source.strength,
            Constants.STRENGTH_MIN,
            Constants.STRENGTH_MAX,
            1
        ),
        decayPerDay = clamp(
            source.decayPerDay,
            Constants.DECAY_MIN,
            Constants.DECAY_MAX,
            0
        ),
        permanent = source.permanent == true,
        visibility = Constants.VALID_VISIBILITY[
            source.visibility
        ] and source.visibility
            or Constants.VISIBILITY_PRIVATE,
        shareable = source.shareable == true,
        tags = normalizeTags(source.tags),
    }
end

function Types.NewConductEvidence(spec)
    return Types.NormalizeConductEvidence(spec)
end

local function effectiveStrength(evidence, at)
    if evidence.permanent then return evidence.strength end
    return math.max(0, evidence.strength
        - evidence.decayPerDay
        * math.max(0, (at - evidence.createdAt) / 24))
end

local function normalizeEvidence(value, at)
    local output = {}
    local seen = {}
    local evidence
    for _, item in pairs(type(value) == "table" and value or {}) do
        evidence = Types.NormalizeConductEvidence(item)
        if evidence and not seen[evidence.id] then
            seen[evidence.id] = true
            if evidence.permanent
                or effectiveStrength(evidence, at) > 0
            then
                output[#output + 1] = evidence
            end
        end
    end
    if #output > Constants.EVIDENCE_LIMIT then
        table.sort(output, function(left, right)
            if left.permanent ~= right.permanent then
                return left.permanent
            end
            local leftStrength = effectiveStrength(left, at)
            local rightStrength = effectiveStrength(right, at)
            if leftStrength ~= rightStrength then
                return leftStrength > rightStrength
            end
            if left.createdAt ~= right.createdAt then
                return left.createdAt > right.createdAt
            end
            return left.id > right.id
        end)
        while #output > Constants.EVIDENCE_LIMIT
            and output[#output].permanent ~= true
        do
            table.remove(output)
        end
    end
    table.sort(output, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt < right.createdAt
        end
        return left.id < right.id
    end)
    return output
end

local function normalizeRecent(value)
    local output = {}
    local seen = {}
    local item
    for _, raw in pairs(type(value) == "table" and value or {}) do
        item = validString(raw, "conduct:", 1024) and raw or nil
        if item and not seen[item] then
            output[#output + 1] = item
            seen[item] = true
        end
    end
    while #output > Constants.RECENT_EVIDENCE_ID_LIMIT do
        table.remove(output, 1)
    end
    return output
end

function Types.NormalizeConductRecord(value)
    local source = type(value) == "table" and value or {}
    local at = timestamp(source.lastEvaluatedAt, 0)
    local baseline = Types.NormalizeConductScores(source.baseline)
    local evidence = normalizeEvidence(source.evidence, at)
    local scores = {}
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        local score = baseline[dimension]
        for _, item in ipairs(evidence) do
            score = score + (item.effects[dimension] or 0)
                * effectiveStrength(item, at)
        end
        scores[dimension] = clamp(
            score,
            Constants.SCORE_MIN,
            Constants.SCORE_MAX,
            0
        )
    end
    return {
        schemaVersion = Constants.SCHEMA_VERSION,
        revision = revision(source.revision),
        scores = scores,
        baseline = baseline,
        evidence = evidence,
        recentEvidenceIDs = normalizeRecent(
            source.recentEvidenceIDs
        ),
        lastEvaluatedAt = at,
    }
end

function Types.NewConductRecord(value)
    return Types.NormalizeConductRecord(value)
end

function Types.AreEqual(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, value in pairs(left) do
        if not Types.AreEqual(value, right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

return Types
