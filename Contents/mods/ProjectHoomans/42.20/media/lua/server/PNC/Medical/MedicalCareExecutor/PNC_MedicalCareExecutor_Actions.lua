if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.MedicalCareExecutor
local Internal = Executor.Internal
local Service = PNC.MedicalCareService
local Status = PNC.MedicalCareRepository.STATUS
local Registry = PNC.Registry
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local Treatment = PNC.Treatment

local function clearRuntime(record, body, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.medicalCare or nil
    if body and state and state.phase == "treating"
        and Animation and Animation.FinishBump
    then
        Animation.FinishBump(body, true)
    end
    if record and Common and Common.HaltMovement then
        Common.HaltMovement(record, body, reason or "medical_care_end")
    end
    if runtime then
        runtime.medicalCare = nil
        if runtime.tacticalState == "medical_care" then
            runtime.tacticalState = nil
        end
    end
    if record and record.activeBehavior == "MedicalCare" then
        record.activeBehavior = nil
    end
    if runtime then
        runtime.forceSyncEvent = "medical_care_ended"
    end
end

local function setLeasePhase(lease, phase)
    if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, phase)
    end
end

local function finishRequest(lease, task, record, body, reason)
    local patient = Internal.Patient(task)
    local remaining
    clearRuntime(record, body, reason)
    if patient then remaining = Internal.Treatable(patient) end
    local current = Service.Get(task.id)
    if current and not Service.TERMINAL[current.status] then
        if remaining and #remaining > 0 then
            Service.MarkProgress(task.id)
            Service.SetPhase(task.id, Status.CLAIMED, {
                actorId = lease.npcId,
                clearReservation = true,
            })
        else
            Service.Complete(task.id, reason or "treatment_completed")
        end
    end
    if not remaining or #remaining == 0 then
        return PNC.Tasking.Commands.Complete(
            lease.leaseId, reason or "treatment_completed")
    end
    return true
end

local function treatmentOptions(task)
    return {
        consumeItem = task.policy ~= nil
            and task.policy.requireItem == true or false,
        consumeReason = "medical_care",
        syncEvent = "npc_treated",
    }
end

local function failForSupply(lease, task, record, body)
    Service.SetPhase(task.id, Status.WAITING_FOR_SUPPLY, {
        clearActor = true,
        clearReservation = true,
        blockedReason = "missing_bandage",
    })
    clearRuntime(record, body, "missing_bandage")
    PNC.Tasking.Commands.CancelForNPC(lease.npcId, "MEDICAL_SUPPLY_REQUIRED")
    return false, "waiting_for_supply"
end

local function treatAbstract(lease, task, record)
    local patient = Internal.Patient(task)
    local partId = Internal.CurrentPart(patient)
    local applied, reason
    if not partId then
        Service.Complete(task.id, "patient_wound_resolved")
        PNC.Tasking.Commands.Complete(lease.leaseId, "patient_wound_resolved")
        return true
    end
    setLeasePhase(lease, "WORKING")
    Service.SetPhase(task.id, Status.TREATING, { actorId = lease.npcId })
    applied, reason = Treatment.TryNPCMedicalTreatment(
        record, patient, partId, treatmentOptions(task))
    if not applied then
        if reason == "missing_bandage" then
            return failForSupply(lease, task, record, nil)
        end
        Service.Requeue(task.id, reason or "medical_treatment_failed")
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            reason or "MEDICAL_TREATMENT_FAILED")
        return false, reason
    end
    return finishRequest(lease, task, record, nil, "treatment_completed")
end

local function beginTreatment(lease, task, record, body, patient, patientBody, now)
    local partId = Internal.CurrentPart(patient)
    local lootPosition
    local state
    if not partId then return false, "patient_wound_resolved" end
    lootPosition = Internal.ResolveLootPosition(patient, partId, patientBody)
    state = record.runtime.medicalCare or {}
    state.phase = "treating"
    state.taskId = task.id
    state.patientId = patient.id
    state.partId = partId
    state.lootPosition = lootPosition
    state.bump = Internal.ResolveLootBump(lootPosition)
    state.startedAt = now
    state.finishAt = now + Treatment.GetNPCBandageDuration(record)
    state.revision = (tonumber(state.revision) or 0) + 1
    record.runtime.medicalCare = state
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    Common.HaltMovement(record, body, "medical_care_treating")
    Internal.Face(body, patientBody)
    if body and body.setVariable then
        body:setVariable("LootPosition", lootPosition)
    end
    if body and Animation and Animation.PlayBump then
        Animation.PlayBump(body, record, state.bump, {
            leaseUntil = state.finishAt,
        })
    end
    local modData = body and body.getModData and body:getModData() or nil
    local animationKey = tostring(task.id) .. ":" .. tostring(partId)
        .. ":" .. tostring(state.startedAt)
    if modData then
        modData.PNC_ClientMedicalCareAnimKey = animationKey
    end
    local emitter = body and body.getEmitter and body:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        if modData then modData.PNC_ClientMedicalCareSoundKey = animationKey end
    end
    record.runtime.forceSyncEvent = "medical_care_treating"
    Service.SetPhase(task.id, Status.TREATING, { actorId = lease.npcId })
    setLeasePhase(lease, "WORKING")
    return true
