-- Persisted presentation history attached to the canonical directed
-- relationship. This never owns approval, respect, or familiarity.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Math = PNC.RelationshipMath
local isAuthority = Internal.isAuthority
local resolveObserver = Internal.resolveObserver
local validateTarget = Internal.validateTarget
local getRelationship = Internal.getRelationship
local prepareSocial = Internal.prepareSocial
local commit = Internal.commit

local function snapshot(value)
    if Types and Types.NormalizeRelationshipSnapshot then
        return Types.NormalizeRelationshipSnapshot(value)
    end
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = tostring(value.state or "unknown"),
        revision = tonumber(value.revision) or 0,
    }
end

local function delta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

function Relationships.RecordInteraction(observerNPCID, targetKey, entry)
    local record
    local reason
    local social
    local socialChanged
    local rawRelationship
    local relationship
    local at
    local specification
    local appended
    local key
    local value
    if not isAuthority() then return false, "not_authority" end
    if type(entry) ~= "table" then return false, "invalid_interaction" end
    record, reason = resolveObserver(observerNPCID)
    if not record then return false, reason end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then return false, reason end
    specification = {}
    for key, value in pairs(entry) do specification[key] = value end
    if not specification.eventID or tostring(specification.eventID) == "" then
        return false, "interaction_event_id_required"
    end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    at = math.max(0, tonumber(specification.worldAgeHours
        or specification.at) or 0)
    specification.before = specification.before or snapshot(rawRelationship)
    specification.after = specification.after or snapshot(relationship)
    specification.delta = specification.delta
        or delta(specification.before, specification.after)
    specification.at = specification.at or at
    specification.worldAgeHours = specification.worldAgeHours or at
    specification.applied = specification.applied == true
    appended = Internal.appendInteraction and Internal.appendInteraction(
        relationship,
        rawRelationship,
        at,
        { interaction = specification, eventID = specification.eventID }
    )
    if not appended then return false, "duplicate_interaction" end
    if Math and Math.RecalculateRelationship then
        relationship = Math.RecalculateRelationship(
            relationship,
            targetKey,
            at
        )
    end
    commit(
        record,
        social,
        targetKey,
        relationship,
        socialChanged or rawRelationship == nil,
        at,
        {
            kind = "interaction_recorded",
            eventID = specification.eventID,
        }
    )
    return true, "recorded", Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
end

return Relationships
