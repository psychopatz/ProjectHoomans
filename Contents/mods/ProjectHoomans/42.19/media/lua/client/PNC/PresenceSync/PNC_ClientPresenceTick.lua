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

local function refreshLocalAuthoritySnapshots(now)
    local snapshots
    if canRequestRemoteSync() then
        return
    end
    if not Registry or not Registry.ForEach or not Network or not Network.BuildSnapshot then
        return
    end
    if now < ((tonumber(Sync.lastLocalSnapshotBuildAt) or 0) + 75) then
        return
    end
    Sync.lastLocalSnapshotBuildAt = now
    snapshots = {}
    Registry.ForEach(function(record)
        local snapshot = Network.BuildSnapshot(record)
        if snapshot and snapshot.id then
            snapshots[snapshot.id] = snapshot
        end
    end)
    ClientState.snapshots = snapshots
    ClientState.lastSyncReceiveAt = now
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
    if not isWorldReady() then
        return
    end
    if canRequestRemoteSync() then
        requestSyncIfStale(now)
    end
    refreshLocalAuthoritySnapshots(now)
    refreshBodyMap(now)
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
                pruneSnapshotDuplicates(snapshot, body)
                if canRequestRemoteSync() and Interpolation and Interpolation.RecordSnapshot then
                    Interpolation.RecordSnapshot(snapshot, body, now)
                end
                if canRequestRemoteSync() and Interpolation and Interpolation.ApplyToZombie then
                    Interpolation.ApplyToZombie(snapshot, body, now)
                end
                -- The authoritative SP/listen-server body was already faced
                -- by PathService.  Re-facing it from the client snapshot loop
                -- created a second movement owner.  Dedicated clients alone
                -- apply replicated facing, with throttling above.
                if canRequestRemoteSync() then
                    applySnapshotFacing(body, snapshot)
                end
                applySnapshotToBody(snapshot, body)
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
