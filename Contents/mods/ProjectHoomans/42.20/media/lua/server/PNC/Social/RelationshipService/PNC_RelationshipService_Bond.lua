-- Durable social-history bond transitions on the existing directed record.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local Core = PNC.Core

local function now(worldAgeHours)
    return math.max(0, tonumber(worldAgeHours)
        or Core and Core.Now and Core.Now() or 0)
end

local function friendshipEventID(record, targetKey, revision)
    return "social:friendship_established:"
        .. tostring(record and record.id or "npc") .. ":"
        .. tostring(targetKey or "target") .. ":"
        .. tostring(revision or 0)
end

local function meetsFriendGate(relationship)
    local state = tostring(relationship.state or Constants.STATE_UNKNOWN)
    return tonumber(relationship.approval) >= Constants.FRIEND_BOND_APPROVAL_ENTER
        and tonumber(relationship.respect) >= Constants.FRIEND_BOND_RESPECT_ENTER
        and tonumber(relationship.familiarity) >= Constants.FRIEND_BOND_FAMILIARITY_ENTER
        and state ~= Constants.STATE_RIVAL
        and state ~= Constants.STATE_ENEMY
end

function Internal.EvaluateDurableBond(record, targetKey, worldAgeHours)
    local relationship
    local social
    local bond
    local memory
    local eventID
    local at
    if not record or not targetKey or not Internal.isAuthority()
        or not Internal.getRelationship or not Internal.commit
    then
        return false, "not_authority"
    end
    relationship = Internal.getRelationship(record, targetKey)
    if not relationship then return false, "relationship_not_found" end
    relationship = Types.NormalizeRelationship(relationship, targetKey)
    bond = Types.NormalizeBond(relationship.bond)
    if bond.class ~= "none" then return false, "bond_already_established" end
    if not meetsFriendGate(relationship) then
        return false, "friend_gate_not_met"
    end
    at = now(worldAgeHours)
    eventID = friendshipEventID(record, targetKey, relationship.revision + 1)
    social = Types.NormalizeSocialState(
        record.social, record.identitySeed, record.archetypeID
    )
    if Internal.hasRecentEvent(social, eventID) then
        return false, "already_recorded"
    end
    memory = Types.NewMemory({
        id = eventID,
        type = "friendship_established",
        aboutKey = targetKey,
        createdAt = at,
        lastEvaluatedAt = at,
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        shareable = true,
        knowledgeSource = Constants.KNOWLEDGE_EXPERIENCED,
        tags = { social_history = true, friendship_established = true },
    })
    if not memory then return false, "friendship_memory_invalid" end
    relationship.bond = {
        schemaVersion = Constants.DURABLE_BOND_SCHEMA_VERSION,
        class = "friend",
        kind = nil,
        establishedAt = at,
        source = "relationship_milestone",
    }
    relationship.memories[#relationship.memories + 1] = memory
    while #relationship.memories > Constants.MEMORY_LIMIT do
        table.remove(relationship.memories, 1)
    end
    Internal.appendRecentEvent(social, eventID)
    social.relationships[targetKey] = relationship
    Internal.commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        at,
        { kind = "friendship_established", eventID = eventID, memoryID = eventID }
    )
    return true, "friendship_established", Types.NormalizeRelationship(
        record.social.relationships[targetKey], targetKey
    )
end

function Relationships.SetDurableBond(
    observerNPCID, targetKey, bondSpec, worldAgeHours, source
)
    local record
    local reason
    local social
    local socialChanged
    local relationship
    local desired
    if not Internal.isAuthority() then return false, "not_authority" end
    record, reason = Internal.resolveObserver(observerNPCID)
    if not record then return false, reason end
    targetKey, reason = Internal.validateTarget(targetKey)
    if not targetKey then return false, reason end
    desired = Types.NormalizeBond(bondSpec)
    if desired.class == "none" then return false, "invalid_bond" end
    social, socialChanged = Internal.prepareSocial(record)
    relationship = Internal.getRelationship(record, targetKey)
    relationship = relationship
        and Types.NormalizeRelationship(relationship, targetKey)
        or Types.NewRelationship(targetKey)
    if not relationship then return false, "relationship_unavailable" end
    if relationship.bond.class ~= "none" then
        return false, "bond_already_established"
    end
    desired.establishedAt = now(worldAgeHours)
    desired.source = source or desired.source or "authored_relationship"
    relationship.bond = desired
    social.relationships[targetKey] = relationship
    Internal.commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        desired.establishedAt,
        { kind = "durable_bond_seeded", bondClass = desired.class, bondKind = desired.kind }
    )
    return true, "bond_seeded", Types.NormalizeRelationship(
        record.social.relationships[targetKey], targetKey
    )
end

function Relationships.GetDurableBond(observerNPCID, targetKey)
    local relationship, reason = Relationships.Get(observerNPCID, targetKey)
    if not relationship then return nil, reason end
    return Types.NormalizeBond(relationship.bond)
end

return Relationships
