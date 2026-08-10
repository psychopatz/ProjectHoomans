--[[
    PNC Client Presence Visuals: treatment audio and animation
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Animation = PNC.Animation

local function syncTreatmentSound(zombie, snapshot, modData)
    local treatment = snapshot and snapshot.treatmentState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local completion = snapshot and snapshot.bandageFeedback or nil
    local completionKey
    local soundKey
    local emitter
    local soundManager
    if not modData then return end
    if completion then
        completionKey = tostring(completion.revision or "")
            .. ":" .. tostring(completion.completedAt or 0)
            .. ":" .. tostring(completion.partId or "")
        if modData.PNC_ClientBandageCompletionKey ~= completionKey then
            emitter = zombie and zombie.getEmitter
                and zombie:getEmitter() or nil
            soundManager = getSoundManager and getSoundManager() or nil
            if emitter and emitter.playSound then
                emitter:playSound(tostring(
                    completion.sound or "PNC_BandageComplete"
                ))
                modData.PNC_ClientBandageCompletionKey = completionKey
            elseif zombie and zombie.playSound then
                zombie:playSound(tostring(
                    completion.sound or "PNC_BandageComplete"
                ))
                modData.PNC_ClientBandageCompletionKey = completionKey
            elseif zombie and zombie.getSquare and zombie:getSquare()
                and soundManager and soundManager.PlayWorldSound
            then
                soundManager:PlayWorldSound(
                    tostring(completion.sound or "PNC_BandageComplete"),
                    zombie:getSquare(),
                    0,
                    8,
                    1.0,
                    false
                )
                modData.PNC_ClientBandageCompletionKey = completionKey
            end
        end
    end
    if phase ~= "bandaging" then
        modData.PNC_ClientTreatmentSoundKey = nil
        return
    end
    soundKey = tostring(treatment.partId or "")
        .. ":" .. tostring(treatment.startedAt or 0)
    if modData.PNC_ClientTreatmentSoundKey == soundKey then return end
    emitter = emitter
        or zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        modData.PNC_ClientTreatmentSoundKey = soundKey
    end
end

local function getTreatmentPresentation(snapshot)
    local treatment = snapshot and snapshot.treatmentState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local partId
    local key
    local anim
    if phase ~= "bandaging" then
        return nil
    end
    partId = tostring(treatment.partId or "")
    key = partId .. ":" .. tostring(treatment.startedAt or 0)
    anim = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.ResolveBandageAnimation
        and PNC.BehaviorTreatment.ResolveBandageAnimation(partId)
        or "BandageUpperBody"
    return {
        key = key,
        anim = anim,
        finishAt = tonumber(treatment.finishAt) or 0,
    }
end

local function syncTreatmentAnimation(
    zombie,
    recordView,
    modData,
    presentation
)
    if not modData then
        return presentation ~= nil, false
    end
    if not presentation then
        if modData.PNC_ClientTreatmentAnimKey == nil then
            return false, false
        end
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientTreatmentAnimKey = nil
        return false, true
    end
    if modData.PNC_ClientTreatmentAnimKey ~= presentation.key then
        if Animation and Animation.PlayBump then
            Animation.PlayBump(
                zombie,
                recordView,
                presentation.anim,
                {
                    leaseUntil = presentation.finishAt,
                }
            )
        end
        modData.PNC_ClientTreatmentAnimKey = presentation.key
    elseif Animation and Animation.MaintainBump then
        Animation.MaintainBump(
            zombie,
            recordView,
            presentation.anim,
            presentation.finishAt
        )
    end
    return true, false
end


Internal.SyncTreatmentSound = syncTreatmentSound
Internal.GetTreatmentPresentation = getTreatmentPresentation
Internal.SyncTreatmentAnimation = syncTreatmentAnimation

