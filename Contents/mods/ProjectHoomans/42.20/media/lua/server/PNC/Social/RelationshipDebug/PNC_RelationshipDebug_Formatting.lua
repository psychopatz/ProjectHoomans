if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Relationships = PNC.Relationships
local Math = PNC.RelationshipMath

local function signed(value)
    return string.format("%+.2f", tonumber(value) or 0)
end

function Debug.FormatRelationship(
    observerNPCID,
    targetKey,
    relationship,
    worldAgeHours
)
    worldAgeHours = tonumber(worldAgeHours)
        or tonumber(relationship.lastEvaluatedAt)
        or 0
    local lines = {
        "Relationship Debug",
        "Observer: " .. tostring(observerNPCID),
        "Target: " .. tostring(targetKey),
        "",
        "Approval: " .. tostring(relationship.approval),
        "Respect: " .. tostring(relationship.respect),
        "Familiarity: " .. tostring(relationship.familiarity),
        "State: " .. tostring(relationship.state),
        "Previous State: " .. tostring(relationship.previousState),
        "",
        "Baseline Approval: " ..
            tostring(relationship.baselineApproval),
        "Baseline Respect: " ..
            tostring(relationship.baselineRespect),
        "",
        "Active memories:",
    }
    local _
    local memory
    local strength
    if #(relationship.memories or {}) == 0 then
        lines[#lines + 1] = "(none)"
    end
    for _, memory in pairs(relationship.memories or {}) do
        strength = Math.CalculateMemoryStrengthAtTime(
            memory,
            worldAgeHours
        )
        if memory.permanent or strength > 0 then
            lines[#lines + 1] = "+ " .. tostring(memory.type)
            lines[#lines + 1] =
                "  approval: " .. signed(memory.approvalEffect)
            lines[#lines + 1] =
                "  respect: " .. signed(memory.respectEffect)
            lines[#lines + 1] =
                "  current strength: " ..
                string.format("%.4f", strength)
            lines[#lines + 1] =
                "  source: " .. tostring(memory.knowledgeSource)
        end
    end
    return table.concat(lines, "\n")
end

function Debug.Inspect(observerNPCID, targetKey, worldAgeHours)
    local relationship
    local reason
    if not Relationships or not Relationships.Get then
        return nil, "relationship_service_unavailable"
    end
    relationship, reason = Relationships.Get(observerNPCID, targetKey)
    if not relationship then
        return nil, reason
    end
    return Debug.FormatRelationship(
        observerNPCID,
        targetKey,
        relationship,
        worldAgeHours
    )
end
