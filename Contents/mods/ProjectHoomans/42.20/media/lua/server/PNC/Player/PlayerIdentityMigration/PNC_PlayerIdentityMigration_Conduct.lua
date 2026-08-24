-- Conduct and companion-state merge for player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local copy = Internal.Copy
local mergeListByID = Internal.MergeListByID
local replaceKey = Internal.ReplaceKey

local function mergeConduct(canonical, candidates, canonicalKey, oldKeys, at)
    local merged = copy(canonical.conduct or {})
    merged.evidence = merged.evidence or {}
    local selectedProfile = canonical.socialProfile
    local startingState = PNC.PlayerCharacterTypes
        .NormalizeStartingCompanionState(canonical.startingCompanions)
    for _, record in ipairs(candidates) do
        local candidateState = PNC.PlayerCharacterTypes
            .NormalizeStartingCompanionState(record.startingCompanions)
        startingState.resolved = startingState.resolved
            or candidateState.resolved
        for traitID, grant in pairs(candidateState.grants or {}) do
            local existing = startingState.grants[traitID]
            local prefer = not existing
                or existing.status ~= "granted" and grant.status == "granted"
                or (tonumber(grant.enrichmentVersion) or 0)
                    > (tonumber(existing and existing.enrichmentVersion) or 0)
            if prefer then startingState.grants[traitID] = copy(grant) end
        end
        merged.evidence = mergeListByID(
            merged.evidence, record.conduct and record.conduct.evidence
        )
        local recentSet = {}
        for _, id in ipairs(merged.recentEvidenceIDs or {}) do
            recentSet[tostring(id)] = true
        end
        for _, id in ipairs(record.conduct
            and record.conduct.recentEvidenceIDs or {}) do
            recentSet[tostring(id)] = true
        end
        merged.recentEvidenceIDs = {}
        for id in pairs(recentSet) do
            merged.recentEvidenceIDs[#merged.recentEvidenceIDs + 1] = id
        end
        table.sort(merged.recentEvidenceIDs)
        merged.revision = math.max(
            tonumber(merged.revision) or 0,
            tonumber(record.conduct and record.conduct.revision) or 0
        )
        if record.socialProfile and (
            not selectedProfile
            or (tonumber(record.socialProfile.revision) or 0)
                > (tonumber(selectedProfile.revision) or 0)
        ) then
            selectedProfile = record.socialProfile
        end
    end
    for _, evidence in ipairs(merged.evidence) do
        evidence.actorKey = replaceKey(
            evidence.actorKey, oldKeys, canonicalKey
        )
        evidence.subjectKey = replaceKey(
            evidence.subjectKey, oldKeys, canonicalKey
        )
    end
    if PNC.ConductMath and PNC.ConductMath.Recalculate then
        merged = PNC.ConductMath.Recalculate(merged, at) or merged
    end
    canonical.conduct = merged
    canonical.socialProfile = copy(selectedProfile)
    canonical.startingCompanions = startingState
end

Internal.MergeConduct = mergeConduct

return Internal