end

local function finishLiveTreatment(lease, task, record, body)
    local state = record.runtime and record.runtime.medicalCare or nil
    local patient = Internal.Patient(task)
    local applied
    local reason
    if not state or state.phase ~= "treating" then
        return false, "medical_treatment_state_missing"
    end
    applied, reason = Treatment.TryNPCMedicalTreatment(
        record, patient, state.partId, treatmentOptions(task))
    if body and Animation and Animation.FinishBump then
        Animation.FinishBump(body, true)
    end
    if not applied then
        if reason == "missing_bandage" then
            return failForSupply(lease, task, record, body)
        end
        Service.Requeue(task.id, reason or "medical_treatment_failed")
        clearRuntime(record, body, reason)
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            reason or "MEDICAL_TREATMENT_FAILED")
        return false, reason
    end
    return finishRequest(lease, task, record, body, "treatment_completed")
end

function Executor.Tick(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease.npcId) or nil
    local patient
    local patientBody
    local body
    local now = PNC.Core.Now()
    local state
    local moved
    local movement
    if not task then return false, "medical_task_missing" end
    if not record or record.alive == false then
        Service.Cancel(task.id, "medical_actor_unavailable")
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "MEDICAL_ACTOR_UNAVAILABLE")
        return false, "medical_actor_unavailable"
    end
    patient = Internal.Patient(task)
    if not patient or patient.alive == false then
        Service.Cancel(task.id, "medical_patient_unavailable")
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "MEDICAL_PATIENT_UNAVAILABLE")
        return false, "medical_patient_unavailable"
    end
    if not Internal.CurrentPart(patient) then
        Service.Complete(task.id, "patient_wound_resolved")
        PNC.Tasking.Commands.Complete(lease.leaseId, "patient_wound_resolved")
        return true
    end
    body = Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    patientBody = Registry.GetLiveZombie
        and Registry.GetLiveZombie(patient.id) or nil
    if not body or not patientBody then
        return treatAbstract(lease, task, record)
    end
    record.runtime = record.runtime or {}
    record.runtime.medicalCare = record.runtime.medicalCare or {
        phase = "traveling", taskId = task.id, patientId = patient.id,
    }
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    state = record.runtime.medicalCare
    if state.phase == "treating" then
        Internal.Face(body, patientBody)
        if now < (tonumber(state.finishAt) or 0) then
            if Animation and Animation.MaintainBump then
                Animation.MaintainBump(body, record, state.bump, state.finishAt)
            end
            return true
        end
        return finishLiveTreatment(lease, task, record, body)
    end
    if Internal.InTreatmentRange(record, body, patient, patientBody) then
        Service.SetPhase(task.id, Status.AT_PATIENT, { actorId = lease.npcId })
        return beginTreatment(lease, task, record, body, patient, patientBody, now)
    end
    if task.status ~= Status.TRAVELING then
        Service.SetPhase(task.id, Status.TRAVELING, {
            actorId = lease.npcId,
            clearBlockedReason = true,
        })
    end
    setLeasePhase(lease, "TRAVEL")
    moved, movement = Common.MoveRecord(record, body,
        patientBody:getX(), patientBody:getY(), patientBody:getZ(),
        "walk", 1.2, "medical_care")
    if not moved then return false, movement or "medical_move_failed" end
    state.lastObservedAt = now
    local x, y, z = body:getX(), body:getY(), body:getZ()
    if state.lastObservedX
        and ((x - state.lastObservedX) * (x - state.lastObservedX)
            + (y - state.lastObservedY) * (y - state.lastObservedY)
            + (z - state.lastObservedZ) * (z - state.lastObservedZ)) > 0.01
    then
        Service.MarkProgress(task.id)
    end
    state.lastObservedX, state.lastObservedY, state.lastObservedZ = x, y, z
    return true
end

function Executor.Cancel(lease, reason)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    local body = record and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    clearRuntime(record, body, reason or "medical_care_cancelled")
    if task and not Service.TERMINAL[task.status]
        and task.status ~= Status.WAITING_FOR_SUPPLY
    then
        Service.Requeue(task.id, reason or "medical_care_cancelled")
    end
    return true
end

function Executor.Complete(lease, reason)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    local body = record and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    clearRuntime(record, body, reason or "medical_care_complete")
    return true
end

return Executor
