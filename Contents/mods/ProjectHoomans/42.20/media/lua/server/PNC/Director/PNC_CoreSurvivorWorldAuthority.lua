if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreSurvivorWorldAuthority =
    PNC.CoreSurvivorWorldAuthority or {}

local Authority = PNC.CoreSurvivorWorldAuthority
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local ImportSource = PNC.SurvivorWorldImportSource
    or require "PNC/Director/PNC_SurvivorWorldImportSource"

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[copy(key)] = copy(child)
    end
    return output
end

local function countMap(value)
    local count = 0
    for _ in pairs(type(value) == "table" and value or {}) do
        count = count + 1
    end
    return count
end

function Authority.BuildImportSource()
    return copy(ImportSource.Build())
end

function Authority.PreviewImport(options)
    local source = Authority.BuildImportSource()
    local snapshot, reason =
        World.Import.FromPNC(source, options)
    if not snapshot then return nil, reason end
    return snapshot, source
end

local function snapshotCounts(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    return {
        factions = countMap(snapshot.factions),
        communities = countMap(snapshot.communities),
        locations = countMap(snapshot.locations),
        groups = countMap(snapshot.groups),
        discoveryPlayers = countMap(
            snapshot.discovery and snapshot.discovery.players
        ),
    }
end

local function isEmpty(snapshot)
    local counts = snapshotCounts(snapshot)
    return counts.factions == 0
        and counts.communities == 0
        and counts.locations == 0
        and counts.groups == 0
        and counts.discoveryPlayers == 0
end

function Authority.Activate()
    local registry, reason = World.ActivateRuntime()
    if not registry then return nil, reason end
    Authority.Registry = registry
    return registry
end

function Authority.RefreshStatus()
    local registry, reason = Authority.Activate()
    if not registry then
        Authority.LastStatus = {
            active = false,
            reason = reason,
        }
        return Authority.LastStatus
    end

    local coreSnapshot = registry:Snapshot()
    local preview, previewReason = Authority.PreviewImport()
    local status = {
        active = true,
        core = snapshotCounts(coreSnapshot),
        coreEmpty = isEmpty(coreSnapshot),
        previewReason = previewReason,
    }
    if preview then
        status.importSource = snapshotCounts(preview)
        status.importSourceEmpty = isEmpty(preview)
        status.needsImport =
            status.coreEmpty and not status.importSourceEmpty
    else
        status.importSource = {}
        status.importSourceEmpty = true
        status.needsImport = false
    end
    Authority.LastStatus = status
    return status
end

function Authority.ImportPreSurvivorWorld(options)
    options = type(options) == "table" and options or {}
    local registry, reason = Authority.Activate()
    if not registry then return nil, reason end

    local current = registry:Snapshot()
    if not isEmpty(current) and options.force ~= true then
        return nil, "core_survivor_world_not_empty"
    end

    local snapshot
    snapshot, reason = Authority.PreviewImport(options)
    if not snapshot then return nil, reason end

    registry, reason = World.RuntimeStore.Replace(
        snapshot,
        options.reason or "project_hoomans_pre_survivor_world_import"
    )
    if not registry then return nil, reason end

    local saved
    saved, reason = World.RuntimeStore.Save()
    if not saved and reason ~= "not_dirty" then
        return nil, reason
    end

    Authority.Registry = registry
    Authority.LastImport = {
        accepted = true,
        revision = registry:Revision(),
        counts = snapshotCounts(snapshot),
    }
    Authority.RefreshStatus()
    return registry, "imported"
end

Authority.World = World
Authority.SnapshotCounts = snapshotCounts
Authority.IsEmpty = isEmpty

local registry, activationReason = Authority.Activate()
if not registry then
    Authority.LastStatus = {
        active = false,
        reason = activationReason,
    }
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
then
    Events.OnInitGlobalModData.Add(function()
        Authority.RefreshStatus()
    end)
end

return Authority
