-- Read-only formatting and sanitized debug snapshots for conduct.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.ConductDebug = PNC.ConductDebug or {}

local Debug = PNC.ConductDebug
local Constants = PNC.ConductConstants

function Debug.BuildSnapshot(entityKey, at)
    local conduct, reason = PNC.Conduct.GetForEntity(entityKey)
    local parsed = PNC.EntityRef.Parse(entityKey)
    local evidence = {}
    if not conduct or not parsed then return nil, reason end
    at = tonumber(at) or conduct.lastEvaluatedAt
    conduct = PNC.ConductMath.Recalculate(conduct, at)
        or conduct
    for _, item in ipairs(conduct.evidence or {}) do
        local copy = PNC.Core.DeepCopy(item)
        copy.currentStrength =
            PNC.ConductMath.CalculateEvidenceStrengthAtTime(
                item, at
            )
        evidence[#evidence + 1] = copy
    end
    table.sort(evidence, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt > right.createdAt
        end
        return left.id < right.id
    end)
    return {
        entityKey = entityKey,
        entityKind = parsed.kind,
        entityID = parsed.targetID,
        characterUUID = parsed.characterUUID,
        npcID = parsed.npcID,
        revision = conduct.revision,
        scores = PNC.Core.DeepCopy(conduct.scores),
        baseline = PNC.Core.DeepCopy(conduct.baseline),
        evidence = evidence,
        evidenceCount = #evidence,
        lastEvaluatedAt = conduct.lastEvaluatedAt,
        previewedAt = at,
    }
end

function Debug.Format(entityKey, at)
    local snapshot, reason = Debug.BuildSnapshot(entityKey, at)
    if not snapshot then
        return "Conduct Debug\nEntity: " .. tostring(entityKey)
            .. "\nStatus: " .. tostring(reason)
    end
    local lines = {
        "Conduct Debug",
        "Entity: " .. tostring(entityKey),
        "Revision: " .. tostring(snapshot.revision),
        "",
        "Scores:",
    }
    for _, dimension in ipairs(Constants.DIMENSIONS) do
        lines[#lines + 1] = "  " .. dimension .. ": "
            .. string.format("%.2f",
                tonumber(snapshot.scores[dimension]) or 0)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Evidence:"
    for _, evidence in ipairs(snapshot.evidence) do
        lines[#lines + 1] = "  " .. evidence.eventType
        for _, dimension in ipairs(Constants.DIMENSIONS) do
            if evidence.effects[dimension] then
                lines[#lines + 1] = string.format(
                    "    %s: %+.2f",
                    dimension,
                    evidence.effects[dimension]
                )
            end
        end
        lines[#lines + 1] = "    visibility: "
            .. evidence.visibility
        lines[#lines + 1] = string.format(
            "    strength: %.4f",
            evidence.currentStrength
        )
        lines[#lines + 1] = "    event: " .. evidence.eventID
    end
    if #snapshot.evidence == 0 then
        lines[#lines + 1] = "  (none)"
    end
    return table.concat(lines, "\n")
end

return Debug
