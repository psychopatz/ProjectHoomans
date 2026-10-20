-- Sparse conversation commitments remain part of the NPC Knowledge journal.
-- They are admitted only after the conversation authority has recorded a
-- successful acknowledgement outcome; a player assertion is never enough.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

local Knowledge = PNC.NPCKnowledge
local Internal = Knowledge.Internal
local Registry = PNC.Registry
local Core = PNC.Core
local safeString = Internal.safeString
local deepCopy = Internal.deepCopy
local now = Internal.now

local MAX_FACT_REFS = 8
local MAX_COMMITMENTS = 16
local MAX_COMMITMENT_TEXT = 160

local function boundedText(value)
    return safeString(value, MAX_COMMITMENT_TEXT)
end

local function factReferenceKnown(reference, acknowledgementEventID, spec, npcID)
    if reference == "conversation:" .. tostring(acknowledgementEventID or "") then
        return true
    end
    local subject, targetID = string.match(
        reference, "^cognition:([^:]+):(.+)$"
    )
    if subject and targetID
        and PNC.Semantics and PNC.Semantics.CognitionService
        and type(PNC.Semantics.CognitionService.GetFact) == "function"
    then
        local ok, fact = pcall(
            PNC.Semantics.CognitionService.GetFact,
            npcID, subject, targetID
        )
        return ok and type(fact) == "table" and fact.status == "known"
            and fact.value ~= nil
    end
    if spec and spec.questInstanceID
        and reference == "quest:" .. tostring(spec.questInstanceID)
    then
        return true
    end
    return false
end

