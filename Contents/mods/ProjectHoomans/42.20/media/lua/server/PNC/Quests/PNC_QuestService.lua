-- Server-owned quest admission, objective evidence, and turn-in lifecycle.
-- Dialogue can request these operations, but cannot mutate this state.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.QuestService = PNC.QuestService or {}

local Service = PNC.QuestService
local Repository = PNC.QuestRepository
local Definitions = PNC.QuestDefinitions
    or require "PNC/Quests/PNC_QuestDefinitions"
local Status = Repository.STATUS
local Core = PNC.Core

Service.STATUS = Status
Service.EVENT_OWNER = "ProjectHoomans.QuestService"
Service.INVENTORY_EVENT = "PNC_INVENTORY_ITEM_TRANSFERRED"

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function now()
    return Core and Core.Now and Core.Now() or 0
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function isAuthority()
    if Core and type(Core.IsAuthority) == "function" then
        return Core.IsAuthority() == true
    end
    return true
end

local function identityFor(player)
    if type(player) == "string" or type(player) == "number" then
        local value = tostring(player)
        return value ~= "" and value or nil
    end
    if type(player) ~= "table" then return nil end
    if player.characterUUID ~= nil then
        return text(player.characterUUID)
    end
    if PNC.PlayerContext and type(PNC.PlayerContext.Peek) == "function" then
        local context = PNC.PlayerContext.Peek(player)
        if context and context.characterUUID then
            return text(context.characterUUID)
        end
    end
    if PNC.PlayerContext and type(PNC.PlayerContext.Resolve) == "function" then
        local context = PNC.PlayerContext.Resolve(player, "quest")
        if context and context.characterUUID then
            return text(context.characterUUID)
        end
    end
    return nil
end

local function scopeKey(characterUUID, questID, giverNPCID)
    return table.concat({ tostring(characterUUID), tostring(questID),
        tostring(giverNPCID) }, "\31")
end

local function definitionFor(questID)
    return Definitions and Definitions.Get
        and Definitions.Get(questID) or nil
end

local function giverFor(giverNPCID)
    local registry = PNC.Registry
    if not registry or type(registry.Get) ~= "function" then
        return nil, "giver_registry_unavailable"
    end
    local giver = registry.Get(tostring(giverNPCID or ""))
    if not giver then return nil, "giver_not_found" end
    if giver.alive == false then return nil, "giver_unavailable" end
    return giver
end

local function supplyTaskFor(giverNPCID)
    local medical = PNC.MedicalCareService
    if not medical or type(medical.List) ~= "function" then
        return nil, "medical_supply_context_unavailable"
    end
    for _, task in ipairs(medical.List(false) or {}) do
        if task
            and tostring(task.status or "") == "WAITING_FOR_SUPPLY"
            and tostring(task.blockedReason or "") == "missing_bandage"
            and tostring(task.supplyRequesterId or "")
                == tostring(giverNPCID or "")
        then
            return task
        end
    end
    return nil, "medical_supply_not_required"
end

local function eligibility(definition, giverNPCID)
    local giver, giverReason = giverFor(giverNPCID)
    local supplyTask
    local supplyReason
    if not giver then return nil, giverReason end
    if definition.eligibility and definition.eligibility.medicalSupplyRequired then
        supplyTask, supplyReason = supplyTaskFor(giverNPCID)
        if not supplyTask then return nil, supplyReason end
    end
    return {
        giver = giver,
        supplyTask = supplyTask,
    }
end

local function eventPayload(instance, extra)
    local payload = {
        questID = instance.questID,
        instanceID = instance.id,
        scopeKey = instance.scopeKey,
        ownerCharacterUUID = instance.ownerCharacterUUID,
        giverNPCID = instance.giverNPCID,
        status = instance.status,
        revision = instance.revision,
    }
    for key, value in pairs(extra or {}) do payload[key] = value end
    return payload
end

