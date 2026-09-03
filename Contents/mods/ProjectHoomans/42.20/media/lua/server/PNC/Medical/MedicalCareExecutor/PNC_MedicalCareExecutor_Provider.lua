if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.MedicalCareExecutor
local Internal = Executor.Internal
local Service = PNC.MedicalCareService
local Repository = PNC.MedicalCareRepository
local Status = Repository.STATUS
local Const = PNC.Const
local Types = PNC.Types
local Treatment = PNC.Treatment
local Wounds = PNC.NPCWounds
local Registry = PNC.Registry
local Common = PNC.BehaviorCommon
local Recovery = PNC.Tasking and PNC.Tasking.Internal
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"

local LOW_PARTS = {
    Groin = true,
    UpperLeg_L = true, UpperLeg_R = true,
    LowerLeg_L = true, LowerLeg_R = true,
    Foot_L = true, Foot_R = true,
}

local HIGH_PARTS = { Head = true, Neck = true }

local function id(value)
    return value == nil and nil or tostring(value)
end

local function nonempty(value)
    value = id(value)
    return value and value ~= "" and value or nil
end

local function affiliation(record)
    return record and record.affiliation or {}
end

local function factionId(record)
    local source = affiliation(record)
    return nonempty(source.factionID or source.factionId
        or record and (record.factionID or record.factionId))
end

local function communityId(record)
    local source = affiliation(record)
    return nonempty(source.communityID or source.communityId
        or record and (record.communityID or record.communityId))
end

local function ownerKey(record)
    return nonempty(record and record.ownerOnlineID)
        or nonempty(record and record.ownerUsername)
end

function Internal.IsDoctor(record)
    local source = affiliation(record)
    local role = string.lower(tostring(
        source.role or source.communityRole or record and record.communityRole
            or ""))
    local archetype = string.lower(tostring(record and record.archetypeID or ""))
    if not WorkPolicy.IsEnabled(record, "MedicalCare") then return false end
    local jobs = record and record.allowedJobs or nil
    return role == "medic" or role == "caregiver"
        or archetype == "doctor"
        or jobs and jobs.MedicalCare == true
end

function Internal.SameCareGroup(actor, patient)
    local actorFaction = factionId(actor)
    local patientFaction = factionId(patient)
    local actorCommunity = communityId(actor)
    local patientCommunity = communityId(patient)
    local actorOwner = ownerKey(actor)
    local patientOwner = ownerKey(patient)
    if actorFaction and patientFaction then
        return actorFaction == patientFaction
    end
    if actorCommunity and patientCommunity then
        return actorCommunity == patientCommunity
    end
    if actorOwner and patientOwner then
        return actorOwner == patientOwner
    end
    return Types and Types.IsColonist
        and Types.IsColonist(actor) and Types.IsColonist(patient) or false
end

function Internal.Patient(task)
    if not task or task.patientKind ~= "npc" then return nil end
    return Registry and Registry.Get and Registry.Get(task.patientId) or nil
end

function Internal.Treatable(patient)
    if not patient or not Wounds
        or not Wounds.GetTreatableWounds
    then
        return {}
    end
    return Wounds.GetTreatableWounds(patient)
end

function Internal.CurrentPart(patient)
    local entries = Internal.Treatable(patient)
    return entries[1] and tostring(entries[1].partId) or nil
end

function Internal.CanTreat(actor, task)
    local patient
    local plan
    if not actor or actor.alive == false or not Internal.IsDoctor(actor) then
        return false, "doctor_unavailable"
    end
    if task and task.actorId and tostring(task.actorId) ~= tostring(actor.id) then
        return false, "claimed_by_other_doctor"
    end
    patient = Internal.Patient(task)
    if not patient or patient.alive == false then
        return false, "patient_unavailable"
    end
    if tostring(patient.id) == tostring(actor.id) then
        return false, "self_treatment_is_not_doctor_care"
    end
    if not Internal.SameCareGroup(actor, patient) then
        return false, "care_group_mismatch"
    end
    if not Internal.CurrentPart(patient) then
        return false, "patient_has_no_treatable_wound"
    end
    plan = Treatment and Treatment.GetNPCBandagePlan
        and Treatment.GetNPCBandagePlan(actor, {
            consumeItem = task and task.policy
                and task.policy.requireItem == true,
        }) or nil
    if not plan then return false, "missing_bandage" end
    return true, patient
end

function Internal.Position(record, body)
    return body and body.getX and body:getX() or tonumber(record and record.x) or 0,
        body and body.getY and body:getY() or tonumber(record and record.y) or 0,
        body and body.getZ and body:getZ() or tonumber(record and record.z) or 0
end

function Internal.InTreatmentRange(actor, actorBody, patient, patientBody)
    local ax, ay, az = Internal.Position(actor, actorBody)
    local px, py, pz = Internal.Position(patient, patientBody)
    local range = tonumber(Const and Const.BANDAGE_RANGE) or 3
    if math.abs(az - pz) >= 1 then return false end
    return (ax - px) * (ax - px) + (ay - py) * (ay - py)
        <= range * range
