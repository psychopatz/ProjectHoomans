--[[
    PNC Client Presence Tick
    Orchestrates snapshot refresh, body resolution, native control, and visuals.
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
local isWorldReady = Internal.IsWorldReady
local canRequestRemoteSync = Internal.CanRequestRemoteSync
local isSnapshotDebugEnabled = Internal.IsSnapshotDebugEnabled
local logClientMotionDebug = Internal.LogClientMotionDebug
local applySnapshotFacing = Internal.ApplySnapshotFacing
local applySnapshotToBody = Internal.ApplySnapshotToBody
local pruneSnapshotDuplicates = Internal.PruneSnapshotDuplicates
local refreshBodyMap = Internal.RefreshBodyMap
local resolveSnapshotBody = Internal.ResolveSnapshotBody
local bindNativePathSnapshot =
    Internal.BindNativePathSnapshot
local voiceTriggers = PNC.NPCVoice
    and PNC.NPCVoice.Triggers or nil

local function resolveSnapshotBodyFromIndexes(snapshot)
    local id
    if type(snapshot) ~= "table" or snapshot.id == nil then
        return nil
    end
    id = tostring(snapshot.id)
    return Sync.BodyByLease[
        id .. ":" .. tostring(snapshot.liveBodyLease or "")
    ] or Sync.BodyByInstanceID[
        tostring(snapshot.liveBodyInstanceID or "")
    ] or Sync.BodyByID[id] or Sync.BodyByOnlineID[
        tostring(snapshot.liveBodyOnlineID or "")
    ]
end

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
end

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
    return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_IDLE_MS) or 500
end

local function refreshLocalAuthoritySnapshots(now)
    local snapshots
    local builtAtByID
    local seen = {}
    local changedIDs = {}
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
    local function collectLiveRecord(record)
        if not record
            or record.presenceState ~= Const.PRESENCE_LIVE
            or record.alive == false
        then
            return
        end
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
            changedIDs[id] = true
            rebuilt = true
        end
    end
    -- Local-authority presentation only consumes embodied NPCs. Walking the
    -- entire persistent registry here made every abstract NPC build a detailed
    -- snapshot on the same two-second boundary, producing population-scaled
    -- hitches even when no NPC body was loaded near the player.
    if Registry.ForEachLive then
        Registry.ForEachLive(collectLiveRecord)
    else
        Registry.ForEach(function(record)
            collectLiveRecord(record)
        end)
    end
    for id, _ in pairs(snapshots) do
        if not seen[tostring(id)] then
            snapshots[id] = nil
            builtAtByID[tostring(id)] = nil
            changedIDs[tostring(id)] = true
            rebuilt = true
        end
    end
    ClientState.snapshots = snapshots
    ClientState.lastSyncReceiveAt = now
    Sync.hasLocalIncapacitatedSnapshots = hasIncapacitated
    Sync.LocalSnapshotChangedByID = changedIDs
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
    local localSnapshotChangedByID
    local localVisualMaintainDue
    local applyLocalVisuals
    local snapshotState
    local snapshotChanged
    local presentationChanged
    local presentationDue
    local facingDue
    local bindingDue
    if not isWorldReady() then
        return
    end
    -- Knowledge bootstrap is independent of roster/presence health. Keep
    -- retrying it in both SP and MP until it is bound to a character UUID.
    if Client and Client.EnsurePlayerBootstrap then
        local forceKnowledge = PNC.KnowledgeInterest
            and PNC.KnowledgeInterest.ConsumeFlush
            and PNC.KnowledgeInterest.ConsumeFlush(now)
            or false
        Client.EnsurePlayerBootstrap(now, forceKnowledge)
    end
    if Client and Client.EnsureWorldDiscovery then
        Client.EnsureWorldDiscovery(now, false)
    end
    remoteReplica = canRequestRemoteSync()
    if remoteReplica then
        requestSyncIfStale(now)
    end
    Sync.LocalSnapshotChangedByID = {}
    localSnapshotsRebuilt = refreshLocalAuthoritySnapshots(now)
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
    if not applyLocalVisuals and not hasIncapacitatedSnapshots() then
        return
    end
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            body = resolveSnapshotBody
                and resolveSnapshotBody(snapshot)
                or resolveSnapshotBodyFromIndexes(snapshot)
            if body then
                if applyLocalVisuals
                    or snapshot.healthState == "incapacitated"
                then
                    if remoteReplica then
                        snapshotState, snapshotChanged, presentationDue,
                            presentationChanged =
                            remotePresentationDue(
                                tostring(id),
                                snapshot,
                                body,
                                now
                            )
                        bindingDue = remoteNativeBindingDue(
                            snapshotState,
                            snapshot,
                            body,
                            now,
                            snapshotChanged,
                            presentationChanged
                        )
                        if bindingDue then
                            if bindNativePathSnapshot then
                                bindNativePathSnapshot(
                                    snapshot,
                                    body,
                                    now
                                )
                            end
                            snapshotState.nextNativeBindAt = now
                                + (tonumber(Const.CLIENT_REMOTE_NATIVE_BIND_MS) or 250)
                            snapshotState.nativeMoveActive = snapshot.visualState
                                and snapshot.visualState.nativeMoveActive == true
                            snapshotState.attackActive = snapshot.visualState
                                and snapshot.visualState.attackActive == true
                        end
                        facingDue = remoteFacingDue(
                            snapshotState,
                            snapshot,
                            now
                        )
                        -- Native PathFindBehavior2 and zombie replication own
                        -- facing while delegated movement is active.
                        if facingDue and applySnapshotFacing then
                            applySnapshotFacing(body, snapshot)
                        end
                    else
                        snapshotChanged = localSnapshotChangedByID[
                            tostring(id)
                        ] == true
                        presentationDue = localVisualMaintainDue
                    end
                    if snapshotChanged or presentationDue then
                        pruneSnapshotDuplicates(snapshot, body)
                        -- The embodied NPC is already an engine-replicated
                        -- IsoZombie.  Project Zomboid smooths its authoritative
                        -- server position just as it does for Bandits.  Applying
                        -- roster-snapshot X/Y interpolation here creates a second
                        -- transport owner that continually rewinds the native
                        -- network mover.
                        -- The authoritative SP/listen-server body was already
                        -- faced by PathService. Dedicated clients alone apply
                        -- replicated facing.
                        applySnapshotToBody(snapshot, body, remoteReplica)
                        if voiceTriggers and voiceTriggers.Observe then
                            voiceTriggers.Observe(
                                snapshot,
                                body,
                                remoteReplica,
                                now
                            )
                        end
                    end
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
    if remoteReplica
        and Internal.PruneNativePathControllers
    then
        Internal.PruneNativePathControllers(now)
        pruneRemoteSnapshotState(now)
    end
end