local function emit(eventType, instance, extra)
    local events = PNC.Tasking and PNC.Tasking.Events
    if not events or type(events.Emit) ~= "function" then
        return false, "quest_event_bus_unavailable"
    end
    return events.Emit(eventType, {
        npcId = instance.giverNPCID,
        source = "QuestService",
        entityId = instance.id,
        revision = instance.revision,
        payload = eventPayload(instance, extra),
    })
end

local function summary(instance)
    return copy(instance)
end

local function save(instance)
    local stored = Repository.Put(instance)
    if not stored then return nil, "quest_persist_failed" end
    return stored
end

local function expectedRevision(instance, options)
    if type(options) ~= "table" or options.expectedRevision == nil then
        return true
    end
    if tonumber(options.expectedRevision) ~= tonumber(instance.revision) then
        return false, "quest_revision_stale"
    end
    return true
end

local function activeInstance(characterUUID, questID, giverNPCID)
    return Repository.Get(scopeKey(characterUUID, questID, giverNPCID))
end

function Service.GetDefinition(questID)
    return definitionFor(questID)
end

function Service.GetInstance(player, questID, giverNPCID)
    if not isAuthority() then return nil, "not_authority" end
    local characterUUID = identityFor(player)
    if not characterUUID then return nil, "character_identity_unavailable" end
    return summary(activeInstance(characterUUID, questID, giverNPCID))
end

function Service.GetObjectiveSummary(player, questID, giverNPCID)
    local instance, reason = Service.GetInstance(player, questID, giverNPCID)
    if reason then return nil, reason end
    if not instance then return nil, "quest_instance_not_found" end
    return {
        questID = instance.questID,
        instanceID = instance.id,
        status = instance.status,
        revision = instance.revision,
        objective = copy(instance.objective),
    }
end

function Service.OfferQuest(player, questID, giverNPCID)
    if not isAuthority() then return nil, "not_authority" end
    local characterUUID = identityFor(player)
    local definition = definitionFor(questID)
    if not characterUUID then return nil, "character_identity_unavailable" end
    if not definition then return nil, "quest_definition_unavailable" end
    local existing = activeInstance(characterUUID, questID, giverNPCID)
    if existing then
        return {
            status = existing.status,
            revision = existing.revision,
            instance = summary(existing),
            definition = definition,
        }, "already_allocated"
    end
    local eligible, reason = eligibility(definition, giverNPCID)
    if not eligible then
        return {
            status = "LOCKED",
            revision = 0,
            questID = definition.id,
            giverNPCID = tostring(giverNPCID or ""),
            responsePoolID = definition.responses
                and definition.responses.locked or nil,
            reason = reason,
            definition = definition,
        }, reason
    end
    return {
        status = "AVAILABLE",
        revision = 0,
        questID = definition.id,
        giverNPCID = tostring(giverNPCID),
        sourceTaskID = eligible.supplyTask and eligible.supplyTask.id or nil,
        responsePoolID = definition.responses and definition.responses.offer,
        definition = definition,
    }, "available"
end