local function factRefs(value, acknowledgementEventID, spec, npcID)
    local output = {}
    local seen = {}
    local index
    if type(value) ~= "table" then
        return nil, "commitment_evidence_required"
    end
    for index = 1, math.min(#value, MAX_FACT_REFS) do
        local reference = safeString(value[index], 128)
        if not reference then
            return nil, "invalid_commitment_fact_ref"
        end
        if not factReferenceKnown(
            reference, acknowledgementEventID, spec, npcID
        ) then
            return nil, "commitment_evidence_unknown"
        end
        if not seen[reference] then
            seen[reference] = true
            output[#output + 1] = reference
        end
    end
    if #output == 0 then return nil, "commitment_evidence_required" end
    return output
end

local function commitmentFromEntry(entry, characterUUID, npcID)
    local params = entry and entry.params or nil
    if entry and entry.type == "conversation_commitment"
        and type(params) == "table"
        and tostring(params.ownerNPCID or "") == tostring(npcID)
        and tostring(params.targetCharacterUUID or "")
            == tostring(characterUUID)
    then
        local output = deepCopy(params)
        local expiresAt = tonumber(output.expiresAt)
        local expired = expiresAt and expiresAt <= now() or false
        output.commitmentID = output.commitmentID or entry.id
        output.memoryID = entry.id
        output.createdAt = entry.createdAt
        output.sourceEventID = entry.sourceEventID
            or output.acknowledgementEventID
        output.authoritative = output.status == "acknowledged"
            and not expired
        if expired then output.status = "expired" end
        return output
    end
    return nil
end

local function existingCommitment(characterUUID, npcID, commitmentID)
    local note = Knowledge.Get(characterUUID, npcID)
    local entries = note and note.journalEntries or {}
    local index
    for index = #entries, 1, -1 do
        local commitment = commitmentFromEntry(
            entries[index], characterUUID, npcID
        )
        if commitment
            and tostring(commitment.commitmentID or "")
                == tostring(commitmentID)
        then
            return commitment
        end
    end
    return nil
end

function Knowledge.RecordConversationCommitment(spec)
    spec = type(spec) == "table" and spec or {}
    local characterUUID = safeString(spec.characterUUID, 128)
    local npcID = safeString(spec.npcID, 128)
    local commitmentID = safeString(spec.commitmentID, 128)
    local topic = boundedText(spec.topic)
    local intent = boundedText(spec.intent)
    local acknowledgementEventID = safeString(
        spec.acknowledgementEventID, 128
    )
    local acknowledgementOutcomeID = safeString(
        spec.acknowledgementOutcomeID, 128
    )
    local acknowledgedBy = safeString(spec.acknowledgedBy, 128)
    local sourceFactRefs
    local record
    local existing
    local reason
    local entryID
    local written

    if not characterUUID or not npcID then
        return nil, "invalid_commitment_identity"
    end
    if not commitmentID or not topic or not intent then
        return nil, "invalid_commitment"
    end
    if spec.acknowledged ~= true then
        return nil, "commitment_not_acknowledged"
    end
    if not acknowledgementEventID then
        return nil, "acknowledgement_event_required"
    end
    if not acknowledgedBy or acknowledgedBy ~= npcID then
        return nil, "commitment_owner_mismatch"
    end
    sourceFactRefs, reason = factRefs(
        spec.sourceFactRefs, acknowledgementEventID, spec, npcID
    )
    if not sourceFactRefs then return nil, reason end
    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end

    existing = existingCommitment(characterUUID, npcID, commitmentID)
    if existing then
        return existing, "already_recorded"
    end

    -- The acknowledgement ID is already authoritative and replay-safe. Keep
    -- the journal key deterministic so the headless worker does not need an
    -- engine RNG and a repeated outcome cannot create a second commitment.
    entryID = "conversation_commitment:" .. tostring(commitmentID)
    written, reason = Knowledge.RecordJournal(
        characterUUID,
        npcID,
        {
            id = entryID,
            type = "conversation_commitment",
            sourceEventID = acknowledgementEventID,
            params = {
                commitmentID = commitmentID,
                ownerNPCID = npcID,
                targetCharacterUUID = characterUUID,
                topic = topic,
                intent = intent,
                sourceFactRefs = sourceFactRefs,
                acknowledged = true,
                acknowledgedBy = acknowledgedBy,
                acknowledgementEventID = acknowledgementEventID,
                acknowledgementOutcomeID = acknowledgementOutcomeID,
                questID = safeString(spec.questID, 128),
                questInstanceID = safeString(spec.questInstanceID, 128),
                expiresAt = tonumber(spec.expiresAt),
                status = "acknowledged",
                owner = "npc_knowledge_journal",
            },
        }
    )
    if written ~= true then return nil, reason or "commitment_write_failed" end

    return existingCommitment(characterUUID, npcID, commitmentID)
        or {
            commitmentID = commitmentID,
            ownerNPCID = npcID,
            targetCharacterUUID = characterUUID,
            topic = topic,
            intent = intent,
            sourceFactRefs = sourceFactRefs,
            acknowledged = true,
            acknowledgedBy = acknowledgedBy,
            acknowledgementEventID = acknowledgementEventID,
            acknowledgementOutcomeID = acknowledgementOutcomeID,
            questID = safeString(spec.questID, 128),
            questInstanceID = safeString(spec.questInstanceID, 128),
            expiresAt = tonumber(spec.expiresAt),
            status = "acknowledged",
            authoritative = true,
        }, "recorded"
end

function Knowledge.GetConversationCommitments(characterUUID, npcID, limit)
    local note = Knowledge.Get(characterUUID, npcID)
    local entries = note and note.journalEntries or {}
    local output = {}
    local maximum = math.max(
        1, math.min(MAX_COMMITMENTS, math.floor(tonumber(limit) or 8))
    )
    local index
    local commitment
    for index = #entries, 1, -1 do
        commitment = commitmentFromEntry(
            entries[index], characterUUID, npcID
        )
        if commitment then
            output[#output + 1] = commitment
            if #output >= maximum then break end
        end
    end
    return output
end

Internal.MAX_COMMITMENT_FACT_REFS = MAX_FACT_REFS
Internal.MAX_CONVERSATION_COMMITMENTS = MAX_COMMITMENTS

return Knowledge
