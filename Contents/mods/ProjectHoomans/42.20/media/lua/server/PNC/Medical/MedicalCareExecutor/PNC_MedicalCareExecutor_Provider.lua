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
local SUPPLY_RETRY_MS = 1500
local SUPPLY_PREFLIGHT_MS = 2000
local SUPPLY_NOTICE_RADIUS = 24
local SUPPLY_NOTICE_REPEAT_MS = 30 * 60 * 1000
local lastSupplyAttemptAt = {}
local lastSupplyPreflightAt = {}
local supplyNoticeRecipients = {}

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

local function combatActive(record)
    local routes = PNC.NeedFacilityAwayRoutes
    if routes and type(routes.IsCombatActive) == "function" then
        return routes.IsCombatActive(record) == true
    end
    local runtime = record and record.runtime or {}
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return runtime.attackAction ~= nil or runtime.combatTarget ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
end

local function hasTaskBandage(record, task)
    if not record or not task or not Treatment
        or type(Treatment.GetNPCBandagePlan) ~= "function"
    then
        return false
    end
    local requireItem = task.policy
        and task.policy.requireItem == true or false
    local plan = Treatment.GetNPCBandagePlan(record, {
        consumeItem = requireItem,
    })
    return plan ~= nil and (not requireItem or plan.requiresItem == true)
end

local function isUsableDoctor(record, patient)
    return record and record.alive ~= false
        and not (record.health and record.health.state == "incapacitated")
        and tostring(record.id or "") ~= tostring(patient and patient.id or "")
        and Internal.IsDoctor(record)
        and Internal.SameCareGroup(record, patient)
end

