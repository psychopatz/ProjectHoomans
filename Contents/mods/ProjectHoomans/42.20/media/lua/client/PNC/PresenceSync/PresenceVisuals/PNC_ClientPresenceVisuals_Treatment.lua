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

local function patientBody(patientId)
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(patientId) or nil
    if body then return body end
    local state = PNC.Network and PNC.Network.ClientState
    local snapshot = state and state.snapshots
        and state.snapshots[tostring(patientId or "")] or nil
    local onlineID = snapshot
        and (snapshot.liveBodyOnlineID or snapshot.bodyOnlineID) or nil
    return onlineID and PNC.Network
        and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(onlineID) or nil
end

local function syncTreatmentSound(zombie, snapshot, modData)
    local treatment = snapshot and snapshot.treatmentState or nil
    local medical = snapshot and snapshot.medicalCareState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local medicalPhase = tostring(medical and medical.phase or "idle")
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
    end
    if medicalPhase ~= "treating" then
        modData.PNC_ClientMedicalCareSoundKey = nil
    end
    if phase == "bandaging" then
        soundKey = tostring(treatment.partId or "")
            .. ":" .. tostring(treatment.startedAt or 0)
        if modData.PNC_ClientTreatmentSoundKey == soundKey then return end
    elseif medicalPhase == "treating" then
        soundKey = tostring(medical.taskId or "")
            .. ":" .. tostring(medical.partId or "")
            .. ":" .. tostring(medical.startedAt or 0)
        if modData.PNC_ClientMedicalCareSoundKey == soundKey then return end
    else
        return
    end
    emitter = emitter
        or zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        if phase == "bandaging" then
            modData.PNC_ClientTreatmentSoundKey = soundKey
        else
            modData.PNC_ClientMedicalCareSoundKey = soundKey
        end
    end
end

local function getTreatmentPresentation(snapshot)
    local treatment = snapshot and snapshot.treatmentState or nil
    local medical = snapshot and snapshot.medicalCareState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local medicalPhase = tostring(medical and medical.phase or "idle")
    local partId
    local key
    local anim
    if medicalPhase == "treating" then
        partId = tostring(medical.partId or "")
        key = "medical:" .. tostring(medical.taskId or "")
            .. ":" .. partId .. ":" .. tostring(medical.startedAt or 0)
        return {
            key = key,
            source = "medical",
            anim = tostring(medical.bump or "Loot"),
            lootPosition = medical.lootPosition or "Mid",
            targetId = medical.patientId,
            finishAt = tonumber(medical.finishAt) or 0,
        }
    end
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
        source = "self",
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
        if modData.PNC_ClientTreatmentAnimKey == nil
            and modData.PNC_ClientMedicalCareAnimKey == nil
        then
            return false, false
        end
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientTreatmentAnimKey = nil
        modData.PNC_ClientMedicalCareAnimKey = nil
        return false, true
    end
    if presentation.source == "medical" then
        modData.PNC_ClientTreatmentAnimKey = nil
    else
        modData.PNC_ClientMedicalCareAnimKey = nil
    end
    if presentation.source == "medical" then
        if zombie and zombie.setVariable then
            zombie:setVariable(
                "LootPosition", presentation.lootPosition or "Mid")
        end
        if zombie and zombie.faceThisObject then
            local patient = patientBody(presentation.targetId)
            if patient then zombie:faceThisObject(patient) end
        end
    end
    local currentKey = presentation.source == "medical"
        and modData.PNC_ClientMedicalCareAnimKey
        or modData.PNC_ClientTreatmentAnimKey
    if currentKey ~= presentation.key then
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
        if presentation.source == "medical" then
            modData.PNC_ClientMedicalCareAnimKey = presentation.key
        else
            modData.PNC_ClientTreatmentAnimKey = presentation.key
        end
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
