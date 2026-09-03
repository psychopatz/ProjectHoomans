--[[
    PNC Client Presence Sync
    Public facade, shared reconciliation state, and client event wiring.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}

local Sync = PNC.ClientPresenceSync
local Core = PNC.Core
local ClientState = PNC.Network and PNC.Network.ClientState

Sync.BodyByID = Sync.BodyByID or {}
Sync.BodyByOnlineID = Sync.BodyByOnlineID or {}
Sync.BodyByInstanceID = Sync.BodyByInstanceID or {}
Sync.BodyByLease = Sync.BodyByLease or {}
Sync.FacingByID = Sync.FacingByID or {}
Sync.UnresolvedLogAtByID = Sync.UnresolvedLogAtByID or {}
Sync.MotionLogByID = Sync.MotionLogByID or {}
Sync.PrunedRevisionByID = Sync.PrunedRevisionByID or {}
Sync.LocalSnapshotAtByID = Sync.LocalSnapshotAtByID or {}
Sync.RemoteSnapshotStateByID = Sync.RemoteSnapshotStateByID or {}
Sync.Internal = Sync.Internal or {}
Sync.lastBodyScanAt = Sync.lastBodyScanAt or 0
Sync.lastLocalSnapshotBuildAt = Sync.lastLocalSnapshotBuildAt or 0
Sync.lastLocalVisualMaintainAt = Sync.lastLocalVisualMaintainAt or 0
Sync.lastRemoteSnapshotStatePruneAt =
    Sync.lastRemoteSnapshotStatePruneAt or 0

require "PNC/PresenceSync/PNC_ClientPresenceRuntime"
require "PNC/PresenceSync/PNC_ClientPresenceFacing"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals"
require "PNC/PresenceSync/PNC_ClientPresenceBodies"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController"
require "PNC/PresenceSync/PNC_ClientZombieAggroController"
require "PNC/PresenceSync/PNC_ClientPresenceTick"

local function onResetLua()
    Sync.BodyByID = {}
    Sync.BodyByOnlineID = {}
    Sync.BodyByInstanceID = {}
    Sync.BodyByLease = {}
    Sync.FacingByID = {}
    Sync.UnresolvedLogAtByID = {}
    Sync.MotionLogByID = {}
    Sync.PrunedRevisionByID = {}
    Sync.LocalSnapshotAtByID = {}
    Sync.RemoteSnapshotStateByID = {}
    Sync.hasLocalIncapacitatedSnapshots = nil
    Sync.lastBodyScanAt = 0
    Sync.lastLocalSnapshotBuildAt = 0
    Sync.lastLocalVisualMaintainAt = 0
    Sync.lastRemoteSnapshotStatePruneAt = 0
    if Sync.Internal.ClearNativePathControllers then
        Sync.Internal.ClearNativePathControllers()
    end
end

function Sync.OnReplicaVisualUpdate(zombie)
    local modData
    local id
    local snapshot
    if not zombie
        or not Core
        or not Core.IsClientOnly
        or Core.IsClientOnly() ~= true
    then
        return
    end
    modData = zombie.getModData
        and zombie:getModData() or nil
    id = modData and modData.PNC_NPC == true
        and modData.PNC_UUID or nil
    snapshot = id and ClientState
        and ClientState.snapshots
        and ClientState.snapshots[tostring(id)]
        or nil
    if not snapshot
        or snapshot.interestDetailed == false
        or snapshot.presenceState
            ~= PNC.Const.PRESENCE_LIVE
        or snapshot.alive == false
    then
        return
    end
    if Sync.Internal.EnsureReplicaClothingSnapshot then
        Sync.Internal.EnsureReplicaClothingSnapshot(
            snapshot,
            zombie
        )
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(Sync.OnTick)
end

if Events and Events.OnZombieUpdate then
    if Sync.ReplicaVisualUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.ReplicaVisualUpdateHandler
        )
    end
    Sync.ReplicaVisualUpdateHandler =
        Sync.OnReplicaVisualUpdate
    Events.OnZombieUpdate.Add(
        Sync.ReplicaVisualUpdateHandler
    )
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
