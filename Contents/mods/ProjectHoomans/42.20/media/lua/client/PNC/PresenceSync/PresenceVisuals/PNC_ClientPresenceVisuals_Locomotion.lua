--[[
    PNC Client Presence Visuals: special and locomotion presentation
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Animation = PNC.Animation
local logClientMotionDebug = Internal.LogClientMotionDebug
local LOCOMOTION_MAINTAIN_MS = 500

local function applyLocomotion(
    snapshot,
    zombie,
    remoteReplica,
    state
)
    local visualState = state.visualState
    local modData = state.modData
    local recordView = state.recordView
    local motionKey = state.motionKey
    local now = state.now
    local specialKey
    local desiredAnim
    local motionChanged
    specialKey = visualState.specialActive and visualState.specialAnim
        and (tostring(visualState.specialAnim) .. ":" .. tostring(visualState.specialFinishAt or 0))
        or nil
    if specialKey and modData and modData.PNC_ClientSpecialKey ~= specialKey then
        if remoteReplica and Animation and Animation.PlayBump then
            Animation.PlayBump(zombie, recordView, visualState.specialAnim)
        end
        modData.PNC_ClientSpecialKey = specialKey
        modData.PNC_ClientMotionKey = motionKey
        return
    end
    if modData and not specialKey and modData.PNC_ClientSpecialKey ~= nil then
        if remoteReplica and Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientSpecialKey = nil
        return
    end
    if specialKey then
        return
    end

    if remoteReplica
        and visualState.nativeMoveActive == true
    then
        -- The nearest client submits the PathFindState request. Only its
        -- walk/run presentation style is ours; movement and action-state
        -- variables remain exclusively engine-owned.
        if Animation and Animation.SyncNativeLocomotionStyle then
            Animation.SyncNativeLocomotionStyle(zombie, recordView)
        end
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return
    end

    desiredAnim = visualState.anim or "Idle"
    motionChanged = not modData
        or modData.PNC_ClientMotionKey ~= motionKey
    if remoteReplica and Animation and Animation.Apply
        and motionChanged
    then
        Animation.Apply(zombie, recordView, desiredAnim, recordView.runtime.pathing.motionProfile, visualState.moving == true)
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
    end
    if remoteReplica and visualState.moving == true
        and Animation and Animation.SyncLocomotion
        and (
            motionChanged
            or not modData
            or now >= (
                tonumber(modData.PNC_ClientLocomotionMaintainAt)
                    or 0
            )
        )
    then
        Animation.SyncLocomotion(zombie, recordView)
        if modData then
            modData.PNC_ClientLocomotionMaintainAt =
                now + LOCOMOTION_MAINTAIN_MS
        end
        logClientMotionDebug(snapshot, snapshot and snapshot.id or nil, "locomotion_resync", "mode=" .. tostring(visualState.mode or "walk") .. " walkType=" .. tostring(visualState.walkType or ""))
    elseif modData and visualState.moving ~= true then
        modData.PNC_ClientLocomotionMaintainAt = nil
    end
end

Internal.ApplyLocomotion = applyLocomotion

