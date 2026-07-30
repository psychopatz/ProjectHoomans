-- Server-authoritative actor-owned behavioral conduct service.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.Conduct = PNC.Conduct or {}

local Conduct = PNC.Conduct
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function resolve(entityKey)
    local parsed = EntityRef.Parse(entityKey)
    local record
    if not parsed then return nil, "invalid_entity_key" end
    if parsed.kind == "npc" then
        record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(parsed.npcID) or nil
        if not record then return nil, "npc_not_found" end
        return {
            kind = "npc",
            key = entityKey,
            id = parsed.npcID,
            record = record,
            conduct = Types.NormalizeConductRecord(
                record.social and record.social.conduct
            ),
        }
    end
    record = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(
            parsed.characterUUID
        ) or nil
    if not record
        or record.accountIdentity ~= parsed.accountIdentity
    then
        return nil, "player_character_not_found"
    end
    return {
        kind = "player",
        key = entityKey,
        id = parsed.characterUUID,
        record = record,
        conduct = Types.NormalizeConductRecord(record.conduct),
    }
end

local function commit(owner, conduct)
    if owner.kind == "player" then
        return PNC.PlayerCharacters.ApplyConductRecord(
            owner.id,
            conduct
        )
    end
    local record = PNC.Registry.Get(owner.id)
    if not record then return false, "npc_not_found" end
    local social = PNC.RelationshipTypes.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    social.conduct = Types.NormalizeConductRecord(conduct)
    social.revision = math.max(
        tonumber(record.social and record.social.revision) or 0,
        tonumber(social.revision) or 0
    ) + 1
    record.social = social
    PNC.Registry.MarkDirty(record, "social")
    return true, "updated", copy(social.conduct)
end

local function containsID(conduct, evidenceID)
    for _, evidence in ipairs(conduct.evidence or {}) do
        if evidence.id == evidenceID then return true end
    end
    for _, recentID in ipairs(conduct.recentEvidenceIDs or {}) do
        if recentID == evidenceID then return true end
    end
    return false
end

