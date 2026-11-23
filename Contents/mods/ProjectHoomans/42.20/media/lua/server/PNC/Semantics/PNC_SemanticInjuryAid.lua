-- Server-authoritative injury-aid inspection and direct NPC treatment adapter.
-- This module never runs on clients and never performs work from a tick hook.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Aid = PNC.Semantics.InjuryAid or {}
PNC.Semantics.InjuryAid = Aid

local MAX_ID_LENGTH = 96

local function cleanID(value)
    if value == nil then return nil end
    local result = tostring(value)
    if result == "" or #result > MAX_ID_LENGTH then return nil end
    if string.find(result, "[^%w_%.:%-]") then return nil end
    return result
end

local function isAuthority()
    local core = PNC.Core
    if core and type(core.IsAuthority) == "function" then
        return core.IsAuthority() == true
    end
    return type(isServer) == "function" and isServer() == true
end

local function validRecord(record)
    return type(record) == "table" and record.alive ~= false
        and cleanID(record.id) ~= nil
end

local function actorBody(record)
    local registry = PNC.Registry
    if registry and type(registry.GetLiveZombie) == "function" then
        return registry.GetLiveZombie(record.id)
    end
    return nil
end

local function position(record, body)
    local x = body and type(body.getX) == "function"
        and tonumber(body:getX()) or tonumber(record and record.x)
    local y = body and type(body.getY) == "function"
        and tonumber(body:getY()) or tonumber(record and record.y)
    local z = body and type(body.getZ) == "function"
        and tonumber(body:getZ()) or tonumber(record and record.z)
    if x == nil or y == nil then return nil end
    return x, y, z or 0
end

local function inTreatmentRange(helper, injured)
    local helperBody = actorBody(helper)
    local injuredBody = actorBody(injured)
    local executor = PNC.MedicalCareExecutor
    local executorInternal = executor and executor.Internal or nil
    if executorInternal and type(executorInternal.InTreatmentRange) == "function" then
        local hx, hy = position(helper, helperBody)
        local ix, iy = position(injured, injuredBody)
        if hx == nil or ix == nil then return false, "position_unavailable" end
        return executorInternal.InTreatmentRange(
            helper, helperBody, injured, injuredBody
        ) == true, "out_of_range"
    end

    local hx, hy, hz = position(helper, helperBody)
    local ix, iy, iz = position(injured, injuredBody)
    if hx == nil or ix == nil then return false, "position_unavailable" end
    if math.abs(hz - iz) >= 1 then return false, "different_floor" end
    local range = tonumber(PNC.Const and PNC.Const.BANDAGE_RANGE) or 3
    local distanceSq = PNC.Core and type(PNC.Core.DistanceSq) == "function"
        and PNC.Core.DistanceSq(hx, hy, ix, iy)
        or ((hx - ix) * (hx - ix) + (hy - iy) * (hy - iy))
    return distanceSq <= range * range, "out_of_range"
end

local function combatActive(record)
    local routes = PNC.NeedFacilityAwayRoutes
    if routes and type(routes.IsCombatActive) == "function" then
        return routes.IsCombatActive(record) == true
    end
    local runtime = record and record.runtime or {}
    local now = PNC.Core and type(PNC.Core.Now) == "function"
        and tonumber(PNC.Core.Now()) or 0
    return runtime.attackAction ~= nil or runtime.combatTarget ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
end

local function scale100(value)
    value = tonumber(value) or 0
    if value >= 0 and value <= 1 then return value * 100 end
    return value
end

