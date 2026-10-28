if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

-- Selective semantic read through the conduct owner; never exports its store.
function Conduct.QuerySemanticEvidence(entityKey, subjectKey, actorID, targetID, at, query)
    local Evidence = require "PNC/Semantics/PNC_SemanticInteractionEvidence"
    local time = getGameTime and getGameTime() or nil
    at = tonumber(at) or time and time.getWorldAgeHours and tonumber(time:getWorldAgeHours())
    if not at or at ~= at or at < 0 or at == math.huge or at == -math.huge then return {} end
    local owner = H.Resolve(entityKey)
    local evidence = owner and owner.conduct and owner.conduct.evidence or {}
    local rows = {}
    for index = math.min(#evidence, Constants.EVIDENCE_LIMIT), 1, -1 do
        local item = evidence[index]
        local definition = PNC.SocialEventDefinitions and PNC.SocialEventDefinitions[item.eventType]
        local metadata = definition and definition.semantic
        local strength = Math.CalculateEvidenceStrengthAtTime(item, at)
        if metadata and strength > 0 and item.actorKey == entityKey
            and item.subjectKey == subjectKey and Evidence.MatchesMeaning(metadata, query) then
            rows[#rows + 1] = { sourceRef = item.id, eventType = item.eventType,
                actorID = actorID, targetID = targetID,
                classes = metadata.classes, relations = metadata.relations,
                retentionSalience = metadata.retentionSalience,
                effectiveStrength = strength, occurredAt = item.createdAt,
                ageHours = math.max(0, (tonumber(at) or item.createdAt) - item.createdAt),
                provenance = "conduct.evidence", visibility = item.visibility }
            if #rows >= 16 then break end
        end
    end
    return rows
end

function Conduct.GetForEntity(entityKey)
    local owner, reason = H.Resolve(entityKey)
    return owner and H.Copy(owner.conduct) or nil, reason
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
        record.accountKey or record.accountIdentity,
        record.uuid
    )
    return Conduct.GetForEntity(key)
end

function Conduct.GetScores(entityKey)
    local conduct, reason = Conduct.GetForEntity(entityKey)
    return conduct and H.Copy(conduct.scores) or nil, reason
end

function Conduct.GetScore(entityKey, dimension)
    if not Types.IsValidConductDimension(dimension) then
        return nil, "invalid_dimension"
    end
    local scores, reason = Conduct.GetScores(entityKey)
    return scores and scores[dimension] or nil, reason
end
