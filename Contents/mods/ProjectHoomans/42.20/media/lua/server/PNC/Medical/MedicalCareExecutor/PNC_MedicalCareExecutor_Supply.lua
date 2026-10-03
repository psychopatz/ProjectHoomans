if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC and PNC.MedicalCareExecutor
if not Executor then return end
local Internal = Executor.Internal
local Service = Internal.Service
local Status = Internal.Status
local Registry = Internal.Registry
local groupDoctors = Internal.groupDoctors
local hasTaskBandage = Internal.hasTaskBandage
local WorkPolicy = Internal.WorkPolicy
local Treatment = Internal.Treatment
local Common = Internal.Common
local Recovery = Internal.Recovery
local Wounds = Internal.Wounds
local Const = Internal.Const
local lastSupplyPreflightAt = Internal.LastSupplyPreflightAt
local supplyNoticeRecipients = Internal.SupplyNoticeRecipients
local lastSupplyAttemptAt = Internal.LastSupplyAttemptAt
local SUPPLY_PREFLIGHT_MS = Internal.SUPPLY_PREFLIGHT_MS
local SUPPLY_NOTICE_RADIUS = Internal.SUPPLY_NOTICE_RADIUS
local SUPPLY_NOTICE_REPEAT_MS = Internal.SUPPLY_NOTICE_REPEAT_MS

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
    at = tonumber(at) or 0
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


Internal.requesterForTask = requesterForTask
Internal.preflightMissingSupply = preflightMissingSupply
Internal.sendSupplyState = sendSupplyState
Internal.playerCanReceiveSupport = playerCanReceiveSupport
Internal.playerNoticeKey = playerNoticeKey

return Executor
