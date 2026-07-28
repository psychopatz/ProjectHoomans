--[[
    PNC Client Presence Tick
    Orchestrates snapshot refresh, body resolution, interpolation, and visuals.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const
local Client = PNC.Client
local Network = PNC.Network
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState
local Interpolation = PNC.ClientInterpolation
local isWorldReady = Internal.IsWorldReady
local canRequestRemoteSync = Internal.CanRequestRemoteSync
local isSnapshotDebugEnabled = Internal.IsSnapshotDebugEnabled
local logClientMotionDebug = Internal.LogClientMotionDebug
local applySnapshotFacing = Internal.ApplySnapshotFacing
local applySnapshotToBody = Internal.ApplySnapshotToBody
local pruneSnapshotDuplicates = Internal.PruneSnapshotDuplicates
local refreshBodyMap = Internal.RefreshBodyMap

local function localSnapshotInterval(record, previous, now)
    local runtime = record and record.runtime or nil
    local attack = runtime and runtime.attackAction or nil
    local pathing = runtime and runtime.pathing or nil
    local previousVisual = previous and previous.visualState or nil
    if (previousVisual and previousVisual.attackActive == true)
        or (attack and now < (tonumber(attack.finishAt) or 0))
    then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_ATTACK_MS) or 50
    end
    if record and record.presenceState == Const.PRESENCE_LIVE
        and pathing
        and (
            pathing.phase == "requested"
            or pathing.phase == "active"
            or now < (tonumber(pathing.visualMovingUntil) or 0)
            or now < (tonumber(pathing.specialMoveUntil) or 0)
        )
    then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_MOVE_MS) or 150
    end
    if record and record.presenceState == Const.PRESENCE_LIVE then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_IDLE_MS) or 500
    end
    return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_ABSTRACT_MS) or 2000
end

local function refreshLocalAuthoritySnapshots(now)
    local snapshots
    local builtAtByID
    local seen = {}
    local rebuilt = false
    local id
    local previous
    local dueAt
    local snapshot
    local hasIncapacitated = false
    if canRequestRemoteSync() then
        return false
    end
    if not Registry or not Registry.ForEach or not Network or not Network.BuildSnapshot then
        return false
    end
    if now < ((tonumber(Sync.lastLocalSnapshotBuildAt) or 0)
        + (tonumber(Const.CLIENT_LOCAL_SNAPSHOT_SCAN_MS) or 50))
    then
        return false
    end
    Sync.lastLocalSnapshotBuildAt = now
    snapshots = ClientState.snapshots or {}
    builtAtByID = Sync.LocalSnapshotAtByID or {}
    Sync.LocalSnapshotAtByID = builtAtByID
    Registry.ForEach(function(record)
        id = tostring(record and record.id or "")
        seen[id] = true
        if record and record.health
            and record.health.state == "incapacitated"
        then
            hasIncapacitated = true
        end
        previous = snapshots[id]
        dueAt = (tonumber(builtAtByID[id]) or 0)
            + localSnapshotInterval(record, previous, now)
        if not previous
            or tonumber(previous.presenceRevision) ~= tonumber(record.presenceRevision)
            or now >= dueAt
        then
            snapshot = Network.BuildSnapshot(record)
        else
            snapshot = nil
        end
        if snapshot and snapshot.id then
            id = tostring(snapshot.id)
            snapshots[id] = snapshot
            builtAtByID[id] = now
            rebuilt = true
        end
    end)
    for id, _ in pairs(snapshots) do
        if not seen[tostring(id)] then
            snapshots[id] = nil
            builtAtByID[tostring(id)] = nil
            rebuilt = true
        end
    end
    ClientState.snapshots = snapshots
    ClientState.lastSyncReceiveAt = now
    Sync.hasLocalIncapacitatedSnapshots = hasIncapacitated
    return rebuilt
end

