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

local PATIENT_DRIFT_CANCEL_SQ = 1.8 * 1.8
local REQUEUE_BACKOFF_MS = {
    patient_moved_away = 4000,
    combat_active = 3000,
}

local function releasePatientHold(state)
    if type(state) ~= "table" or state.patientKind ~= "npc" or state.patientId == nil then return end
    local patient = Registry and Registry.Get and Registry.Get(state.patientId) or nil
    if type(patient) == "table" and type(patient.runtime) == "table" then
        if patient.runtime.receivingMedicalCareBy == state.actorId
            or patient.runtime.receivingMedicalCareTaskId == state.taskId
        then
            patient.runtime.receivingMedicalCareBy = nil
            patient.runtime.receivingMedicalCareTaskId = nil
            patient.runtime.receivingMedicalCareUntil = nil
        end
    end
end

local function holdPatientForTreatment(record, body, task, patient, patientBody, finishAt)
    if not patient then return end
    if task.patientKind == "player" then
        -- Stop the player's current timed action so they stop working while being bandaged.
        if type(ISTimedActionQueue) == "table" and type(ISTimedActionQueue.clear) == "function" then
            pcall(ISTimedActionQueue.clear, patient)
        elseif type(patient.StopAllActionQueue) == "function" then
            pcall(patient.StopAllActionQueue, patient)
        end
        return
    end
    if type(patient) == "table" then
        patient.runtime = type(patient.runtime) == "table" and patient.runtime or {}
        patient.runtime.receivingMedicalCareBy = record and record.id or nil
        patient.runtime.receivingMedicalCareTaskId = task and task.id or nil
        patient.runtime.receivingMedicalCareUntil = finishAt
        if Common and Common.HaltMovement then
            Common.HaltMovement(patient, patientBody, "receiving_medical_care")
        end
        Internal.Face(patientBody, body)
    end
end

local function speakTreatmentInterrupted(record, patient, patientKind, partId, role, now)
    if Internal.SpeakTreatmentInterrupted then
        return Internal.SpeakTreatmentInterrupted(record, patient, patientKind, partId, role, now)
    end
    return false
end

