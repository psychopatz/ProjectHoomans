if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

function Conduct.AddEvidence(entityKey, evidenceSpec)
    local prepared
    local reason
    if not H.Authority() then return false, "not_authority" end
    prepared, reason = H.PrepareEvidence(entityKey, evidenceSpec)
    if not prepared then return false, reason end
    local ok, commitReason, conduct =
        H.Commit(prepared.owner, prepared.after)
    return ok, commitReason, conduct
end

function Conduct.RemoveEvidence(entityKey, evidenceID)
    local owner, reason = H.Resolve(entityKey)
    local conduct
    local found
    if not H.Authority() then return false, "not_authority" end
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
    return H.Commit(owner, conduct)
end

function H.RecalculateInternal(entityKey, at, prune)
    local owner, reason = H.Resolve(entityKey)
    local conduct
    local changed
    local withinLimit = true
    if not H.Authority() then return false, "not_authority" end
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
        return false, "unchanged", H.Copy(owner.conduct)
    end
    conduct.revision = owner.conduct.revision + 1
    return H.Commit(owner, conduct)
end

function Conduct.Recalculate(entityKey, at)
    return H.RecalculateInternal(entityKey, at, false)
end

function Conduct.PruneEvidence(entityKey, at)
    return H.RecalculateInternal(entityKey, at, true)
end

Conduct.NormalizePlayerConduct = Types.NormalizeConductRecord
Conduct.NormalizeNPCConduct = Types.NormalizeConductRecord
