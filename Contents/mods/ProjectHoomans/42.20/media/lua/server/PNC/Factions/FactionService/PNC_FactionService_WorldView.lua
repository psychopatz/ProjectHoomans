if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef

local function refreshCoreViews()
    local extensions = PNC.SurvivorWorldExtensions
    local authority = PNC.CoreSurvivorWorldAuthority
    local registry = authority and authority.Registry
    if not extensions or extensions.Active ~= true
        or type(extensions.RebuildAll) ~= "function"
        or not registry
        or type(registry.Snapshot) ~= "function"
    then
        return false, "cutover_not_active"
    end
    return extensions.RebuildAll(registry:Snapshot())
end

local function cutoverPending()
    local extensions = PNC.SurvivorWorldExtensions
    return extensions ~= nil
        and extensions.Active ~= true
        and type(extensions.ActivateCutover) == "function"
end

function Factions.ReconcileLoadedView(reason, canonicalMembership)
    local changed
    if not Internal.authority() then return false, "not_authority" end
    if not Factions.Loaded then return false, "not_loaded" end

    changed = Internal.rebuildIndexes(canonicalMembership)
    if Factions.ReconcilePlayerMemberships then
        Factions.ReconcilePlayerMemberships(
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
        )
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileAll
    then
        PNC.FactionBehavior.ReconcileAll(reason or "view_reconcile")
    end
    if PNC.ProvisionScheduler then
        for factionID in pairs(Factions.Registry.byID or {}) do
            PNC.ProvisionScheduler.MarkFactionDirty(factionID)
        end
    end
    Factions.Ready = true
    Factions.LoadDeferred = nil
    Factions.LastLoadReason = reason
    return true, changed == true
end

function Factions.Load()
    if not Internal.authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    local refreshed, refreshReason = refreshCoreViews()
    if not refreshed and refreshReason ~= "cutover_not_active" then
        return false, refreshReason
    end
    if not refreshed then
        Factions.Registry = Types.NormalizeFactionRegistry(nil)
        Factions.Loaded = true
        Factions.Dirty = false
        if cutoverPending() then
            Factions.Ready = false
            Factions.LoadDeferred = true
            Factions.LastLoadReason = "cutover_pending"
            return true, false
        end
        return Factions.ReconcileLoadedView("registry_load")
    end
    return true, Factions.Dirty
end

-- Detached semantic runtimes transport the persisted registry directly and
-- do not have the complete live NPC registry available for the normal
-- world-load reconciliation pass.  Keep normalization and ownership here,
-- while preserving the saved membership/index state until live records are
-- available to the normal server lifecycle.
function Factions.LoadRaw(raw)
    if not Internal.authority() then return false, "not_authority" end
    Factions.Registry = Types.NormalizeFactionRegistry(raw)
    Factions.Loaded = true
    Factions.Ready = true
    Factions.LoadDeferred = nil
    Factions.Dirty = false
    return true, "loaded_raw"
end

function Factions.EnsureLoaded()
    if not Factions.Loaded then return Factions.Load() end
    return true
end

function Factions.Commit()
    Factions.EnsureLoaded()
    if not Factions.Dirty then return false, "not_dirty" end
    local extensions = PNC.SurvivorWorldExtensions
    if not extensions or type(extensions.Save) ~= "function" then
        return false, "survivor_world_cutover_unavailable"
    end
    if extensions.Active ~= true then
        return false, "survivor_world_cutover_inactive"
    end
    extensions.MarkDirty("faction_view_commit")
    return extensions.Save()
end

function Factions.RebuildIndexes()
    Factions.EnsureLoaded()
    return Internal.rebuildIndexes()
end

function Factions.GenerateID()
    Factions.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Factions.IDGenerator()
        if Types.IsValidFactionID(candidate)
            and not Factions.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end

return Factions
