if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal

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

local function mergeExtensionMap(target, source)
    target = type(target) == "table" and target or {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        target[key] = value
    end
    return target
end

local function preserveDirtyLiveExtensions()
    Extensions.Registry = type(Extensions.Registry) == "table"
        and Extensions.Registry or Extensions.NewRegistry()
    local preserved = false
    if PNC.Factions and PNC.Factions.Loaded == true
        and PNC.Factions.Dirty == true
        and type(Extensions.CaptureFactions) == "function"
    then
        Extensions.Registry.factions = mergeExtensionMap(
            Extensions.Registry.factions,
            Extensions.CaptureFactions()
        )
        preserved = true
    end
    if PNC.Communities and PNC.Communities.Loaded == true
        and PNC.Communities.Dirty == true
        and type(Extensions.CaptureCommunities) == "function"
    then
        local communities, sites = Extensions.CaptureCommunities()
        Extensions.Registry.communities = mergeExtensionMap(
            Extensions.Registry.communities,
            communities
        )
        Extensions.Registry.sitesByID = mergeExtensionMap(
            Extensions.Registry.sitesByID,
            sites
        )
        preserved = true
    end
    if PNC.HoomansWorldView and PNC.HoomansWorldView.Loaded == true
        and PNC.HoomansWorldView.Dirty == true
        and type(Extensions.CaptureAbstract) == "function"
    then
        local groups, locations, abstract = Extensions.CaptureAbstract()
        Extensions.Registry.groups = mergeExtensionMap(
            Extensions.Registry.groups,
            groups
        )
        Extensions.Registry.locations = mergeExtensionMap(
            Extensions.Registry.locations,
            locations
        )
        if type(abstract) == "table" then
            Extensions.Registry.abstract = abstract
        end
        preserved = true
    end
    if preserved then
        Extensions.Dirty = true
    end
    return preserved
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

    -- Capture any unsaved Hoomans-only extension state (such as a newly
    -- created player faction's ownerPlayerKey/playerMemberKeys) before
    -- rebuilding views from Core so mid-session reloads never drop it.
    preserveDirtyLiveExtensions()

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
                "survivor_world_cutover", true
            )
        if not reconciled then return false, reason end
    end
    if PNC.Factions
        and type(PNC.Factions.ReconcileLoadedView) == "function"
    then
        local reconciled, reason =
            PNC.Factions.ReconcileLoadedView(
                "survivor_world_cutover", true
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

    if loaded ~= true then
        Extensions.Registry = Extensions.CaptureAll()
        Extensions.Dirty = true
    end

    Extensions.Active = true

    if Extensions.Dirty then
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

    Extensions.Activating = false
    Extensions.LastCutover = {
        accepted = true,
        coreRevision = core:Revision(),
        extensionRevision =
            tonumber(Extensions.Registry.revision) or 0,
    }
    return true, "cutover_active"
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
