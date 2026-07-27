-- Read-only lifecycle diagnostics used by server and client debug surfaces.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Lifecycle.BuildDiagnostics(record)
    local state
    local body
    local bite
    local diagnosticBodyState
    if not record then
        return nil
    end
    state = Internal.ensureRuntime(record)
    body = Internal.registry() and Internal.registry().GetLiveZombie
        and Internal.registry().GetLiveZombie(record.id) or nil
    bite = record.runtime and record.runtime.lastZombieBite or nil
    diagnosticBodyState = state.bodyState
    if record.presenceState == Const.PRESENCE_CORPSE then
        diagnosticBodyState = state.corpseState == "inert_loaded" and "corpse-loaded" or "corpse-missing"
    end
    return {
        id = tostring(record.id),
        name = record.name,
        faction = record.faction,
        presenceState = record.presenceState,
        alive = record.alive ~= false,
        phase = state.phase,
        bodyState = diagnosticBodyState,
        bodyLease = record.runtime and record.runtime.bodyLease or nil,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyInstanceID = record.liveBodyInstanceID,
        x = record.x,
        y = record.y,
        z = record.z,
        lastReason = state.lastReason,
        lastTransitionAt = state.lastTransitionAt,
        lastAuditAt = state.lastAuditAt,
        lastError = state.lastError,
        lastCleanupState = state.lastCleanupState,
        lastCleanupReason = state.lastCleanupReason,
        lastCleanupAt = state.lastCleanupAt,
        corpseState = state.corpseState,
        corpseToken = record.corpse and record.corpse.token or nil,
        bodyActionState = body and body.getActionStateName and body:getActionStateName() or nil,
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        debugRecording = record.runtime and record.runtime.debug == true or false,
        healthState = record.health and record.health.state or nil,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        targetKind = record.runtime and record.runtime.targetKind or "none",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
        bite = bite and Core.DeepCopy(bite) or nil,
    }
end

function Lifecycle.BuildDeathMarkerDiagnostics(marker)
    local state = marker and Internal.registry()
        and Internal.registry().GetDeathMarkerRuntime
        and Internal.registry().GetDeathMarkerRuntime(marker.id) or {}
    if not marker then return nil end
    return {
        id = tostring(marker.id),
        name = marker.name,
        faction = "dead",
        deathMarker = true,
        presenceState = Const.PRESENCE_CORPSE,
        alive = false,
        phase = marker.infected == true and "awaiting-reanimation"
            or "engine-corpse",
        bodyState = state.corpseState == "inert_loaded"
            and "corpse-loaded" or "corpse-missing",
        corpseState = state.corpseState or "unresolved",
        corpseToken = marker.corpseToken,
        infected = marker.infected == true,
        createdWorldHour = marker.createdWorldHour,
        reanimateAt = state.reanimateAt,
        missingSinceAt = state.missingSinceAt,
        x = marker.x,
        y = marker.y,
        z = marker.z,
        healthState = "dead",
        hpCurrent = 0,
        hpMax = 0,
        targetKind = "none",
        lastReason = marker.infected == true and "infection-death"
            or "death",
    }
end

function Lifecycle.BuildDebugRoster()
    local list = {}
    local registry = Internal.registry()
    if not registry then return list end
    if registry.ForEach then
        registry.ForEach(function(record)
            local diagnostic = Lifecycle.BuildDiagnostics(record)
            if diagnostic then list[#list + 1] = diagnostic end
        end)
    end
    if registry.ForEachDeathMarker then
        registry.ForEachDeathMarker(function(marker)
            local diagnostic = Lifecycle.BuildDeathMarkerDiagnostics(marker)
            if diagnostic then list[#list + 1] = diagnostic end
        end)
    end
    table.sort(list, function(left, right)
        return tostring(left and (left.name or left.id) or "")
            < tostring(right and (right.name or right.id) or "")
    end)
    return list
end