local function resolveSocial(helper, injured, danger, bandageCount)
    local projection = PNC.ConvoEngine
        and PNC.ConvoEngine.DispositionProjection or nil
    local adapter = PNC.ConvoEngine
        and PNC.ConvoEngine.InteractionActorAdapterProjectHoomans or nil
    if not projection and type(require) == "function" then
        projection = require "PNC/ConvoEngine/DispositionProjection"
    end
    if not adapter and type(require) == "function" then
        adapter = require "PNC/ConvoEngine/Interaction/ActorAdapter_ProjectHoomans"
    end

    local resolved = projection and type(projection.Resolve) == "function"
        and projection.Resolve(helper) or nil
    local disposition = resolved and resolved.effectiveDisposition or {}
    local demeanor = resolved and resolved.temporaryDemeanor or {}
    local relationship = adapter and type(adapter.ProjectRelationship) == "function"
        and adapter.ProjectRelationship(helper, injured) or {}
    local compassion = scale100(disposition.compassion)
    local aggression = scale100(disposition.aggression)
    local loyalty = scale100(disposition.loyalty)
    local materialism = scale100(disposition.materialism)
    local scarcityAnxiety = scale100(demeanor.scarcityAnxiety)
    local firstAidLevel = PNC.Treatment
        and PNC.Treatment.GetNPCFirstAidLevel
        and tonumber(PNC.Treatment.GetNPCFirstAidLevel(helper)) or 0
    local isMedic = PNC.MedicalCareExecutor
        and PNC.MedicalCareExecutor.IsDoctor
        and PNC.MedicalCareExecutor.IsDoctor(helper) == true
    local approval = tonumber(relationship.approval) or 0
    local trust = tonumber(relationship.trust) or 0
    local relationState = string.lower(tostring(relationship.state or "unknown"))
    local policy

    if relationState == "enemy" or relationState == "hostile"
        or (approval <= -40 and aggression >= 60)
    then
        policy = "hostile"
    elseif danger and (loyalty >= 55 or compassion >= 65
        or relationState == "friend" or relationState == "friendly")
    then
        policy = "protective"
    elseif scarcityAnxiety >= 65 and materialism >= 60 and compassion < 45 then
        policy = "dismissive"
    elseif compassion >= 65 or trust >= 55 or approval >= 50 then
        policy = "supportive"
    elseif isMedic or firstAidLevel >= 3 then
        policy = "clinical"
    elseif scarcityAnxiety >= 55 and bandageCount <= 1
        and materialism >= 50 and compassion < 55
    then
        policy = "disappointed"
    else
        policy = "practical"
    end

    return {
        policy = policy,
        relationship = relationship,
        disposition = disposition,
        demeanor = demeanor,
        role = isMedic and "medic" or "helper",
        firstAidLevel = firstAidLevel,
        remainingBandages = tonumber(bandageCount) or 0,
        dangerActive = danger == true,
    }
end

local function taskTransfer(taskID, helper, injured)
    if taskID == nil then return nil, nil end
    local service = PNC.MedicalCareService
    if not service or type(service.Get) ~= "function" then
        return false, "medical_task_unavailable"
    end
    local task = service.Get(taskID)
    local status = service.STATUS
    if not task or not status
        or task.patientKind ~= "npc"
        or tostring(task.patientId or "") ~= tostring(injured.id)
        or task.status ~= status.WAITING_FOR_SUPPLY
        or task.blockedReason ~= "missing_bandage"
    then
        return false, "medical_task_not_waiting_for_bandage"
    end
    if tostring(task.supplyRequesterId or "") == tostring(helper.id)
        or tostring(injured.id) == tostring(helper.id)
    then
        return false, "invalid_supply_donor"
    end
    return task, nil
end

local function countBandages(record, treatment)
    local inventory = record and record.inventory or nil
    local inventoryService = PNC.Inventory
    if inventoryService and type(inventoryService.EnsureRecordInventory) == "function" then
        inventory = inventoryService.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        }) or inventory
    end
    local count = 0
    for _, item in pairs(inventory and inventory.items or {}) do
        if item and item.type ~= nil
            and treatment.IsBandageType(item.type) == true
        then
            count = count + math.max(0, math.floor(tonumber(item.stack) or 1))
        end
    end
    return count
end

