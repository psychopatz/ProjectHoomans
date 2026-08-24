if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local DEBUG_CHANGE_LIMIT = 16
local getRelationship = Internal.getRelationship

local function appendDebugChange(
    record,
    targetKey,
    before,
    after,
    moraleBefore,
    moraleAfter,
    worldAgeHours,
    changeSpec
)
    changeSpec = type(changeSpec) == "table"
        and changeSpec or {}
    before = type(before) == "table" and before or {}
    after = type(after) == "table" and after or {}
    local approvalBefore = tonumber(before.approval) or 0
    local approvalAfter = tonumber(after.approval) or 0
    local respectBefore = tonumber(before.respect) or 0
    local respectAfter = tonumber(after.respect) or 0
    local familiarityBefore =
        tonumber(before.familiarity) or 0
    local familiarityAfter =
        tonumber(after.familiarity) or 0
    moraleBefore = tonumber(moraleBefore) or 0
    moraleAfter = tonumber(moraleAfter) or 0
    local stateBefore = tostring(before.state or "unknown")
    local stateAfter = tostring(after.state or "unknown")
    local hasChange = approvalBefore ~= approvalAfter
        or respectBefore ~= respectAfter
        or familiarityBefore ~= familiarityAfter
        or moraleBefore ~= moraleAfter
        or stateBefore ~= stateAfter
        or changeSpec.memoryID ~= nil
        or changeSpec.eventID ~= nil
        or (tonumber(changeSpec.removedCount) or 0) > 0
        or changeSpec.kind == "relationship_created"
    if not hasChange then return end
    record.runtime = record.runtime or {}
    local sequence = math.max(
        0,
        math.floor(tonumber(
            record.runtime.relationshipDebugSequence
        ) or 0)
    ) + 1
    record.runtime.relationshipDebugSequence = sequence
    local changes =
        record.runtime.relationshipDebugChanges or {}
    record.runtime.relationshipDebugChanges = changes
    changes[#changes + 1] = {
        sequence = sequence,
        targetKey = targetKey,
        kind = tostring(
            changeSpec.kind or "relationship_changed"
        ),
        eventID = changeSpec.eventID,
        memoryID = changeSpec.memoryID,
        memoryType = changeSpec.memoryType,
        knowledgeSource = changeSpec.knowledgeSource,
        removedCount =
            tonumber(changeSpec.removedCount) or 0,
        worldAgeHours = math.max(
            0,
            tonumber(worldAgeHours) or 0
        ),
        runtimeAt = Core and Core.Now
            and Core.Now() or 0,
        approvalBefore = approvalBefore,
        approvalAfter = approvalAfter,
        approvalDelta = approvalAfter - approvalBefore,
        respectBefore = respectBefore,
        respectAfter = respectAfter,
        respectDelta = respectAfter - respectBefore,
        familiarityBefore = familiarityBefore,
        familiarityAfter = familiarityAfter,
        familiarityDelta =
            familiarityAfter - familiarityBefore,
        moraleBefore = moraleBefore,
        moraleAfter = moraleAfter,
        moraleDelta = moraleAfter - moraleBefore,
        stateBefore = stateBefore,
        stateAfter = stateAfter,
        relationshipRevision =
            tonumber(after.revision) or 0,
    }
    while #changes > DEBUG_CHANGE_LIMIT do
        table.remove(changes, 1)
    end
end

local function commit(record, social, targetKey, relationship,
    relationshipChanged, worldAgeHours, changeSpec)
    local existing = getRelationship(record, targetKey)
    local moraleBefore = record.social
        and record.social.morale or 0
    if relationshipChanged then
        relationship.revision = math.max(
            tonumber(existing and existing.revision) or 0,
            tonumber(relationship.revision) or 0
        ) + 1
    end
    social.relationships[targetKey] = relationship
    if worldAgeHours ~= nil then
        social.lastEvaluatedAt = math.max(
            0,
            tonumber(worldAgeHours) or social.lastEvaluatedAt or 0
        )
    end
    social.revision = math.max(
        tonumber(record.social and record.social.revision) or 0,
        tonumber(social.revision) or 0
    ) + 1
    appendDebugChange(
        record,
        targetKey,
        existing,
        relationship,
        moraleBefore,
        social.morale,
        worldAgeHours,
        changeSpec
    )
    record.social = social
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "social")
    end
    if PNC.Factions
        and PNC.Factions.OnRelationshipChanged
    then
        PNC.Factions.OnRelationshipChanged(
            record,
            targetKey,
            relationship
        )
    end
    local parsedTarget = EntityRef.Parse(targetKey)
    if parsedTarget and parsedTarget.kind == "player"
        and PNC.NPCKnowledge
        and PNC.NPCKnowledge.OnFamiliarityMilestone
    then
        PNC.NPCKnowledge.OnFamiliarityMilestone(
            parsedTarget.characterUUID,
            record.id,
            tonumber(existing and existing.familiarity) or 0,
            tonumber(relationship and relationship.familiarity) or 0,
            worldAgeHours
        )
    end
end

Internal.commit = commit
