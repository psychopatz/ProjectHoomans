if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local authority = Internal.authority
local copy = Internal.copy
local assignTable = Internal.assignTable
local rebuildDerivedIndexes = Internal.rebuildDerivedIndexes
local reconcileLeaders = Internal.reconcileLeaders
local reconcileNPCReferences = Internal.reconcileNPCReferences
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"
local ImportSource = PNC.SurvivorWorldImportSource
    or require "PNC/Director/PNC_SurvivorWorldImportSource"

local function refreshCoreViews()
    local extensions = PNC.SurvivorWorldExtensions
    local coreAuthority = PNC.CoreSurvivorWorldAuthority
    local registry = coreAuthority and coreAuthority.Registry
    if not extensions or extensions.Active ~= true
        or type(extensions.RebuildAll) ~= "function"
        or not registry
        or type(registry.Snapshot) ~= "function"
    then
        return false, "cutover_not_active"
    end
    return extensions.RebuildAll(registry:Snapshot())
end

function Communities.Load()
    local raw
    local sourceRaw
    local normalized
    if not authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    if PNC.Factions and PNC.Factions.EnsureLoaded then
        PNC.Factions.EnsureLoaded()
    end
    local refreshed = refreshCoreViews()
    if not refreshed then
        local reason
        raw, reason, sourceRaw = ImportSource.Read("communities")
        normalized = Types.NormalizeRegistry(raw)
        Communities.Registry = normalized
        Communities.Loaded = true
        Communities.Dirty = (reason ~= nil and reason ~= "empty_state")
            or (reason == nil and not Types.AreEqual(raw, normalized))
        if reason ~= nil and reason ~= "empty_state" then
            Reset.Mark(
                Communities,
                sourceRaw,
                Constants.REGISTRY_SCHEMA_VERSION,
                reason,
                "community_world_view_import"
            )
        end
    end
    reconcileNPCReferences()
    rebuildDerivedIndexes()
    reconcileLeaders()
    return true, Communities.Dirty
end

-- Detached semantic runtimes do not carry the complete live NPC registry.
-- Use the production normalizer and preserve the persisted member/leader
-- references; the normal server loader remains responsible for full-world
-- reconciliation once live records are present.
function Communities.LoadRaw(raw)
    if not authority() then return false, "not_authority" end
    Communities.Registry = Types.NormalizeRegistry(raw)
    Communities.Loaded = true
    Communities.Dirty = false
    return true, "loaded_raw"
end

function Communities.EnsureLoaded()
    if not Communities.Loaded then
        return Communities.Load()
    end
    return true
end

function Communities.Commit()
    Communities.EnsureLoaded()
    if not Communities.Dirty then return false, "not_dirty" end
    local extensions = PNC.SurvivorWorldExtensions
    if not extensions or type(extensions.Save) ~= "function" then
        return false, "survivor_world_cutover_unavailable"
    end
    if extensions.Active ~= true then
        return false, "survivor_world_cutover_inactive"
    end
    extensions.MarkDirty("community_view_commit")
    return extensions.Save()
end

function Communities.GenerateID()
    Communities.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Communities.IDGenerator()
        if Types.IsValidCommunityID(candidate)
            and not Communities.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end


return Communities