function Service.AcceptQuest(player, questID, giverNPCID, options)
    if not isAuthority() then return nil, "not_authority" end
    options = type(options) == "table" and options or {}
    local characterUUID = identityFor(player)
    local definition = definitionFor(questID)
    local existing
    local eligible
    local reason
    local instance
    local at
    if not characterUUID then return nil, "character_identity_unavailable" end
    if not definition then return nil, "quest_definition_unavailable" end
    existing = activeInstance(characterUUID, questID, giverNPCID)
    if existing then
        if not expectedRevision(existing, options) then
            return nil, "quest_revision_stale"
        end
        if existing.status == Status.ACTIVE
            or existing.status == Status.READY_TO_TURN_IN
            or existing.status == Status.COMPLETED
        then
            return summary(existing), "already_active"
        end
        return nil, "quest_instance_terminal"
    end
    if options.expectedRevision ~= nil
        and tonumber(options.expectedRevision) ~= 0
    then
        return nil, "quest_revision_stale"
    end
    eligible, reason = eligibility(definition, giverNPCID)
    if not eligible then return nil, reason end
    at = now()
    instance = {
        id = Repository.NextId(),
        questID = definition.id,
        scopeKey = scopeKey(characterUUID, definition.id, giverNPCID),
        definitionVersion = definition.version,
        ownerCharacterUUID = characterUUID,
        giverNPCID = tostring(giverNPCID),
        status = Status.ACTIVE,
        revision = 1,
        objective = {
            id = definition.objective.id,
            required = tonumber(definition.objective.quantity) or 1,
            delivered = 0,
            itemFullType = definition.objective.itemFullType,
            direction = definition.objective.direction,
        },
        sourceTaskID = eligible.supplyTask and eligible.supplyTask.id or nil,
        sourceRequestID = eligible.supplyTask
            and eligible.supplyTask.supplyRequestId or nil,
        acceptedAt = at,
        updatedAt = at,
        rewardID = definition.reward and definition.reward.id or nil,
        rewardClaimed = false,
    }
    instance = save(instance)
    if not instance then return nil, "quest_persist_failed" end
    emit("QUEST_ACCEPTED", instance, {
        responsePoolID = definition.responses and definition.responses.accepted,
    })
    return summary(instance), "accepted"
end

local function itemTypesMatch(instance, payload)
    local expected = tostring(instance.objective.itemFullType or "")
    local itemTypes = type(payload.itemTypes) == "table"
        and payload.itemTypes or {}
    if #itemTypes ~= 1 then return false end
    return tostring(itemTypes[1] or "") == expected
end

function Service.ApplyObjectiveEvent(event)
    if not isAuthority() then return nil, "not_authority" end
    if type(event) ~= "table" then return nil, "quest_event_invalid" end
    local payload = type(event.payload) == "table" and event.payload or {}
    if payload.committed ~= true
        or tostring(payload.direction or "") ~= "player_to_npc"
        or tostring(event.type or "") ~= Service.INVENTORY_EVENT
    then
        return nil, "quest_objective_evidence_invalid"
    end
    local characterUUID = text(payload.playerCharacterUUID)
    local giverNPCID = text(payload.targetNPCID or payload.npcID)
    local taskID = text(payload.medicalSupplyTaskID)
    if not characterUUID or not giverNPCID or not itemTypesMatch({
        objective = {
            itemFullType = payload.expectedItemFullType
                or payload.itemTypes and payload.itemTypes[1],
        },
    }, payload) then
        return nil, "quest_objective_evidence_invalid"
    end
    for _, definition in ipairs(Definitions.List()) do
        local instance = activeInstance(characterUUID, definition.id, giverNPCID)
        if instance and (instance.status == Status.READY_TO_TURN_IN
                or instance.status == Status.COMPLETED
                or instance.status == Status.REWARDED)
            and (not taskID or tostring(instance.sourceTaskID or "") == taskID)
            and itemTypesMatch(instance, payload)
        then
            return summary(instance), "already_ready"
        end
        if instance and instance.status == Status.ACTIVE
            and (not taskID or tostring(instance.sourceTaskID or "") == taskID)
            and itemTypesMatch(instance, payload)
        then
            local requestID = text(payload.requestID or event.id)
            if not requestID then return nil, "quest_transfer_request_missing" end
            instance.objective.delivered = math.min(
                instance.objective.required,
                instance.objective.delivered + 1)
            instance.objective.lastEventID = requestID
            instance.status = Status.READY_TO_TURN_IN
            instance.revision = instance.revision + 1
            instance.updatedAt = now()
            instance = save(instance)
            if not instance then return nil, "quest_persist_failed" end
            emit("QUEST_OBJECTIVE_PROGRESSED", instance, {
                eventID = requestID,
                responsePoolID = definition.responses
                    and definition.responses.progress,
            })
            emit("QUEST_READY_TO_TURN_IN", instance, {
                responsePoolID = definition.responses and definition.responses.ready,
            })
            return summary(instance), "ready"
        end
    end
    return nil, "quest_instance_not_found"
