if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Math = PNC.RelationshipMath
local Constants = PNC.RelationshipConstants
local isAuthority = Internal.isAuthority
local resolveObserver = Internal.resolveObserver
local validateTarget = Internal.validateTarget
local getRelationship = Internal.getRelationship
local prepareSocial = Internal.prepareSocial
local finiteNumber = Internal.finiteNumber
local commit = Internal.commit

function Relationships.Get(observerNPCID, targetKey)
    local record
    local reason
    local relationship
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return nil, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return nil, reason
    end
    relationship = getRelationship(record, targetKey)
    if not relationship then
        return nil, "relationship_not_found"
    end
    -- Return a canonical copy so a read API cannot mutate authoritative data.
    return Types.NormalizeRelationship(relationship, targetKey)
end

function Relationships.GetOrCreate(observerNPCID, targetKey)
    local record
    local reason
    local social
    local socialChanged
    local relationship
    local rawRelationship
    local relationshipChanged
    if not isAuthority() then
        return nil, "not_authority"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return nil, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return nil, reason
    end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    relationshipChanged = rawRelationship == nil
        or not Types.AreEqual(rawRelationship, relationship)
    if socialChanged or relationshipChanged then
        commit(
            record,
            social,
            targetKey,
            relationship,
            relationshipChanged,
            nil,
            {
                kind = rawRelationship == nil
                    and "relationship_created"
                    or "relationship_normalized",
            }
        )
    end
    return Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    ), rawRelationship == nil and "created" or "existing"
end

-- Debug-only synthetic baseline support. The server command that calls this
-- is admin gated. Memories, cooldowns, saturation, and familiarity are left
-- intact so the normal recalculation remains explainable and reproducible.
local function setBaseline(
    observerNPCID,
    targetKey,
    standing,
    worldAgeHours,
    eventKind
)
    local record
    local reason
    local social
    local socialChanged
    local rawRelationship
    local relationship
    if not isAuthority() then return nil, "not_authority" end
    if type(standing) ~= "table" then return nil, "invalid_standing" end
    worldAgeHours = finiteNumber(worldAgeHours)
    if worldAgeHours == nil or worldAgeHours < 0 then
        return nil, "invalid_world_age_hours"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then return nil, reason end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then return nil, reason end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    relationship.baselineApproval = Math.Clamp(
        standing.approval,
        Constants.APPROVAL_MIN,
        Constants.APPROVAL_MAX
    )
    relationship.baselineRespect = Math.Clamp(
        standing.respect,
        Constants.RESPECT_MIN,
        Constants.RESPECT_MAX
    )
    if standing.familiarity ~= nil then
        relationship.familiarity = Math.Clamp(
            standing.familiarity,
            Constants.FAMILIARITY_MIN,
            Constants.FAMILIARITY_MAX
        )
    end
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    commit(
        record,
        social,
        targetKey,
        relationship,
        socialChanged or not Types.AreEqual(rawRelationship, relationship),
        worldAgeHours,
        { kind = eventKind or "baseline_set" }
    )
    return Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
end


function Relationships.SetInitialBaseline(
    observerNPCID, targetKey, standing, worldAgeHours
)
    return setBaseline(
        observerNPCID, targetKey, standing, worldAgeHours,
        "initial_baseline_set"
    )
end

function Relationships.SetDebugBaseline(
    observerNPCID, targetKey, standing, worldAgeHours
)
    return setBaseline(
        observerNPCID, targetKey, standing, worldAgeHours,
        "debug_baseline_set"
    )
end

local function getNumeric(observerNPCID, targetKey, field)
    local relationship
    local reason
    relationship, reason = Relationships.Get(observerNPCID, targetKey)
    if not relationship then
        return nil, reason
    end
    return relationship[field]
end

function Relationships.GetApproval(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "approval")
end

function Relationships.GetRespect(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "respect")
end

function Relationships.GetFamiliarity(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "familiarity")
end

function Relationships.GetState(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "state")
end
