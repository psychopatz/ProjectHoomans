if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal
local ImportSource = PNC.SurvivorWorldImportSource
    or require "PNC/Director/PNC_SurvivorWorldImportSource"

local IMPORT_KINDS = {
    "factions",
    "communities",
    "abstractWorld",
}

local function hasImportSources()
    for _, kind in ipairs(IMPORT_KINDS) do
        if ImportSource.HasData(kind) then return true end
    end
    return false
end

local function currentCore()
    local adapter = PNC.CoreSurvivorWorldAdapter
    if adapter and adapter.EnsureCanonical then
        return adapter.EnsureCanonical()
    end
    local authority = PNC.CoreSurvivorWorldAuthority
    if authority and authority.Registry then
        return authority.Registry
    end
    if authority and authority.Activate then
        return authority.Activate()
    end
    return nil, "core_survivor_world_unavailable"
end

function Extensions.CaptureAll()
    local factions = Extensions.CaptureFactions()
    local communities, sites =
        Extensions.CaptureCommunities()
    local groups, locations, abstract =
        Extensions.CaptureAbstract()

    return {
        schemaVersion = Extensions.SCHEMA_VERSION,
        revision = math.max(
            0,
            tonumber(
                Extensions.Registry
                    and Extensions.Registry.revision
            ) or 0
        ),
        factions = factions,
        communities = communities,
        sitesByID = sites,
        groups = groups,
        locations = locations,
        abstract = abstract,
    }
end

function Extensions.RebuildAll(coreSnapshot)
    if type(coreSnapshot) ~= "table" then
        return false, "core_survivor_world_snapshot_required"
    end
    if not PNC.Factions
        or not PNC.Communities
        or not PNC.HoomansWorldView
    then
        return false, "pnc_world_views_unavailable"
    end

    local factions = Extensions.RebuildFactions(coreSnapshot)
    local communities =
        Extensions.RebuildCommunities(coreSnapshot)
    local abstract = Extensions.RebuildAbstract(coreSnapshot)

    if type(factions) ~= "table"
        or type(communities) ~= "table"
        or type(abstract) ~= "table"
    then
        return false, "pnc_world_view_rebuild_failed"
    end

    PNC.Factions.Registry = factions
    PNC.Communities.Registry = communities
    PNC.HoomansWorldView.Registry = abstract

    PNC.Factions.Loaded = true
    PNC.Factions.Dirty = false
    PNC.Communities.Loaded = true
    PNC.Communities.Dirty = false
    PNC.HoomansWorldView.Loaded = true
    PNC.HoomansWorldView.Dirty = false

    -- Faction and community loaders may have run before this callback. They
    -- intentionally defer NPC-affiliation reconciliation while the canonical
    -- Core view is unavailable, so finalize those indexes only after all
    -- authoritative views have been installed.
    if PNC.Communities
        and type(PNC.Communities.ReconcileLoadedView) == "function"
    then
        local reconciled, reason =
            PNC.Communities.ReconcileLoadedView(
                "survivor_world_cutover"
            )
        if not reconciled then return false, reason end
    end
    if PNC.Factions
        and type(PNC.Factions.ReconcileLoadedView) == "function"
    then
        local reconciled, reason =
            PNC.Factions.ReconcileLoadedView(
                "survivor_world_cutover"
            )
        if not reconciled then return false, reason end
    end

    if PNC.AbstractLocations
        and PNC.AbstractLocations.RebuildIndex
    then
        PNC.AbstractLocations.RebuildIndex()
    end

    return true
end

local function retireImportSources()
    for _, kind in ipairs(IMPORT_KINDS) do
        if ImportSource.HasData(kind) then
            local retired, reason = ImportSource.Retire(kind)
            if not retired
                and reason ~= "already_empty"
            then
                return false, reason
            end
        end
    end
    return true
end

function Extensions.ActivateCutover()
    if Extensions.Activating then
        return false, "survivor_world_cutover_reentrant"
    end
    if Extensions.Active then
        return true, "already_active"
    end

    Extensions.Activating = true

    local core, reason = currentCore()
    if not core then
        Extensions.Activating = false
        return false, reason
    end

    local loaded = Extensions.Load()
    local importPresent = hasImportSources()

    -- The first cutover captures only Hoomans-owned extension state while
    -- pre-SurvivorWorld import sources still contain the complete old view.
    -- Existing extension roots are authoritative on later loads and must not
    -- be replaced from retired import sources.
    if loaded ~= true then
        Extensions.Registry = Extensions.CaptureAll()
        Extensions.Dirty = true
    end

    Extensions.Active = true

    -- Persist Core first, then the Hoomans-only extension root. Import sources
    -- are retired only after both durable targets are safe.
    if importPresent or Extensions.Dirty then
        local saved
        saved, reason = Extensions.Save()
        if not saved and reason ~= "not_dirty" then
            Extensions.Active = false
            Extensions.Activating = false
            return false, reason
        end
    else
        local coreOK
        coreOK, reason = Extensions.FlushCore()
        if not coreOK then
            Extensions.Active = false
            Extensions.Activating = false
            return false, reason
        end
    end

    local snapshot = core:Snapshot()
    local rebuilt
    rebuilt, reason = Extensions.RebuildAll(snapshot)
    if not rebuilt then
        Extensions.Active = false
        Extensions.Activating = false
        return false, reason
    end

    local retired
    retired, reason = retireImportSources()
    if not retired then
        Extensions.Active = false
        Extensions.Activating = false
        return false, reason
    end

    Extensions.Activating = false
    Extensions.LastCutover = {
        accepted = true,
        coreRevision = core:Revision(),
        extensionRevision =
            tonumber(Extensions.Registry.revision) or 0,
        importedPreSurvivorWorld = importPresent == true,
    }
    return true, importPresent
        and "import_cutover_complete"
        or "cutover_active"
end

function Extensions.RefreshFromCore()
    if not Extensions.Active then
        return false, "extensions_not_active"
    end
    local core, reason = currentCore()
    if not core then return false, reason end
    return Extensions.RebuildAll(core:Snapshot())
end

local function onInitGlobalModData()
    Extensions.ActivateCutover()
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
    and not Extensions.CutoverHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Extensions.CutoverHookRegistered = true
end

return Extensions