end

function Internal.ResolveLootPosition(patient, partId, patientBody)
    local health = patient and patient.health or {}
    local downed = tostring(health.state or "") == "incapacitated"
        or patientBody and patientBody.isOnFloor
        and patientBody:isOnFloor() == true
    partId = tostring(partId or "")
    if downed or LOW_PARTS[partId] then return "Low" end
    if HIGH_PARTS[partId] then return "High" end
    return "Mid"
end

function Internal.ResolveLootBump(lootPosition)
    if lootPosition == "Low" then return "LootLow" end
    if lootPosition == "High" then return "LootHigh" end
    return "Loot"
end

function Internal.Face(actorBody, patientBody)
    if actorBody and patientBody and actorBody.faceThisObject then
        actorBody:faceThisObject(patientBody)
    end
end

function Executor.GetCandidates(npcId)
    local actor = Registry and Registry.Get and Registry.Get(npcId) or nil
    local candidates = {}
    local at = PNC.Core.Now()
    if not actor or not Internal.IsDoctor(actor) then return candidates end
    for _, task in ipairs(Service.List(false)) do
        local ready = (tonumber(task.retryAt) or 0) <= at
        local supplyReady = task.status == Status.WAITING_FOR_SUPPLY
            and Treatment.HasNPCBandage(actor)
        if (ready and task.status ~= Status.WAITING_FOR_SUPPLY)
            or supplyReady
        then
            local valid = Internal.CanTreat(actor, task)
            if valid then
                candidates[#candidates + 1] = {
                    taskId = "medical_care:" .. tostring(task.id)
                        .. ":" .. tostring(npcId),
                    npcId = tostring(npcId),
                    kind = "MEDICAL_CARE",
                    sourceDomain = "medical",
                    sourceRef = task.id,
                    precedence = (tonumber(task.priority) or 0) >= 100
                        and "CRITICAL_NEED" or "NORMAL_NEED",
                    urgency = math.max(0, math.min(1,
                        (tonumber(task.priority) or 0) / 100)),
                    workPriority = WorkPolicy.GetPriority(actor, "MedicalCare"),
                    capability = "MEDICAL_CARE",
                    interruptPolicy = "NORMAL",
                    revision = task.revision,
                    createdAt = task.createdAt,
                }
                break
            end
        end
    end
    return candidates
end

function Executor.Validate(intent)
    local actor = Registry and Registry.Get and Registry.Get(intent and intent.npcId) or nil
    local task = Service.Get(intent and intent.sourceRef)
    if not task or Service.TERMINAL[task.status] then return false end
    return Internal.CanTreat(actor, task) == true
end

function Executor.Assign(intent)
    local task = Service.Get(intent and intent.sourceRef)
    local actorId = intent and tostring(intent.npcId or "") or ""
    local actor = Registry and Registry.Get and Registry.Get(actorId) or nil
    local valid = task and actor and Internal.CanTreat(actor, task)
    local changed
    if not valid then return nil, "medical_task_invalid" end
    if task.actorId and tostring(task.actorId) ~= actorId then
        return nil, "medical_task_claimed"
    end
    changed = Service.SetPhase(task.id, Status.CLAIMED, {
        actorId = actorId,
        clearReservation = true,
        clearBlockedReason = true,
    })
    if not changed then return nil, "medical_task_claim_failed" end
    return {
        executionMode = "LIVE",
        resourceKey = task.id,
        resourceKind = "MEDICAL_CARE",
    }
end

function Executor.Start(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease.npcId) or nil
    local now = PNC.Core.Now()
    if not task or not record then return false, "medical_actor_unavailable" end
    record.runtime = record.runtime or {}
    record.runtime.medicalCare = {
        phase = "traveling",
        taskId = task.id,
        patientId = task.patientId,
        startedAt = now,
        lastObservedAt = now,
    }
    record.runtime.forceSyncEvent = "medical_care_started"
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, "TRAVEL")
    end
    Service.SetPhase(task.id, Status.TRAVELING, {
        actorId = lease.npcId,
        clearBlockedReason = true,
    })
    return true
end

function Executor.CanContinue(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    if not task or Service.TERMINAL[task.status] then return false end
    if not record or record.alive == false then return false end
    return tostring(task.actorId or "") == tostring(lease and lease.npcId or "")
end

function Executor.GetRecoveryState(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    local snapshot
    if not task or Service.TERMINAL[task.status] then return { terminal = true } end
    snapshot = {
        phase = "WAITING",
        lastProgressAt = task.lastProgressAt or lease and lease.lastProgressAt,
        watchable = false,
    }
    if task.status == Status.TRAVELING then
        snapshot.phase = "TRAVEL"
        snapshot.watchable = true
        if Recovery and Recovery.ApplyMovementRecovery then
            snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record)
        end
    elseif task.status == Status.AT_PATIENT
        or task.status == Status.TREATING
    then
        snapshot.phase = "WORKING"
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "medical_treatment_timeout"
    end
    return snapshot
end

return Executor
