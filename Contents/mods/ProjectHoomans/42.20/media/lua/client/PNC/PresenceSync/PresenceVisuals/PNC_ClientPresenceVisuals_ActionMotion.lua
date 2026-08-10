--[[
    PNC Client Presence Visuals: downed, attack, treatment, and scene priority
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Animation = PNC.Animation
local AnimationTrace = PNC.AnimationTrace
local beginClientAttackBump = Internal.BeginClientAttackBump
local observeClientAttackBump = Internal.ObserveClientAttackBump
local rearmDroppedClientAttackBump =
    Internal.RearmDroppedClientAttackBump
local syncTreatmentAnimation = Internal.SyncTreatmentAnimation
local syncAnimationScene = Internal.SyncAnimationScene

local function applyActionMotion(
    snapshot,
    zombie,
    remoteReplica,
    state
)
    local visualState = state.visualState
    local modData = state.modData
    local recordView = state.recordView
    local motionKey = state.motionKey
    local attackKey = state.attackKey
    local bumpReleaseActive = state.bumpReleaseActive
    local treatmentPresentation = state.treatmentPresentation
    local scenePresentation = state.scenePresentation
    local now = state.now
    local treatmentActive
    local treatmentReleased
    local sceneActive
    local sceneReleased
    if snapshot.healthState == "incapacitated" then
        -- Downed-state repair is idempotent and also clears late vanilla
        -- stagger/hit-reaction latches on the authoritative body.
        if Animation and Animation.ApplyDowned then
            Animation.ApplyDowned(zombie, recordView, visualState.moving == true and visualState.isCrawling == true and recordView.runtime.pathing.motionProfile or false)
        end
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientWasDowned = true
        end
        return true
    elseif modData
        and modData.PNC_ClientWasDowned == true
        and Animation
        and Animation.ClearDowned
    then
        -- ClearDowned writes the generic movement variables, so it is only a
        -- transition repair. Running it for every healthy snapshot competes
        -- with PathFindBehavior2 and forces WalkTowardState over path2.
        Animation.ClearDowned(zombie)
        modData.PNC_ClientWasDowned = nil
    end

    -- Combat presentation is client-owned in every topology. The server
    -- chooses the clip and hit timing; SP and MP clients both render the
    -- resulting attack snapshot. remoteReplica only gates replicated
    -- locomotion, facing, and traversal presentation.
    if attackKey and modData and modData.PNC_ClientAttackKey ~= attackKey then
        modData.PNC_ClientTreatmentAnimKey = nil
        modData.PNC_ClientAnimationSceneKey = nil
        beginClientAttackBump(
            snapshot,
            zombie,
            recordView,
            modData,
            attackKey,
            visualState.attackAnim,
            now
        )
        modData.PNC_ClientMotionKey = motionKey
        return true
    end
    if modData and not attackKey and modData.PNC_ClientAttackKey ~= nil then
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAttackKey = nil
        modData.PNC_ClientAttackLocalStartedAt = nil
        modData.PNC_ClientAttackRetries = nil
        modData.PNC_ClientAttackRequestedAnim = nil
        modData.PNC_ClientAttackResolvedAnim = nil
        return true
    end
    if attackKey then
        rearmDroppedClientAttackBump(
            snapshot,
            zombie,
            recordView,
            modData,
            attackKey,
            visualState.attackAnim,
            now
        )
        observeClientAttackBump(zombie, modData)
        if AnimationTrace and AnimationTrace.Sample then
            AnimationTrace.Sample(
                zombie,
                "client_attack_observe",
                now
            )
        end
        return true
    end
    if bumpReleaseActive then
        -- A newer movement snapshot can arrive before BumpedState consumes
        -- BumpAnimFinished. Do not let traversal, native locomotion, or fake
        -- locomotion presentation overwrite that final action-graph frame.
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
        return true
    end

    if treatmentPresentation and modData then
        modData.PNC_ClientAnimationSceneKey = nil
    end
    treatmentActive, treatmentReleased =
        syncTreatmentAnimation(
            zombie,
            recordView,
            modData,
            treatmentPresentation
        )
    if treatmentActive or treatmentReleased then
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return true
    end

    sceneActive, sceneReleased =
        syncAnimationScene(
            zombie,
            recordView,
            modData,
            scenePresentation
        )
    if sceneActive or sceneReleased then
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return true
    end

    if remoteReplica
        and visualState.nativeTraversalActive == true
    then
        -- Fence/window traversal is already carried by the engine zombie
        -- packet and its native action state.  Replaying a PNC locomotion or
        -- scripted bump here would create a second animation owner.
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return true
    end
    return false
end

Internal.ApplyActionMotion = applyActionMotion

