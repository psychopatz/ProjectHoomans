if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

function H.ContainsID(conduct, evidenceID)
    for _, evidence in ipairs(conduct.evidence or {}) do
        if evidence.id == evidenceID then return true end
    end
    for _, recentID in ipairs(conduct.recentEvidenceIDs or {}) do
        if recentID == evidenceID then return true end
    end
    return false
end

function H.AppendRecent(conduct, evidenceID)
    conduct.recentEvidenceIDs[#conduct.recentEvidenceIDs + 1] =
        evidenceID
    while #conduct.recentEvidenceIDs
        > Constants.RECENT_EVIDENCE_ID_LIMIT
    do
        table.remove(conduct.recentEvidenceIDs, 1)
    end
end

function H.PrepareEvidence(entityKey, evidenceSpec)
    local owner
    local reason
    local evidence
    local conduct
    local withinLimit
    owner, reason = H.Resolve(entityKey)
    if not owner then return nil, reason end
    evidence = Types.NewConductEvidence(evidenceSpec)
    if not evidence or evidence.actorKey ~= entityKey then
        return nil, "invalid_evidence"
    end
    conduct = Types.NormalizeConductRecord(owner.conduct)
    if H.ContainsID(conduct, evidence.id) then
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
    H.AppendRecent(conduct, evidence.id)
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
