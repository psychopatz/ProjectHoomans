--[[
    PNC Client Presence Visuals: snapshot-to-body orchestration
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local AnimationTrace = PNC.AnimationTrace
local buildRecordView = Internal.BuildRecordView
local buildMotionKey = Internal.BuildMotionKey
local getTreatmentPresentation = Internal.GetTreatmentPresentation
local getScenePresentation = Internal.GetScenePresentation
local applyIdentityVars = Internal.ApplyIdentityVars
local applyBodyPresentation = Internal.ApplyBodyPresentation
local applyActionMotion = Internal.ApplyActionMotion
local applyLocomotion = Internal.ApplyLocomotion

local function normalizeVisualStateSnapshot(snapshot)
    local key
    local value
    local normalized
    if snapshot.visualState == nil
        or type(snapshot.visualState) == "table"
    then
        return snapshot
    end
    normalized = {}
    for key, value in pairs(snapshot) do
        normalized[key] = value
    end
    normalized.visualState = {}
    return normalized
end

local function applySnapshotToBody(snapshot, zombie, remoteReplica)
    local visualState
    local modData
    local attackKey
    local recordView
    local motionKey
    local engineMovementActive
    local bumpReleaseActive
    local treatmentPresentation
    local treatmentActive
    local scenePresentation
    local sceneActive
    local now
    if type(snapshot) ~= "table" or not zombie
    then
        return
    end
    snapshot = normalizeVisualStateSnapshot(snapshot)
    if zombie.isDead and zombie:isDead() then
        return
    end
    visualState = type(snapshot.visualState) == "table"
        and snapshot.visualState or {}
    modData = zombie.getModData and zombie:getModData() or nil
    if remoteReplica == nil then
        remoteReplica = true
    end

    now = Core and Core.Now and Core.Now() or 0
    treatmentPresentation = getTreatmentPresentation(snapshot)
    treatmentActive = treatmentPresentation ~= nil
    scenePresentation = getScenePresentation(snapshot, now)
    sceneActive = scenePresentation ~= nil
    if PNC.AnimationDebugPlayer
        and PNC.AnimationDebugPlayer.IsPreviewing
        and PNC.AnimationDebugPlayer.IsPreviewing(zombie)
    then
        applyIdentityVars(zombie, snapshot)
        if modData and snapshot.id ~= nil then
            modData.PNC_UUID = tostring(snapshot.id)
            modData.PNC_NPC = true
        end
        if Internal.SyncBandageVisuals then
            Internal.SyncBandageVisuals(zombie, snapshot)
        end
        PNC.AnimationDebugPlayer.Maintain(zombie, now)
        return
    end
    attackKey = not (
            remoteReplica
            and visualState.nativeTraversalActive == true
        )
        and visualState.attackActive
        and visualState.attackAnim
        and (
            tostring(visualState.attackAnim)
                .. ":"
                .. tostring(visualState.attackFinishAt or 0)
        )
        or nil
    if attackKey
        and modData
        and modData.PNC_ClientAttackKey ~= attackKey
        and AnimationTrace
        and AnimationTrace.Begin
        and (
            AnimationTrace.forceEnabled == true
            or snapshot.debugState
                and snapshot.debugState.debugEnabled == true
        )
    then
        AnimationTrace.Begin(zombie, {
            npcId = snapshot.id,
            attackKey = attackKey,
            requested = visualState.attackAnim,
            resolved = Animation
                and Animation.ResolveBumpType
                and Animation.ResolveBumpType(
                    visualState.attackAnim
                )
                or visualState.attackAnim,
            debugEnabled = snapshot.debugState
                and snapshot.debugState.debugEnabled == true
                or false,
        }, now)
    end
    -- Apply gender/appearance before body maintenance.  IsoZombie's gender
    -- setter rewrites its native voice and hurt-sound channels, so running
    -- the safety pass first leaves a freshly bound replica audible as a
    -- zombie until the next update callback.
    recordView = buildRecordView(snapshot)
    applyBodyPresentation(
        snapshot,
        zombie,
        remoteReplica,
        recordView,
        modData,
        now
    )
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_pre_maintain", now)
    end
    engineMovementActive = remoteReplica
        and (
            visualState.nativeMoveActive == true
            or visualState.nativeTraversalActive == true
            or visualState.attackActive == true
            or treatmentActive
            or sceneActive
            or modData and modData.PNC_BumpActionLease == true
            or modData and modData.PNC_BumpReleasePending == true
        )
    if LiveBodyControl and LiveBodyControl.MaintainHumanizedBody then
        LiveBodyControl.MaintainHumanizedBody(
            zombie,
            now,
            engineMovementActive
        )
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_post_maintain", now)
    end
    if (
        remoteReplica
        or (
            modData
            and (
                modData.PNC_ClientAttackKey ~= nil
                or modData.PNC_BumpReleasePending == true
            )
        )
    )
        and Animation and Animation.PumpBumpRelease
    then
        bumpReleaseActive =
            Animation.PumpBumpRelease(zombie, now)
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "client_post_release_pump",
            now
        )
    end
    motionKey = buildMotionKey(snapshot)
    local motionState = {
        visualState = visualState,
        modData = modData,
        recordView = recordView,
        motionKey = motionKey,
        attackKey = attackKey,
        bumpReleaseActive = bumpReleaseActive,
        treatmentPresentation = treatmentPresentation,
        scenePresentation = scenePresentation,
        now = now,
    }
    if applyActionMotion(
        snapshot,
        zombie,
        remoteReplica,
        motionState
    ) then
        return
    end
    applyLocomotion(
        snapshot,
        zombie,
        remoteReplica,
        motionState
    )
end

Internal.ApplySnapshotToBody = applySnapshotToBody
