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

local function countMap(value)
    local count = 0
    for _ in pairs(type(value) == "table" and value or {}) do
        count = count + 1
    end
    return count
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
    local status = {
        active = true,
        core = snapshotCounts(coreSnapshot),
        coreEmpty = isEmpty(coreSnapshot),
    }
    Authority.LastStatus = status
    return status
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