local function inspect(helper, injured, options)
    options = type(options) == "table" and options or {}
    local result = {
        eligible = false,
        reason = nil,
        helperID = validRecord(helper) and cleanID(helper.id) or nil,
        injuredID = validRecord(injured) and cleanID(injured.id) or nil,
        partID = nil,
        injury = nil,
        reachability = { reachable = false, reason = nil },
        inventory = {
            mode = "none",
            hasBandage = false,
            itemID = nil,
            fullType = nil,
            displayName = nil,
        },
        treatment = nil,
        social = nil,
        outcome = "unable",
        requestID = nil,
    }
    local wounds = PNC.NPCWounds
    local treatment = PNC.Treatment
    local bandagePlan
    local partID
    local wound
    local task
    local taskReason
    local danger
    local reachable
    local action = tostring(options.action or "treat")
    local bandageCount = 0

    if not validRecord(helper) then result.reason = "invalid_helper"; return result end
    if not validRecord(injured) then result.reason = "invalid_injured"; return result end
    if tostring(helper.id) == tostring(injured.id) then
        result.reason = "self_treatment_not_aid"
        return result
    end
    if not wounds or type(wounds.FindTreatableWound) ~= "function" then
        result.reason = "wound_service_unavailable"
        return result
    end
    if not treatment or type(treatment.GetNPCBandagePlan) ~= "function"
        or type(treatment.TryNPCMedicalTreatment) ~= "function"
    then
        result.reason = "treatment_service_unavailable"
        return result
    end

    partID, wound = wounds.FindTreatableWound(injured)
    if not partID or type(wound) ~= "table" then
        result.reason = "no_treatable_wound"
        return result
    end
    result.partID = tostring(partID)
    result.injury = {
        woundType = tostring(wound.type or "unknown"),
        bandaged = wound.bandaged == true,
        dirty = wound.bandageDirty == true,
        bleeding = (tonumber(wound.bleedingRate) or 0) > 0,
        severity = tonumber(wound.damage or wound.severity) or 0,
    }

    bandagePlan = treatment.GetNPCBandagePlan(helper, { consumeItem = true })
    bandageCount = countBandages(helper, treatment)
    result.inventory.bandageCount = bandageCount
    if bandagePlan and bandagePlan.itemID
        and treatment.IsBandageType
        and treatment.IsBandageType(bandagePlan.fullType) == true
    then
        result.inventory.mode = "physical"
        result.inventory.hasBandage = true
        result.inventory.itemID = tostring(bandagePlan.itemID)
        result.inventory.fullType = tostring(bandagePlan.fullType)
        result.inventory.displayName = tostring(bandagePlan.displayName or bandagePlan.fullType)
    end

    local taskID = options.medicalTaskID
    if taskID ~= nil then
        task, taskReason = taskTransfer(taskID, helper, injured)
        if not task then result.reason = taskReason; return result end
        result.treatment = { kind = "supply_transfer", requiresItem = true }
    elseif action == "transfer_bandage" then
        local patientPlan = treatment.GetNPCBandagePlan(
            injured, { consumeItem = true })
        if patientPlan and patientPlan.itemID then
            result.reason = "medical_supply_already_available"
            return result
        end
        result.treatment = { kind = "bandage_transfer", requiresItem = true }
    elseif action == "treat" then
        result.treatment = { kind = "npc_bandage", requiresItem = true }
    else
        result.reason = "unsupported_aid_action"
        return result
    end

    danger = combatActive(helper) or combatActive(injured)
    reachable, result.reachability.reason = inTreatmentRange(helper, injured)
    result.reachability.reachable = reachable == true

    if not result.inventory.hasBandage then
        result.reason = "missing_bandage"
        result.outcome = "ask_for_supplies"
        result.social = resolveSocial(helper, injured, danger, bandageCount)
        if result.social.policy == "hostile"
            or result.social.policy == "dismissive"
            or result.social.policy == "disappointed"
        then
            result.outcome = "refuse"
        end
        return result
    end

    if not reachable then
        result.reason = result.reachability.reason or "out_of_range"
        result.social = resolveSocial(helper, injured, danger, bandageCount)
        return result
    end
    if danger then
        result.reason = "combat_active"
        result.social = resolveSocial(helper, injured, true, bandageCount)
        result.outcome = result.social.policy == "hostile"
            and "refuse" or "protective_cover_first"
        return result
    end

    result.social = resolveSocial(helper, injured, false, bandageCount)
    result.eligible = true
    result.reason = "ready"
    if result.social.policy == "hostile"
        or result.social.policy == "dismissive"
        or result.social.policy == "disappointed"
    then
        result.outcome = "refuse"
    else
        result.outcome = "aid_offer"
    end
    result.requestID = table.concat({
        "injury-aid",
        tostring(result.helperID),
        tostring(result.injuredID),
        result.partID,
        tostring(result.inventory.itemID),
        tostring(tonumber(injured.runtime and injured.runtime.injuryRevision) or 0),
        tostring(task and task.id or action),
    }, ":")
    if task then result.medicalTaskID = tostring(task.id) end
    return result