local function hasIncapacitatedSnapshots()
    local snapshot
    if Sync.hasLocalIncapacitatedSnapshots ~= nil then
        return Sync.hasLocalIncapacitatedSnapshots == true
    end
    for _, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.healthState == "incapacitated" then
            Sync.hasLocalIncapacitatedSnapshots = true
            return true
        end
    end
    Sync.hasLocalIncapacitatedSnapshots = false
    return false
end

local function requestSyncIfStale(now)
    local player = getSpecificPlayer(0)
    local lastRequestAt = tonumber(ClientState.lastFullSyncRequestAt or 0) or 0
    local lastReceiveAt = tonumber(ClientState.lastSyncReceiveAt or 0) or 0
    local hasSnapshots = false
    local id
    if not player or not sendClientCommand or not Client or not Client.RequestFullSync then
        return
    end
    for id, _ in pairs(ClientState and ClientState.snapshots or {}) do
        hasSnapshots = true
        break
    end
    if hasSnapshots then
        return
    end
    if lastReceiveAt > 0 and (now - lastReceiveAt) < 6000 then
        return
    end
    if (now - lastRequestAt) < 4000 then
        return
    end
    Client.RequestFullSync()
end

function Sync.OnTick()
    local now = Core.Now()
    local id
    local snapshot
    local body
    local remoteReplica
    local localSnapshotsRebuilt
    local applyLocalVisuals
    if not isWorldReady() then
        return
    end
    remoteReplica = canRequestRemoteSync()
    if remoteReplica then
        requestSyncIfStale(now)
    end
    localSnapshotsRebuilt = refreshLocalAuthoritySnapshots(now)
    applyLocalVisuals = remoteReplica
        or localSnapshotsRebuilt
        or now >= ((tonumber(Sync.lastLocalVisualMaintainAt) or 0)
            + (tonumber(Const.CLIENT_LOCAL_VISUAL_MAINTAIN_MS) or 250))
    if not remoteReplica and applyLocalVisuals then
        Sync.lastLocalVisualMaintainAt = now
    end
    refreshBodyMap(now)
    if not applyLocalVisuals and not hasIncapacitatedSnapshots() then
        return
    end
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            body = Sync.BodyByOnlineID[tostring(snapshot.liveBodyOnlineID or "")]
            if not body and snapshot.liveBodyLease then
                body = Sync.BodyByLease[tostring(id) .. ":" .. tostring(snapshot.liveBodyLease)]
            end
            if not body and not snapshot.liveBodyLease then
                body = Sync.BodyByID[tostring(id)]
            end
            body = body or Sync.BodyByInstanceID[tostring(snapshot.liveBodyInstanceID or "")]
            if body then
                if applyLocalVisuals
                    or snapshot.healthState == "incapacitated"
                then
                    pruneSnapshotDuplicates(snapshot, body)
                    if remoteReplica and Interpolation and Interpolation.RecordSnapshot then
                        Interpolation.RecordSnapshot(snapshot, body, now)
                    end
                    if remoteReplica and Interpolation and Interpolation.ApplyToZombie then
                        Interpolation.ApplyToZombie(snapshot, body, now)
                    end
                    -- The authoritative SP/listen-server body was already
                    -- faced by PathService. Dedicated clients alone apply
                    -- replicated facing.
                    if remoteReplica then
                        applySnapshotFacing(body, snapshot)
                    end
                    applySnapshotToBody(snapshot, body, remoteReplica)
                end
            elseif isSnapshotDebugEnabled(snapshot)
                and (now - (tonumber(Sync.UnresolvedLogAtByID[tostring(id)]) or 0)) >= 3000
            then
                Sync.UnresolvedLogAtByID[tostring(id)] = now
                logClientMotionDebug(
                    snapshot,
                    id,
                    "body_unresolved",
                    "onlineID=" .. tostring(snapshot.liveBodyOnlineID or "nil")
                        .. " instanceID=" .. tostring(snapshot.liveBodyInstanceID or "nil")
                )
            end
        end
    end
end