local function groupDoctors(task, patient)
    local output = {}
    if not patient or not Registry or type(Registry.ForEach) ~= "function" then
        return output
    end
    Registry.ForEach(function(record)
        if isUsableDoctor(record, patient) then
            output[#output + 1] = record
        end
    end)
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

local function requesterForTask(task, doctors)
    if task and task.supplyRequesterId then
        for index = 1, #doctors do
            if tostring(doctors[index].id)
                == tostring(task.supplyRequesterId)
            then
                return doctors[index]
            end
        end
    end
    if task and task.actorId then
        for index = 1, #doctors do
            if tostring(doctors[index].id) == tostring(task.actorId) then
                return doctors[index]
            end
        end
    end
    return doctors[1]
end

local function preflightMissingSupply(task, at)
    local patient
    local doctors
    local requester
    local key
    local last
    local changed
    if not task or task.status ~= Status.QUEUED
        and task.status ~= Status.WAITING_FOR_DOCTOR
    then
        return nil
    end
    key = tostring(task.id or "")
    last = lastSupplyPreflightAt[key]
    if last ~= nil and at - last < SUPPLY_PREFLIGHT_MS then return nil end
    lastSupplyPreflightAt[key] = at
    patient = Internal.Patient(task)
    if not patient or patient.alive == false or not Internal.CurrentPart(patient) then
        return nil
    end
    doctors = groupDoctors(task, patient)
    if #doctors == 0 then return nil end
    for index = 1, #doctors do
        if hasTaskBandage(doctors[index], task) then return nil end
    end
    requester = requesterForTask(task, doctors)
    if not requester then return nil end
    changed = Service.SetPhase(task.id, Status.WAITING_FOR_SUPPLY, {
        clearActor = true,
        clearReservation = true,
        blockedReason = "missing_bandage",
        supplyRequesterId = tostring(requester.id),
    })
    if changed then return Service.Get(task.id) end
    return nil
end

local function callPosition(target, method, fallback)
    local callback = target and target[method] or nil
    if type(callback) == "function" then
        local ok, value = pcall(callback, target)
        if ok and tonumber(value) ~= nil then return tonumber(value) end
    end
    return tonumber(fallback)
end

local function playerCanReceiveSupport(player, requester)
    local body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(requester and requester.id) or nil
    local px = callPosition(player, "getX")
    local py = callPosition(player, "getY")
    local pz = callPosition(player, "getZ", 0)
    local nx = callPosition(body, "getX", requester and requester.x)
    local ny = callPosition(body, "getY", requester and requester.y)
    local nz = callPosition(body, "getZ", requester and requester.z or 0)
    local dx
    local dy
    if px == nil or py == nil or nx == nil or ny == nil
        or pz == nil or nz == nil or math.abs(pz - nz) >= 1
    then
        return false
    end
    dx = px - nx
    dy = py - ny
    return dx * dx + dy * dy <= SUPPLY_NOTICE_RADIUS * SUPPLY_NOTICE_RADIUS
end

local function playerNoticeKey(player)
    local onlineID = callPosition(player, "getOnlineID")
    if onlineID ~= nil then return tostring(onlineID) end
    local username = player and player.getUsername
        and player:getUsername() or nil
    if username ~= nil and tostring(username) ~= "" then
        return "user:" .. tostring(username)
    end
    return tostring(player)
end

local function sendSupplyState(task, state)
    local patient = Internal.Patient(task)
    local requester = task and Registry and Registry.Get
        and Registry.Get(task.supplyRequesterId) or nil
    local requestID = tostring(task and task.supplyRequestId or "")
    local core = PNC.Core
    local network = PNC.Network
    local notices
    local stateRecipients
    local neededRecipients
    local eventID
    local role
    local at
    local sentCount = 0
    if requestID == "" or not requester or not patient
        or not core or type(core.ForEachPlayer) ~= "function"
        or not network
        or type(network.SendConversationRelationshipForNPC) ~= "function"
    then
        return false
    end
    notices = supplyNoticeRecipients[requestID]
    if not notices then
        notices = { needed = {}, fulfilled = {}, resolved = {} }
        supplyNoticeRecipients[requestID] = notices
    end
    stateRecipients = notices[state] or {}
    notices[state] = stateRecipients
    neededRecipients = notices.needed or {}
    at = core.Now and core.Now() or 0
    eventID = requestID .. ":" .. tostring(state)
    role = string.lower(tostring(requester.affiliation
        and (requester.affiliation.role
            or requester.affiliation.communityRole)
        or requester.communityRole or "colonist"))
    core.ForEachPlayer(function(player)
        local playerKey
        local context
        local ambientFlavor
        local ok
        local sent
        local lastSentAt
        if not player or not playerCanReceiveSupport(player, requester) then
            return
        end
        playerKey = playerNoticeKey(player)
        if state ~= "needed" and not neededRecipients[playerKey] then
            return
        end
        lastSentAt = tonumber(stateRecipients[playerKey])
        if state == "needed" and lastSentAt ~= nil
            and at - lastSentAt < SUPPLY_NOTICE_REPEAT_MS
        then
            return
        end
        if state ~= "needed" and stateRecipients[playerKey] then return end
        context = {
            eventType = "medical_bandage_request",
            medicalBandageRequired = true,
            medicalBandageStatus = state == "fulfilled" and "found"
                or state == "resolved" and "resolved" or "missing",
            medicalSupplyRequestStatus = state,
            medicalSupplyRequestID = requestID,
            medicalSupplyTaskID = tostring(task.id),
            medicalSupplyRequesterID = tostring(requester.id),
            victimNPCID = tostring(patient.id),
            socialRole = role,
            npcType = role,
        }
        ambientFlavor = {
            flavorID = "social.witnessed_teammate_hurt",
            eventType = "medical_bandage_request",
            family = "medical_support",
            priority = 78,
            llmPriority = 100,
            llmEligible = false,
            weight = 1,
            npcID = tostring(requester.id),
            npcType = role,
            socialRole = role,
            relationshipState = "unknown",
            relationshipTier = "reserved",
            eventID = eventID,
            mergeKey = eventID,
            cooldowns = {
                familyMs = 0,
                speakerMs = 0,
                ambientMs = 0,
                mergeWindowMs = 0,
            },
            context = context,
        }
        ok, sent = pcall(
            network.SendConversationRelationshipForNPC,
            player,
            requester.id,
            "medical_bandage_request",
            {
                source = "medical_bandage_request",
                eventID = eventID,
                npcID = tostring(requester.id),
                ambientFlavor = ambientFlavor,
            }
        )
        if ok and sent == true then
            stateRecipients[playerKey] = at
            sentCount = sentCount + 1
        end
    end)
    if state ~= "needed" then
        supplyNoticeRecipients[requestID] = nil
        lastSupplyAttemptAt[requestID] = nil
    end
    return sentCount > 0
end

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

function Executor.GetCandidates(npcId)
    local actor = Registry and Registry.Get and Registry.Get(npcId) or nil
    local candidates = {}
    local at = PNC.Core.Now()
    if not actor or not Internal.IsDoctor(actor) then return candidates end
    for _, task in ipairs(Service.List(false)) do
        local supplyTask = preflightMissingSupply(task, at)
        if supplyTask then
            Executor.RequestBandageSupport(supplyTask.id)
        elseif task.status == Status.WAITING_FOR_SUPPLY then
            Executor.RequestBandageSupport(task.id)
        end
    end
    for _, task in ipairs(Service.List(false)) do
        local ready = (tonumber(task.retryAt) or 0) <= at
        local supplyReady = task.status == Status.WAITING_FOR_SUPPLY
            and hasTaskBandage(actor, task)
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