end

local function commitReward(player, instance, definition)
    local rewards = PNC.QuestRewards
    if rewards and type(rewards.Commit) == "function" then
        local ok, committed, reason = pcall(
            rewards.Commit, player, instance, definition.reward)
        if not ok or committed ~= true then
            return false, ok and (reason or "quest_reward_rejected")
                or "quest_reward_adapter_failed"
        end
    elseif not definition.reward
        or definition.reward.kind ~= "dialogue_acknowledgement"
    then
        return false, "quest_reward_adapter_unavailable"
    end
    return true
end

function Service.SubmitTurnIn(player, questID, giverNPCID, options)
    if not isAuthority() then return nil, "not_authority" end
    options = type(options) == "table" and options or {}
    local characterUUID = identityFor(player)
    local instance = characterUUID
        and activeInstance(characterUUID, questID, giverNPCID) or nil
    local definition = definitionFor(questID)
    local rewarded
    local reason
    if not instance then return nil, "quest_instance_not_found" end
    if not definition then return nil, "quest_definition_unavailable" end
    if not expectedRevision(instance, options) then
        return nil, "quest_revision_stale"
    end
    if instance.status == Status.REWARDED or instance.rewardClaimed then
        return summary(instance), "already_rewarded"
    end
    if instance.status == Status.READY_TO_TURN_IN then
        instance.status = Status.COMPLETED
        instance.completedAt = now()
        instance.updatedAt = instance.completedAt
        instance.revision = instance.revision + 1
        instance = save(instance)
        if not instance then return nil, "quest_persist_failed" end
        emit("QUEST_COMPLETED", instance, {
            responsePoolID = definition.responses and definition.responses.rewarded,
        })
    elseif instance.status ~= Status.COMPLETED then
        return nil, "quest_not_ready"
    end
    rewarded, reason = commitReward(player, instance, definition)
    if not rewarded then return nil, reason end
    instance.rewardClaimed = true
    instance.rewardClaimedAt = now()
    instance.status = Status.REWARDED
    instance.updatedAt = instance.rewardClaimedAt
    instance.revision = instance.revision + 1
    instance = save(instance)
    if not instance then return nil, "quest_persist_failed" end
    emit("QUEST_REWARDED", instance, {
        rewardID = instance.rewardID,
        responsePoolID = definition.responses and definition.responses.rewarded,
    })
    return summary(instance), "rewarded"
end

function Service.AbandonQuest(player, questID, giverNPCID, reason)
    if not isAuthority() then return nil, "not_authority" end
    local characterUUID = identityFor(player)
    local instance = characterUUID
        and activeInstance(characterUUID, questID, giverNPCID) or nil
    if not instance then return nil, "quest_instance_not_found" end
    if Repository.TERMINAL[instance.status] then
        return nil, "quest_instance_terminal"
    end
    instance.status = Status.ABANDONED
    instance.failureReason = text(reason) or "abandoned"
    instance.updatedAt = now()
    instance.revision = instance.revision + 1
    instance = save(instance)
    if not instance then return nil, "quest_persist_failed" end
    emit("QUEST_ABANDONED", instance)
    return summary(instance), "abandoned"
end

