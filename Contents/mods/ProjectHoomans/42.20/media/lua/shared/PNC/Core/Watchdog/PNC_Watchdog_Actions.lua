-- Unified actor-side committed action watchdog probes.

PNC = PNC or {}
PNC.Watchdog = PNC.Watchdog or {}

local Watchdog = PNC.Watchdog
local Core = PNC.Core
local DEFAULT_ACTION_GRACE_MS = 1500
local DEFAULT_ACTION_CAP_MS = 15000

local function recoverAttackAction(record, zombie, now)
    local runtime = record and record.runtime or nil
    local action = runtime and runtime.attackAction or nil
    if type(action) ~= "table" then return false end
    if not Watchdog.IsDeadlineStale(
        action.startedAt, action.finishAt, now, 1000, 10000
    ) then
        return false
    end
    if PNC.Combat and PNC.Combat.CancelAttackAction then
        PNC.Combat.CancelAttackAction(
            record, zombie, nil, "combat_action_timeout"
        )
    else
        runtime.attackAction = nil
        if zombie and PNC.Animation and PNC.Animation.FinishBump then
            PNC.Animation.FinishBump(zombie, true)
        end
    end
    Watchdog.Record("attack", record.id, "combat_action_timeout", "recovered")
    return true
end

local function recoverSelfTreatment(record, zombie, now)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.selfTreatment or nil
    if type(state) ~= "table" or state.phase ~= "bandaging" then
        return false
    end
    if not Watchdog.IsDeadlineStale(
        state.startedAt, state.finishAt, now,
        DEFAULT_ACTION_GRACE_MS, DEFAULT_ACTION_CAP_MS
    ) then
        return false
    end
    if zombie and PNC.Animation and PNC.Animation.FinishBump then
        PNC.Animation.FinishBump(zombie, true)
    end
    state.phase = "idle"
    state.partId = nil
    state.bandageType = nil
    state.useSplint = nil
    state.bandageName = nil
    state.startedAt = 0
    state.finishAt = 0
    state.interruptedReason = "watchdog_self_treatment_timeout"
    if runtime.tacticalState == "self_bandage" then
        runtime.tacticalState = nil
    end
    runtime.forceSyncEvent = "self_treatment_interrupted"
    Watchdog.Record(
        "self_treatment", record.id, "self_treatment_timeout", "recovered"
    )
    return true
end

local function recoverMedicalCare(record, zombie, now)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.medicalCare or nil
    if type(state) ~= "table" or state.phase ~= "treating" then
        return false
    end
    if not Watchdog.IsDeadlineStale(
        state.startedAt, state.finishAt, now,
        DEFAULT_ACTION_GRACE_MS, DEFAULT_ACTION_CAP_MS
    ) then
        return false
    end
    if zombie then
        if PNC.Animation and PNC.Animation.FinishBump then
            PNC.Animation.FinishBump(zombie, true)
        end
        if zombie.setVariable then
            zombie:setVariable("LootPosition", "")
        end
    end
    if state.patientKind == "npc" and state.patientId ~= nil
        and PNC.Registry and PNC.Registry.Get
    then
        local patient = PNC.Registry.Get(state.patientId)
        if patient and patient.runtime
            and patient.runtime.receivingMedicalCareBy == record.id
        then
            patient.runtime.receivingMedicalCareBy = nil
            patient.runtime.receivingMedicalCareTaskId = nil
            patient.runtime.receivingMedicalCareUntil = nil
        end
    end
    runtime.medicalCare = nil
    if runtime.tacticalState == "medical_care" then
        runtime.tacticalState = nil
    end
    if record.activeBehavior == "MedicalCare" then
        record.activeBehavior = nil
    end
    runtime.forceSyncEvent = "medical_care_ended"
    Watchdog.Record(
        "medical_care", record.id, "medical_care_pose_timeout", "recovered"
    )
    return true
end

local function recoverPatientHold(record, now)
    local runtime = record and record.runtime or nil
    if not runtime or runtime.receivingMedicalCareBy == nil then
        return false
    end
    local untilAt = tonumber(runtime.receivingMedicalCareUntil) or 0
    local expired = untilAt <= 0 or now >= untilAt + DEFAULT_ACTION_GRACE_MS
    if not expired and PNC.Registry and PNC.Registry.Get then
        local medic = PNC.Registry.Get(runtime.receivingMedicalCareBy)
        local medicCare = medic and medic.runtime
            and medic.runtime.medicalCare or nil
        if not medic or medic.alive == false
            or not medicCare or medicCare.phase ~= "treating"
        then
            expired = true
        end
    end
    if not expired then return false end
    runtime.receivingMedicalCareBy = nil
    runtime.receivingMedicalCareTaskId = nil
    runtime.receivingMedicalCareUntil = nil
    Watchdog.Record(
        "medical_patient_hold", record.id, "patient_hold_expired", "recovered"
    )
    return true
end

local function recoverAnimationScene(record, zombie, now)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    if type(scene) ~= "table" then return false end
    local stale = false
    local reason = nil
    local finishAt = tonumber(scene.finishAt) or 0
    if scene.loop ~= true and finishAt > 0 and now >= finishAt + 2000 then
        stale = true
        reason = "animation_scene_deadline_expired"
    elseif tostring(scene.id or "") == "social.conversation" then
        local convo = PNC.Conversation
        local active = convo and convo.IsActive
            and convo.IsActive(record.id) == true
            or (runtime.conversationActive == true)
        if not active and finishAt <= 0
            and (tonumber(scene.stepStartedAt) or 0) > 0
            and (now - (tonumber(scene.stepStartedAt) or now)) >= 5000
        then
            stale = true
            reason = "conversation_scene_orphaned"
        end
    end
    if not stale then return false end
    if PNC.AnimationScenes and PNC.AnimationScenes.Stop then
        PNC.AnimationScenes.Stop(record, zombie, reason)
    else
        runtime.animationScene = nil
        if zombie and PNC.Animation and PNC.Animation.FinishBump then
            PNC.Animation.FinishBump(zombie, true)
        end
    end
    Watchdog.Record("animation_scene", record.id, reason, "recovered")
    return true
end

function Watchdog.RecoverCommittedActions(record, zombie, now)
    if not record or record.alive == false then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if recoverAttackAction(record, zombie, now) then return true end
    if recoverSelfTreatment(record, zombie, now) then return true end
    if recoverMedicalCare(record, zombie, now) then return true end
    if recoverAnimationScene(record, zombie, now) then return true end
    recoverPatientHold(record, now)
    return false
end

return Watchdog
