--[[
    PNC Client Presence Tick
    Orchestrates local snapshot refresh, remote sync, and presentation.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
require "PNC/PresenceSync/PNC_ClientPresenceTick_LocalSnapshots"
require "PNC/PresenceSync/PNC_ClientPresenceTick_Remote"
require "PNC/PresenceSync/PNC_ClientPresenceTick_Apply"
local Tick = Internal.PresenceTick
local LocalSnapshots = Tick.LocalSnapshots
local RemoteSnapshots = Tick.RemoteSnapshots
local Presentation = Tick.Presentation
local canRequestRemoteSync = Internal.CanRequestRemoteSync
local Core = PNC.Core
local Const = PNC.Const
local Client = PNC.Client
local isWorldReady = Internal.IsWorldReady
local refreshBodyMap = Internal.RefreshBodyMap

function Sync.OnTick()
    local now = Core.Now()
    local remoteReplica
    local localSnapshotsRebuilt
    local localSnapshotChangedByID
    local localVisualMaintainDue
    local applyLocalVisuals
    if Client and Client.Internal
        and Client.Internal.PumpInitialStateRequests
    then
        if Client.Internal.PumpInitialStateRequests(now) == false then
            return
        end
    elseif not isWorldReady() then
        return
    end
    remoteReplica = canRequestRemoteSync()
    if remoteReplica then
        RemoteSnapshots.RequestSyncIfStale(now)
    end
    Sync.LocalSnapshotChangedByID = {}
    localSnapshotsRebuilt = LocalSnapshots.RefreshAuthority(now)
    localSnapshotChangedByID = Sync.LocalSnapshotChangedByID or {}
    localVisualMaintainDue = now >= (
        (tonumber(Sync.lastLocalVisualMaintainAt) or 0)
            + (tonumber(Const.CLIENT_LOCAL_VISUAL_MAINTAIN_MS) or 250)
    )
    applyLocalVisuals = remoteReplica
        or localSnapshotsRebuilt
        or localVisualMaintainDue
    if not remoteReplica and applyLocalVisuals then
        Sync.lastLocalVisualMaintainAt = now
    end
    refreshBodyMap(now)
    Presentation.ApplySnapshots(
        now,
        remoteReplica,
        applyLocalVisuals,
        localVisualMaintainDue,
        localSnapshotChangedByID
    )
    if remoteReplica
        and Internal.PruneNativePathControllers
    then
        Internal.PruneNativePathControllers(now)
        RemoteSnapshots.PruneState(now)
    end
end