-- Network/dialogue ingress for the fixed Clinic Supplies contract. The
-- operation table is deliberately closed: semantic input can request only
-- these authored lifecycle operations and never an arbitrary Lua callback.
function Service.HandleRequest(player, request, options)
    request = type(request) == "table" and request or {}
    options = type(options) == "table" and options or {}
    local operation = string.lower(tostring(request.operation or ""))
    local questID = text(request.questID) or "pnc.quest.clinic_supplies"
    local giverNPCID = text(request.giverNPCID or request.npcID)
    local requestID = text(request.requestID)
    local result
    local reason
    local instance
    local definition = definitionFor(questID)
    local output = {
        accepted = false,
        status = "failed",
        reason = "quest_operation_invalid",
        requestID = requestID,
        questID = questID,
        giverNPCID = giverNPCID,
        operation = operation,
    }
    if not definition then
        output.reason = "quest_definition_unavailable"
        return output
    end
    if not giverNPCID then
        output.reason = "giver_identity_missing"
        return output
    end

    if operation == "offer" then
        result, reason = Service.OfferQuest(player, questID, giverNPCID)
        if result then
            local rawStatus = string.upper(tostring(result.status or ""))
            local available = rawStatus == "AVAILABLE"
            local existing = type(result.instance) == "table"
                and result.instance or nil
            local existingStatus = existing and string.upper(
                tostring(existing.status or "")) or ""
            output.accepted = available or existing ~= nil
            output.status = available and "available"
                or existingStatus == Status.ACTIVE and "active"
                or existingStatus == Status.READY_TO_TURN_IN and "ready"
                or existingStatus == Status.REWARDED and "rewarded"
                or "locked"
            output.responsePoolID = result.responsePoolID
                or definition.responses and definition.responses.offer
            output.sourceTaskID = result.sourceTaskID
            output.instance = copy(existing)
            output.objective = existing and copy(existing.objective) or nil
            output.revision = result.revision
            output.reason = reason
        else
            output.reason = reason or output.reason
            output.status = "locked"
        end
    elseif operation == "accept" then
        result, reason = Service.AcceptQuest(player, questID, giverNPCID, {
            expectedRevision = request.expectedRevision,
        })
        if result then
            output.accepted = reason == "accepted" or reason == "already_active"
            output.status = reason == "accepted" and "accepted"
                or string.upper(tostring(result.status or ""))
                    == Status.READY_TO_TURN_IN and "ready"
                or "active"
            output.responsePoolID = definition.responses
                and definition.responses.accepted
            output.instance = copy(result)
            output.objective = copy(result.objective)
            output.revision = result.revision
            output.reason = reason
        else
            output.reason = reason or output.reason
            output.status = "rejected"
        end
    elseif operation == "status" then
        result, reason = Service.GetInstance(player, questID, giverNPCID)
        if result then
            local rawStatus = string.upper(tostring(result.status or ""))
            output.accepted = true
            output.status = rawStatus == Status.ACTIVE and "active"
                or rawStatus == Status.READY_TO_TURN_IN and "ready"
                or rawStatus == Status.COMPLETED and "completed"
                or rawStatus == Status.REWARDED and "rewarded"
                or "unknown"
            output.responsePoolID = definition.responses
                and (output.status == "ready" and definition.responses.ready
                    or output.status == "rewarded"
                        and definition.responses.rewarded
                    or definition.responses.progress)
            output.instance = copy(result)
            output.objective = copy(result.objective)
            output.revision = result.revision
            output.reason = "status_returned"
        else
            output.status = "unknown"
            output.reason = reason or "quest_instance_not_found"
        end
    elseif operation == "turn_in" then
        result, reason = Service.SubmitTurnIn(player, questID, giverNPCID, {
            expectedRevision = request.expectedRevision,
        })
        if result then
            output.accepted = reason == "rewarded" or reason == "already_rewarded"
            output.status = output.accepted and "rewarded" or "rejected"
            output.responsePoolID = definition.responses
                and definition.responses.rewarded
            output.instance = copy(result)
            output.objective = copy(result.objective)
            output.revision = result.revision
            output.reason = reason
        else
            output.status = "rejected"
            output.reason = reason or output.reason
        end
    end
    output.network = options.network == true
    return output
end

function Service.ObserveInventoryTransfer(_, event)
    return Service.ApplyObjectiveEvent(event)
end

local taskEvents = PNC.Tasking and PNC.Tasking.Events
if taskEvents and type(taskEvents.Subscribe) == "function"
    and not Service.EventHookRegistered
then
    taskEvents.Subscribe(Service.INVENTORY_EVENT,
        function(context, event)
            return Service.ObserveInventoryTransfer(context, event)
        end, Service.EVENT_OWNER)
    Service.EventHookRegistered = true
end

return Service
