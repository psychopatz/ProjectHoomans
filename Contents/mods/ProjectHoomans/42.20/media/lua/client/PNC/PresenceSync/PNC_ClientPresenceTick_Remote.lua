--[[
    PNC Client Presence Tick: remote replica cadence and state cleanup.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local Client = PNC.Client
local ClientState = PNC.Network and PNC.Network.ClientState
local Tick = Internal.PresenceTick or {}
Internal.PresenceTick = Tick
local Remote = Tick.RemoteSnapshots or {}
Tick.RemoteSnapshots = Remote

local function remoteSnapshotInterval(snapshot)
    local visualState = snapshot and snapshot.visualState or nil
    local treatment = snapshot and snapshot.treatmentState or nil
    local medical = snapshot and snapshot.medicalCareState or nil
    local sceneActive = visualState
        and visualState.sceneActive == true
    local active = visualState
        and (
            visualState.attackActive == true
            or visualState.specialActive == true
            or visualState.nativeMoveActive == true
        )
    if sceneActive
        or (treatment and treatment.phase and treatment.phase ~= "idle")
        or (medical and medical.phase and medical.phase ~= "idle")
        or (snapshot and snapshot.healthState == "incapacitated")
        or active
    then
        return tonumber(Const.CLIENT_REMOTE_SNAPSHOT_ACTIVE_MS) or 100
    end
    if visualState and visualState.moving == true then
        return tonumber(Const.CLIENT_REMOTE_SNAPSHOT_MOVE_MS) or 150
    end
    return tonumber(Const.CLIENT_REMOTE_SNAPSHOT_IDLE_MS) or 500
end

local function remoteFacingInterval(snapshot)
    local visualState = snapshot and snapshot.visualState or nil
    if visualState and visualState.moving == true then
        return tonumber(Const.CLIENT_REMOTE_FACING_MOVE_MS) or 100
    end
    return tonumber(Const.CLIENT_REMOTE_FACING_IDLE_MS) or 220
end

local function getRemoteSnapshotState(id)
    local states = Sync.RemoteSnapshotStateByID
    local state
    if not states then
        states = {}
        Sync.RemoteSnapshotStateByID = states
    end
    state = states[id]
    if not state then
        state = {}
        states[id] = state
    end
    return state
end

local function remotePresentationChanged(state, snapshot)
    local visualState = snapshot and snapshot.visualState or nil
    local treatment = snapshot and snapshot.treatmentState or nil
    local medical = snapshot and snapshot.medicalCareState or nil
    local revision = snapshot and snapshot.presenceRevision or 0
    local healthState = snapshot and snapshot.healthState or "normal"
    local anim = visualState and visualState.anim or "Idle"
    local moveAnim = visualState and visualState.moveAnim or ""
    local moving = visualState and visualState.moving == true
    local attackActive = visualState and visualState.attackActive == true
    local specialActive = visualState and visualState.specialActive == true
    local nativeMoveActive = visualState
        and visualState.nativeMoveActive == true
    local sceneActive = visualState and visualState.sceneActive == true
    local sceneId = visualState and visualState.sceneId or ""
    local sceneRevision = visualState and visualState.sceneRevision or 0
    local treatmentPhase = treatment and treatment.phase or "idle"
    local treatmentPartId = treatment and treatment.partId or ""
    local medicalPhase = medical and medical.phase or "idle"
    local medicalTaskId = medical and medical.taskId or ""
    local medicalBump = medical and medical.bump or ""
    local changed = state.presentationRevision ~= revision
        or state.presentationHealthState ~= healthState
        or state.presentationAnim ~= anim
        or state.presentationMoveAnim ~= moveAnim
        or state.presentationMoving ~= moving
        or state.presentationAttackActive ~= attackActive
        or state.presentationSpecialActive ~= specialActive
        or state.presentationNativeMoveActive ~= nativeMoveActive
        or state.presentationSceneActive ~= sceneActive
        or state.presentationSceneId ~= sceneId
        or state.presentationSceneRevision ~= sceneRevision
        or state.presentationTreatmentPhase ~= treatmentPhase
        or state.presentationTreatmentPartId ~= treatmentPartId
        or state.presentationMedicalPhase ~= medicalPhase
        or state.presentationMedicalTaskId ~= medicalTaskId
        or state.presentationMedicalBump ~= medicalBump
        or state.presentationAppearance ~= (snapshot and snapshot.appearance)
        or state.presentationEquipment ~= (snapshot and snapshot.equipmentSummary)
    state.presentationRevision = revision
    state.presentationHealthState = healthState
    state.presentationAnim = anim
    state.presentationMoveAnim = moveAnim
    state.presentationMoving = moving
    state.presentationAttackActive = attackActive
    state.presentationSpecialActive = specialActive
    state.presentationNativeMoveActive = nativeMoveActive
    state.presentationSceneActive = sceneActive
    state.presentationSceneId = sceneId
    state.presentationSceneRevision = sceneRevision
    state.presentationTreatmentPhase = treatmentPhase
    state.presentationTreatmentPartId = treatmentPartId
    state.presentationMedicalPhase = medicalPhase
    state.presentationMedicalTaskId = medicalTaskId
    state.presentationMedicalBump = medicalBump
    state.presentationAppearance = snapshot and snapshot.appearance
    state.presentationEquipment = snapshot and snapshot.equipmentSummary
    return changed
end

local function remotePresentationDue(id, snapshot, body, now)
    local state = getRemoteSnapshotState(id)
    local changed = state.snapshot ~= snapshot
        or state.body ~= body
    local presentationChanged = remotePresentationChanged(state, snapshot)
    local due
    if changed then
        state.snapshot = snapshot
        state.body = body
    end
    due = changed
        or presentationChanged
        or now >= (tonumber(state.nextApplyAt) or 0)
    if due then
        state.nextApplyAt = now + remoteSnapshotInterval(snapshot)
    end
    return state, changed, due, presentationChanged
end

local function remoteFacingDue(state, snapshot, now)
    local visualState = snapshot and snapshot.visualState or nil
    local nativeMoveActive = visualState
        and visualState.nativeMoveActive == true
    if nativeMoveActive then
        -- Let the engine/native path owner control facing. Reassert on the
        -- first presentation pass after delegated movement ends.
        state.nextFacingAt = now
        return false
    end
    if now >= (tonumber(state.nextFacingAt) or 0) then
        state.nextFacingAt = now + remoteFacingInterval(snapshot)
        return true
    end
    return false
end

local function remoteNativeBindingDue(
    state,
    snapshot,
    body,
    now,
    snapshotChanged,
    presentationChanged
)
    local controllerState = Sync.NativePathStateByBody
        and Sync.NativePathStateByBody[body] or nil
    if snapshotChanged
        or presentationChanged
        or not controllerState
        or controllerState.snapshot ~= snapshot
        or controllerState.releasePending == true
    then
        return true
    end
    if controllerState.failed == true
        and now >= (tonumber(controllerState.retryAt) or 0)
    then
        return true
    end
    return now >= (tonumber(state.nextNativeBindAt) or 0)
end

local function pruneRemoteSnapshotState(now)
    local states = Sync.RemoteSnapshotStateByID
    local prunedRevisions = Sync.PrunedRevisionByID
    local snapshots = ClientState and ClientState.snapshots or {}
    local lastPruneAt = tonumber(Sync.lastRemoteSnapshotStatePruneAt) or 0
    local id
    if not states
        or now < lastPruneAt
            + (tonumber(Const.CLIENT_REMOTE_STATE_PRUNE_MS) or 5000)
    then
        return
    end
    Sync.lastRemoteSnapshotStatePruneAt = now
    for id, _ in pairs(states) do
        if not snapshots[tostring(id)] then
            states[id] = nil
        end
    end
    for id, _ in pairs(prunedRevisions or {}) do
        if not snapshots[tostring(id)] then
            prunedRevisions[id] = nil
        end
    end
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


Remote.PresentationDue = remotePresentationDue
Remote.FacingDue = remoteFacingDue
Remote.NativeBindingDue = remoteNativeBindingDue
Remote.PruneState = pruneRemoteSnapshotState
Remote.RequestSyncIfStale = requestSyncIfStale
