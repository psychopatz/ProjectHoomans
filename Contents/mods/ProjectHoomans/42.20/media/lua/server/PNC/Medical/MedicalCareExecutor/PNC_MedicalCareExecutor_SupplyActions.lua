if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC and PNC.MedicalCareExecutor
if not Executor then return end
local Internal = Executor.Internal
local Service = Internal.Service
local Status = Internal.Status
local Registry = Internal.Registry
local Treatment = Internal.Treatment
local combatActive = Internal.combatActive
local groupDoctors = Internal.groupDoctors
local requesterForTask = Internal.requesterForTask
local Common = Internal.Common
local Wounds = Internal.Wounds
local sendSupplyState = Internal.sendSupplyState
local SUPPLY_RETRY_MS = Internal.SUPPLY_RETRY_MS

function Executor.NotifyBandageSupportState(task, state)
    state = tostring(state or "")
    if state ~= "needed" and state ~= "fulfilled" and state ~= "resolved" then
        return false, "invalid_supply_state"
    end
    return sendSupplyState(task, state)
end

local function tryShareBandage(task)
    local patient = Internal.Patient(task)
    local requester = task and Registry and Registry.Get
        and Registry.Get(task.supplyRequesterId) or nil
    local donors
    if not patient or patient.alive == false or not requester
        or requester.alive == false or combatActive(requester)
    then
        return false, "medical_bandage_share_unavailable"
    end
    donors = {}
    if Registry and type(Registry.ForEach) == "function" then
        Registry.ForEach(function(record)
            if record and record.alive ~= false
                and tostring(record.id or "") ~= tostring(requester.id)
                and tostring(record.id or "") ~= tostring(patient.id)
                and not (record.health
                    and record.health.state == "incapacitated")
                and not combatActive(record)
                and Internal.SameCareGroup(record, patient)
            then
                donors[#donors + 1] = record
            end
        end)
    end
    table.sort(donors, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    for index = 1, #donors do
        local donor = donors[index]
        local plan = Treatment.GetNPCBandagePlan(donor, {
            consumeItem = true,
        })
        if plan and plan.requiresItem == true and plan.itemID
            and not combatActive(donor)
        then
            local transferred
            local transferService = PNC.ServerInventory
            if transferService
                and type(transferService.TransferMedicalBandageForTask)
                    == "function"
            then
                transferred = transferService.TransferMedicalBandageForTask(
                    task.id, donor.id, plan.itemID)
            end
            if transferred == true then return true end
        end
    end
    return false, "donor_bandage_unavailable"
end

function Executor.FulfillBandageSupport(taskID)
    local task = Service.Get(taskID)
    local patient = Internal.Patient(task)
    local doctors
    local available = false
    local physicalBandageAvailable = false
    local requireItem
    local plan
    if not task or task.status ~= Status.WAITING_FOR_SUPPLY then
        return false, "medical_supply_request_inactive"
    end
    if not patient then
        return false, "medical_supply_request_invalid"
    end
    doctors = groupDoctors(task, patient)
    requireItem = task.policy and task.policy.requireItem == true or false
    for index = 1, #doctors do
        plan = Treatment.GetNPCBandagePlan(doctors[index], {
            consumeItem = requireItem,
        })
        if plan then
            available = true
            if plan.requiresItem == true then
                physicalBandageAvailable = true
            end
        end
    end
    if not available then return false, "medical_supply_still_missing" end
    return Service.SetPhase(task.id, Status.WAITING_FOR_DOCTOR, {
        clearActor = true,
        clearReservation = true,
        clearBlockedReason = true,
        supplyResolution = physicalBandageAvailable
            and "fulfilled" or "resolved",
    })
end

function Executor.RequestBandageSupport(taskID)
    local task = Service.Get(taskID)
    local patient
    local doctors
    local requester
    local requestID
    local at
    local last
    local changed
    if not task or task.status ~= Status.WAITING_FOR_SUPPLY
    then
        return false, "medical_supply_request_inactive"
    end
    patient = Internal.Patient(task)
    if not patient or patient.alive == false then
        return false, "medical_patient_unavailable"
    end
    if not Internal.CurrentPart(patient) then
        Service.Complete(task.id, "patient_wound_resolved")
        return false, "patient_wound_resolved"
    end
    doctors = groupDoctors(task, patient)
    if #doctors == 0 then return false, "medical_doctor_unavailable" end
    requester = requesterForTask(task, doctors)
    if not requester then return false, "medical_doctor_unavailable" end
    if tostring(task.supplyRequesterId or "")
        ~= tostring(requester.id)
    then
        if task.supplyRequestId then
            Executor.NotifyBandageSupportState(task, "resolved")
        end
        changed = Service.SetPhase(task.id, Status.WAITING_FOR_SUPPLY, {
            clearActor = true,
            clearReservation = true,
            blockedReason = "missing_bandage",
            supplyRequesterId = tostring(requester.id),
            supplyRequestId = "medical-bandage:" .. tostring(task.id)
                .. ":" .. tostring((tonumber(task.revision) or 0) + 1),
        })
        if not changed then return false, "medical_supply_request_update_failed" end
        task = Service.Get(task.id)
    end
    if Executor.FulfillBandageSupport(task.id) then return true, "fulfilled" end
    requestID = tostring(task.supplyRequestId or "")
    if requestID == "" then return false, "medical_supply_request_invalid" end
    at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    last = lastSupplyAttemptAt[requestID]
    if last == nil or at - last >= SUPPLY_RETRY_MS then
        lastSupplyAttemptAt[requestID] = at
        local shared = tryShareBandage(task)
        if shared then
            local fulfilled = Executor.FulfillBandageSupport(task.id)
            if fulfilled then return true, "fulfilled" end
        end
    end
    Executor.NotifyBandageSupportState(task, "needed")
    return true, "waiting_for_supply"
end


return Executor
