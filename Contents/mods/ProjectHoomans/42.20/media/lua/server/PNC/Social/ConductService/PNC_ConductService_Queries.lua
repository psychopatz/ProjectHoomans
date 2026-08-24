if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

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