end

function Aid.Inspect(helper, injured, options)
    if not isAuthority() then
        return { eligible = false, reason = "not_authority", outcome = "unable" }
    end
    return inspect(helper, injured, options)
end

function Aid.Offer(helper, injured, options)
    local result = Aid.Inspect(helper, injured, options)
    if result.eligible ~= true then return nil, result.reason, result end
    if result.outcome == "refuse" then
        return nil, "aid_refused", result
    end
    return {
        requestID = result.requestID,
        helperID = result.helperID,
        injuredID = result.injuredID,
        partID = result.partID,
        itemID = result.inventory.itemID,
        treatment = result.treatment.kind,
        action = result.treatment.kind,
        medicalTaskID = result.medicalTaskID,
        socialPolicy = result.social.policy,
    }, nil, result
end

function Aid.Execute(helper, injured, offer, options)
    if not isAuthority() then return false, "not_authority" end
    if type(offer) ~= "table" then return false, "invalid_aid_offer" end
    local opts = {}
    for key, value in pairs(type(options) == "table" and options or {}) do
        opts[key] = value
    end
    if offer.action == "bandage_transfer" then
        opts.action = "transfer_bandage"
    elseif offer.action == "npc_bandage" then
        opts.action = "treat"
    end
    if offer.medicalTaskID ~= nil then
        opts.medicalTaskID = offer.medicalTaskID
    end
    local current = inspect(helper, injured, opts)
    if current.eligible ~= true then return false, current.reason, current end
    if current.outcome == "refuse" then
        return false, "aid_refused", current
    end
    if tostring(offer.requestID or "") ~= tostring(current.requestID or "")
        or tostring(offer.helperID or "") ~= tostring(current.helperID or "")
        or tostring(offer.injuredID or "") ~= tostring(current.injuredID or "")
        or tostring(offer.partID or "") ~= tostring(current.partID or "")
        or tostring(offer.itemID or "") ~= tostring(current.inventory.itemID or "")
        or tostring(offer.treatment or "") ~= tostring(current.treatment.kind or "")
        or tostring(offer.socialPolicy or "") ~= tostring(current.social.policy or "")
        or tostring(offer.medicalTaskID or "") ~= tostring(current.medicalTaskID or "")
    then
        return false, "aid_offer_stale", current
    end

    if current.treatment.kind == "supply_transfer"
        or current.treatment.kind == "bandage_transfer"
    then
        local transfer = PNC.ServerInventory
        local transferFunction = current.treatment.kind == "supply_transfer"
            and transfer and transfer.TransferMedicalBandageForTask
            or transfer and transfer.TransferMedicalBandageForAid
        if type(transferFunction) ~= "function" then
            return false, "medical_transfer_unavailable", current
        end
        local ok
        local reason
        local details
        if current.treatment.kind == "supply_transfer" then
            ok, reason, details = transferFunction(
                current.medicalTaskID, current.helperID, current.inventory.itemID)
        else
            ok, reason, details = transferFunction(
                current.helperID, current.injuredID, current.inventory.itemID)
        end
        return ok == true, reason or (ok and "bandage_shared" or "medical_transfer_failed"), {
            inspection = current,
            transfer = details,
        }
    end

    local treatment = PNC.Treatment
    local ok, result = treatment.TryNPCMedicalTreatment(
        helper,
        injured,
        current.partID,
        {
            consumeItem = true,
            bandageType = current.inventory.fullType,
            consumeReason = "semantic_injury_aid",
            syncEvent = "npc_treated",
        }
    )
    return ok == true, result, { inspection = current }
end

return Aid
