-- Public player identity migration workflow.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Migration = PNC.PlayerIdentityMigration
local Internal = Migration.Internal
local Characters = PNC.PlayerCharacters
local Types = PNC.PlayerCharacterTypes
local Constants = PNC.PlayerCharacterConstants
local EntityRef = PNC.EntityRef
local atNow = Internal.AtNow
local collectCandidates = Internal.CollectCandidates
local chooseCanonical = Internal.ChooseCanonical
local mergeRelationships = Internal.MergeRelationships
local mergeKnowledge = Internal.MergeKnowledge
local mergeConduct = Internal.MergeConduct
local mergeFactions = Internal.MergeFactions
local backupOnce = Internal.BackupOnce

function Migration.RunForPlayer(player, accountKey, at)
    Characters.EnsureLoaded()
    local state = Characters.Registry.migration or {}
    if state.status == "complete" then
        return state.canonicalUUID, "already_migrated"
    end
    if type(accountKey) ~= "string"
        or string.sub(accountKey, 1, 8) ~= "sp_slot_"
    then
        return nil, "not_singleplayer"
    end
    if PNC.NPCKnowledge and PNC.NPCKnowledge.EnsureLoaded then
        PNC.NPCKnowledge.EnsureLoaded()
    end
    if PNC.Factions and PNC.Factions.EnsureLoaded then PNC.Factions.EnsureLoaded() end

    local candidates = collectCandidates(player)
    if #candidates == 0 then
        local active = 0
        for _, record in pairs(Characters.Registry.byUUID or {}) do
            if record.status == Constants.STATUS_ACTIVE then active = active + 1 end
        end
        if active > 0 then
            state.status = "ambiguous"
            state.diagnostic = "active_survivor_descriptor_conflict"
            state.revision = (tonumber(state.revision) or 0) + 1
            Characters.Registry.migration = state
            Characters.Dirty = true
            return nil, "identity_ambiguous"
        end
        return nil, "no_legacy_candidate"
    end
    local canonical, selectedBy = chooseCanonical(player, candidates)
    if not canonical then
        state.status = "ambiguous"
        state.diagnostic = "no_safe_canonical_candidate"
        Characters.Registry.migration = state
        Characters.Dirty = true
        return nil, "identity_ambiguous"
    end
    backupOnce(candidates)
    local canonicalKey = EntityRef.ForPlayerIdentity(accountKey, canonical.uuid)
    local oldKeys = mergeRelationships(
        canonicalKey, candidates, atNow(at)
    ) or {}
    mergeKnowledge(canonical, candidates)
    mergeConduct(canonical, candidates, canonicalKey, oldKeys, atNow(at))
    mergeFactions(canonicalKey, oldKeys)

    canonical.accountKey = accountKey
    canonical.accountIdentity = accountKey
    canonical.legacyAccountIdentities = canonical.legacyAccountIdentities or {}
    for _, record in ipairs(candidates) do
        canonical.legacyAccountIdentities[record.accountIdentity] = true
        canonical.legacyAccountIdentities[record.accountKey] = true
        if record.uuid ~= canonical.uuid then
            record.status = Constants.STATUS_RETIRED
            record.retiredAt = atNow(at)
            record.supersededBy = canonical.uuid
            record.revision = (tonumber(record.revision) or 0) + 1
            Characters.Registry.uuidAliases[record.uuid] = canonical.uuid
        end
    end
    canonical.revision = (tonumber(canonical.revision) or 0) + 1
    Characters.Registry.revision = (tonumber(Characters.Registry.revision) or 0) + 1
    Characters.Registry.migration = {
        revision = (tonumber(state.revision) or 0) + 1,
        status = "complete",
        completedAt = atNow(at),
        canonicalUUID = canonical.uuid,
        diagnostic = "merged_" .. tostring(#candidates)
            .. "_selected_by_" .. selectedBy,
    }
    Characters.Registry = Types.NormalizeRegistry(Characters.Registry)
    Characters.Dirty = true
    if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
        local committed, reason = PNC.PersistenceCoordinator.Commit(
            "identity_v4_migration"
        )
        if not committed then return nil, reason end
    end
    return canonical.uuid, "migrated"
end

return Migration
