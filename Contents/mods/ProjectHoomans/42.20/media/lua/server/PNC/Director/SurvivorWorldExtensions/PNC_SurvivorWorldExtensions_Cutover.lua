if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal

local function legacyKeys()
    return {
        PNC.FactionConstants
            and PNC.FactionConstants.REGISTRY_MODDATA_KEY,
        PNC.CommunityConstants
            and PNC.CommunityConstants.REGISTRY_MODDATA_KEY,
        PNC.DirectorConfig
            and PNC.DirectorConfig.MODDATA_KEY,
    }
end

local function hasLegacyRoots()
    for _, key in ipairs(legacyKeys()) do
        if key and Extensions.LegacyRootHasData(key) then
            return true
        end
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
        or not PNC.AbstractWorldStore
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
    PNC.AbstractWorldStore.Registry = abstract

    PNC.Factions.Loaded = true
    PNC.Factions.Dirty = false
    PNC.Communities.Loaded = true
    PNC.Communities.Dirty = false
    PNC.AbstractWorldStore.Loaded = true
    PNC.AbstractWorldStore.Dirty = false

    if PNC.AbstractLocations
        and PNC.AbstractLocations.RebuildIndex
    then
        PNC.AbstractLocations.RebuildIndex()
    end

    return true
end

local function retireLegacyRoots()
    for _, key in ipairs(legacyKeys()) do
        if key and Extensions.LegacyRootHasData(key) then
            local retired, reason =
                Extensions.RetireLegacyRoot(key)
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
    local legacyPresent = hasLegacyRoots()

    -- The first cutover captures only Hoomans-owned extension state while
    -- legacy PNC registries still contain the complete pre-cutover view.
    -- Existing extension roots are authoritative on later loads and must not
    -- be replaced from the now-retired legacy generic stores.
    if loaded ~= true then
        Extensions.Registry = Extensions.CaptureAll()
        Extensions.Dirty = true
    end

    Extensions.Active = true

    -- Persist Core first, then the Hoomans-only extension root. Legacy generic
    -- roots are retired only after both durable targets are safe.
    if legacyPresent or Extensions.Dirty then
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
    retired, reason = retireLegacyRoots()
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
        migratedLegacy = legacyPresent == true,
    }
    return true, legacyPresent
        and "legacy_cutover_complete"
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