local function appendRecent(conduct, evidenceID)
    conduct.recentEvidenceIDs[#conduct.recentEvidenceIDs + 1] =
        evidenceID
    while #conduct.recentEvidenceIDs
        > Constants.RECENT_EVIDENCE_ID_LIMIT
    do
        table.remove(conduct.recentEvidenceIDs, 1)
    end
end

local function prepareEvidence(entityKey, evidenceSpec)
    local owner
    local reason
    local evidence
    local conduct
    local withinLimit
    owner, reason = resolve(entityKey)
    if not owner then return nil, reason end
    evidence = Types.NewConductEvidence(evidenceSpec)
    if not evidence or evidence.actorKey ~= entityKey then
        return nil, "invalid_evidence"
    end
    conduct = Types.NormalizeConductRecord(owner.conduct)
    if containsID(conduct, evidence.id) then
        return nil, "duplicate_evidence_id"
    end
    conduct.evidence[#conduct.evidence + 1] = evidence
    conduct, _, withinLimit = Math.PruneEvidence(
        conduct,
        evidence.createdAt,
        Constants.EVIDENCE_LIMIT
    )
    if not withinLimit then
        return nil, "permanent_evidence_limit"
    end
    local retained = false
    for _, item in ipairs(conduct.evidence) do
        retained = retained or item.id == evidence.id
    end
    if not retained then return nil, "evidence_pruned_by_limit" end
    conduct = Math.Recalculate(conduct, evidence.createdAt)
    appendRecent(conduct, evidence.id)
    conduct.revision = owner.conduct.revision + 1
    return {
        entityKey = entityKey,
        owner = owner,
        before = owner.conduct,
        after = conduct,
        evidenceID = evidence.id,
        evidence = evidence,
    }
end

function Conduct.GetForEntity(entityKey)
    local owner, reason = resolve(entityKey)
    return owner and copy(owner.conduct) or nil, reason
end

function Conduct.GetForNPC(npcID)
    local key = EntityRef.ForNPC(npcID)
    if not key then return nil, "invalid_npc_id" end
    return Conduct.GetForEntity(key)
end

function Conduct.GetForPlayerCharacter(characterUUID)
    local record = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(characterUUID)
        or nil
    if not record then return nil, "character_not_found" end
    local key = EntityRef.ForPlayerIdentity(
        record.accountIdentity,
        record.uuid
    )
    return Conduct.GetForEntity(key)
end

function Conduct.GetScores(entityKey)
    local conduct, reason = Conduct.GetForEntity(entityKey)
    return conduct and copy(conduct.scores) or nil, reason
end

function Conduct.GetScore(entityKey, dimension)
    if not Types.IsValidConductDimension(dimension) then
        return nil, "invalid_dimension"
    end
    local scores, reason = Conduct.GetScores(entityKey)
    return scores and scores[dimension] or nil, reason
end

function Conduct.AddEvidence(entityKey, evidenceSpec)
    local prepared
    local reason
    if not authority() then return false, "not_authority" end
    prepared, reason = prepareEvidence(entityKey, evidenceSpec)
    if not prepared then return false, reason end
    local ok, commitReason, conduct =
        commit(prepared.owner, prepared.after)
    return ok, commitReason, conduct
end

function Conduct.PrepareSocialEvent(event, definition)
    local participants = {}
    local function add(actorKey, subjectKey, role)
        participants[#participants + 1] = {
            actorKey = actorKey,
            subjectKey = subjectKey,
            role = role,
        }
    end
    if type(event) ~= "table" or type(definition) ~= "table" then
        return nil, "invalid_social_event"
    end
    if definition.participants == "actor_and_target" then
        add(event.actorKey, event.targetKey, definition.role)
        add(event.targetKey, event.actorKey, definition.role)
    else
        add(event.actorKey, event.targetKey, definition.role)
    end
    local prepared = {}
    for _, participant in ipairs(participants) do
        local evidenceID = "conduct:" .. event.id .. ":"
            .. participant.actorKey .. ":" .. participant.role
        local item, reason = prepareEvidence(
            participant.actorKey,
            {
                id = evidenceID,
                eventID = event.id,
                eventType = event.type,
                actorKey = participant.actorKey,
                subjectKey = participant.subjectKey,
                createdAt = event.occurredAt,
                lastEvaluatedAt = event.occurredAt,
                effects = definition.effects,
                strength = 1,
                decayPerDay = definition.decayPerDay,
                permanent = definition.permanent == true,
                visibility = definition.visibility,
                shareable = definition.shareable == true,
                tags = definition.tags,
            }
        )
        if not item then return nil, reason end
        prepared[#prepared + 1] = item
    end
    return prepared
end

function Conduct.CommitPrepared(prepared)
    if not authority() then return false, "not_authority" end
    for _, item in ipairs(prepared or {}) do
        local current, reason = Conduct.GetForEntity(item.entityKey)
        if not current then return false, reason end
        if not Types.AreEqual(current, item.before) then
            return false, "conduct_changed_during_event"
        end
    end
    local details = {}
    for _, item in ipairs(prepared or {}) do
        local ok, reason, conduct = commit(item.owner, item.after)
        if not ok then return false, reason end
        details[#details + 1] = {
            entityKey = item.entityKey,
            evidenceID = item.evidenceID,
            evidence = copy(item.evidence),
            conduct = conduct,
        }
    end
    return true, "applied", details
end

function Conduct.ApplySocialEvent(event, definition)
    local prepared, reason =
        Conduct.PrepareSocialEvent(event, definition)
    if not prepared then return false, reason end
    return Conduct.CommitPrepared(prepared)
end

function Conduct.RemoveEvidence(entityKey, evidenceID)
    local owner, reason = resolve(entityKey)
    local conduct
    local found
    if not authority() then return false, "not_authority" end
    if type(evidenceID) ~= "string" or evidenceID == "" then
        return false, "invalid_evidence_id"
    end
    if not owner then return false, reason end
    conduct = Types.NormalizeConductRecord(owner.conduct)
    for index, evidence in ipairs(conduct.evidence) do
        if evidence.id == evidenceID then
            table.remove(conduct.evidence, index)
            found = true
            break
        end
    end
    if not found then return false, "evidence_not_found" end
    conduct = Math.Recalculate(conduct, conduct.lastEvaluatedAt)
    conduct.revision = owner.conduct.revision + 1
    return commit(owner, conduct)
end

local function recalculate(entityKey, at, prune)
    local owner, reason = resolve(entityKey)
    local conduct
    local changed
    local withinLimit = true
    if not authority() then return false, "not_authority" end
    at = tonumber(at)
    if at == nil or at ~= at or at == math.huge
        or at == -math.huge or at < 0
    then
        return false, "invalid_world_age_hours"
    end
    if not owner then return false, reason end
    conduct = owner.conduct
    if prune then
        conduct, _, withinLimit = Math.PruneEvidence(
            conduct, at, Constants.EVIDENCE_LIMIT
        )
        if not withinLimit then
            return false, "permanent_evidence_limit"
        end
    end
    conduct, changed = Math.Recalculate(conduct, at)
    if not changed
        or Types.AreEqual(owner.conduct, conduct)
    then
        return false, "unchanged", copy(owner.conduct)
    end
    conduct.revision = owner.conduct.revision + 1
    return commit(owner, conduct)
end

function Conduct.Recalculate(entityKey, at)
    return recalculate(entityKey, at, false)
end

function Conduct.PruneEvidence(entityKey, at)
    return recalculate(entityKey, at, true)
end

Conduct.NormalizePlayerConduct = Types.NormalizeConductRecord
Conduct.NormalizeNPCConduct = Types.NormalizeConductRecord

return Conduct