local function clearRuntime(record, body, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.medicalCare or nil
    releasePatientHold(state)
    if body then
        if Animation and Animation.FinishBump then
            Animation.FinishBump(body, true)
        end
        if body.setVariable then
            body:setVariable("LootPosition", "")
        end
        local modData = body.getModData and body:getModData() or nil
        if type(modData) == "table" then
            modData.PNC_ClientMedicalCareAnimKey = nil
            modData.PNC_ClientMedicalCareSoundKey = nil
        end
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
    if patient then remaining = Internal.Treatable(patient, task) end
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

local function treatmentOptions(task, state)
    return {
        consumeItem = task.policy ~= nil
            and task.policy.requireItem == true or false,
        bandageType = state and state.bandageType or nil,
        consumeReason = "medical_care",
        syncEvent = "npc_treated",
    }
end

local function failForSupply(lease, task, record, body)
    local changed = Service.SetPhase(task.id, Status.WAITING_FOR_SUPPLY, {
        clearActor = true,
        clearReservation = true,
        blockedReason = "missing_bandage",
        supplyRequesterId = tostring(lease.npcId),
    })
    clearRuntime(record, body, "missing_bandage")
    PNC.Tasking.Commands.CancelForNPC(lease.npcId, "MEDICAL_SUPPLY_REQUIRED")
    if changed and Executor.RequestBandageSupport then
        Executor.RequestBandageSupport(task.id)
    end
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
    local partId, entry = Internal.CurrentPart(patient, task)
    local plan = Treatment and Treatment.GetNPCBandagePlan
        and Treatment.GetNPCBandagePlan(record, treatmentOptions(task))
        or nil
    local lootPosition
    local state
    if not partId then return false, "patient_wound_resolved" end
    if task.policy and task.policy.requireItem == true and not plan then
        return false, "missing_bandage"
    end
    lootPosition = Internal.ResolveLootPosition(patient, partId, patientBody)
    state = record.runtime.medicalCare or {}
    state.phase = "treating"
    state.actorId = record.id
    state.taskId = task.id
    state.patientId = task.patientId or patient.id
    state.patientKind = task.patientKind
    state.partId = partId
    local px, py, pz = Internal.Position(patient, patientBody)
    state.patientStartX, state.patientStartY, state.patientStartZ = px, py, pz
    state.dirtyChange = (task.patientKind == "player" and entry and entry.dirty == true)
        or (entry and entry.wound and entry.wound.bandageDirty == true) or false
    state.playerPartInfo = task.patientKind == "player" and entry or nil
    state.lootPosition = lootPosition
    state.bump = Internal.ResolveLootBump(lootPosition)
    state.bandageType = plan and plan.requiresItem == true
        and plan.fullType or nil
    state.bandageName = plan and plan.requiresItem == true
        and plan.displayName or nil
    state.startedAt = now
    state.finishAt = now + Treatment.GetNPCBandageDuration(record)
    state.revision = (tonumber(state.revision) or 0) + 1
    record.runtime.medicalCare = state
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    Common.HaltMovement(record, body, "medical_care_treating")
    holdPatientForTreatment(record, body, task, patient, patientBody, state.finishAt)
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
    local soundKey = tostring(task.id) .. ":" .. tostring(partId)
        .. ":" .. tostring(state.startedAt)
    local animationKey = "medical:" .. soundKey
    if modData then
        modData.PNC_ClientMedicalCareAnimKey = animationKey
    end
    local emitter = body and body.getEmitter and body:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        if modData then modData.PNC_ClientMedicalCareSoundKey = soundKey end
    end
    record.runtime.forceSyncEvent = "medical_care_treating"
    Service.SetPhase(task.id, Status.TREATING, { actorId = lease.npcId })
    setLeasePhase(lease, "WORKING")
    if Internal.SpeakTreatmentStart then
        Internal.SpeakTreatmentStart(record, patient, task.patientKind, partId, state.dirtyChange == true, now)
    end
    local callouts = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if task.patientKind == "npc" and callouts and type(callouts.OnAllyBandagingUnderThreat) == "function" then
        callouts.OnAllyBandagingUnderThreat(record, patient, now)
    end
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
    if task.patientKind == "player" then
        local _, freshInfo = Internal.CurrentPart(patient, task)
        local pInfo = state.playerPartInfo or freshInfo
        if Internal.ApplyNPCTreatmentToPlayer then
            applied, reason = Internal.ApplyNPCTreatmentToPlayer(record, patient, pInfo, treatmentOptions(task, state))
        else
            applied, reason = false, "player_treatment_unavailable"
        end
    else
        applied, reason = Treatment.TryNPCMedicalTreatment(
            record, patient, state.partId, treatmentOptions(task, state))
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
    if Internal.SpeakTreatmentComplete then
        Internal.SpeakTreatmentComplete(record, patient, task.patientKind, state.partId,
            state.dirtyChange == true, PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
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
    local started
    local startReason
    if not task then return false, "medical_task_missing" end
    body = record and Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    if not record or record.alive == false then
        clearRuntime(record, body, "medical_actor_unavailable")
        Service.Cancel(task.id, "medical_actor_unavailable")
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "MEDICAL_ACTOR_UNAVAILABLE")
        return false, "medical_actor_unavailable"
    end
    patient = Internal.Patient(task)
    local pDead = patient and (task.patientKind == "player" and patient.isDead and patient:isDead() == true or task.patientKind ~= "player" and patient.alive == false)
    if not patient or pDead then
        clearRuntime(record, body, "medical_patient_unavailable")
        Service.Cancel(task.id, "medical_patient_unavailable")
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "MEDICAL_PATIENT_UNAVAILABLE")
        return false, "medical_patient_unavailable"
    end
    local curState = record.runtime and record.runtime.medicalCare or nil
    local hasTreatable = false
    if task.patientKind == "player"
        and curState and curState.phase == "treating"
        and curState.playerPartInfo
        and Internal.IsPlayerPartStillTreatable
        and Internal.IsPlayerPartStillTreatable(curState.playerPartInfo)
    then
        hasTreatable = true
    else
        hasTreatable = Internal.CurrentPart(patient, task) ~= nil
    end
    if not hasTreatable then
        clearRuntime(record, body, "patient_wound_resolved")
        Service.Complete(task.id, "patient_wound_resolved")
        PNC.Tasking.Commands.Complete(lease.leaseId, "patient_wound_resolved")
        return true
    end
    local medicInCombat = Internal.combatActive and Internal.combatActive(record)
    local patientInCombat = task.patientKind == "npc" and Internal.combatActive and Internal.combatActive(patient)
    if medicInCombat or patientInCombat then
        if curState and curState.phase == "treating" then
            speakTreatmentInterrupted(record, patient, task.patientKind, curState.partId, "hostile_interrupted", now)
        end
        Executor.Cancel(lease, "combat_active")
        if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelForNPC then
            PNC.Tasking.Commands.CancelForNPC(lease.npcId, "COMBAT_ACTIVE")
        end
        return false, "combat_active"
    end
    patientBody = task.patientKind == "player" and patient
        or (Registry.GetLiveZombie and Registry.GetLiveZombie(patient.id) or nil)
    if not body or not patientBody then
        if task.patientKind == "player" then return false, "player_body_unavailable" end
        return treatAbstract(lease, task, record)
    end
    record.runtime = record.runtime or {}
    record.runtime.medicalCare = record.runtime.medicalCare or {
        phase = "traveling", taskId = task.id, patientId = task.patientId or patient.id, patientKind = task.patientKind,
    }
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    state = record.runtime.medicalCare
    if state.phase == "treating" then
        -- Cancel cleanly if the patient (player or NPC) moved away mid-treatment.
        local px, py, pz = Internal.Position(patient, patientBody)
        local drifted = false
        if state.patientStartX ~= nil and state.patientStartY ~= nil then
            local dx, dy = px - state.patientStartX, py - state.patientStartY
            local dz = math.abs(pz - (tonumber(state.patientStartZ) or pz))
            if dz >= 1 or (dx * dx + dy * dy) > PATIENT_DRIFT_CANCEL_SQ then
                drifted = true
            end
        end
        if drifted or not Internal.InTreatmentRange(record, body, patient, patientBody) then
            local partId = state.partId
            Executor.Cancel(lease, "patient_moved_away")
            if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelForNPC then
                PNC.Tasking.Commands.CancelForNPC(lease.npcId, "PATIENT_MOVED_AWAY")
            end
            speakTreatmentInterrupted(record, patient, task.patientKind, partId, "patient_moved_away", now)
            return false, "patient_moved_away"
        end
        if task.patientKind == "npc" then
            if patient.runtime and patient.runtime.moveIntent ~= nil and Common and Common.HaltMovement then
                Common.HaltMovement(patient, patientBody, "receiving_medical_care")
            end
            Internal.Face(patientBody, body)
        end
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
        started, startReason = beginTreatment(
            lease, task, record, body, patient, patientBody, now)
        if not started and startReason == "missing_bandage" then
            return failForSupply(lease, task, record, body)
        end
        return started, startReason
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
        Service.Requeue(task.id, reason or "medical_care_cancelled",
            REQUEUE_BACKOFF_MS[tostring(reason or "")])
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
