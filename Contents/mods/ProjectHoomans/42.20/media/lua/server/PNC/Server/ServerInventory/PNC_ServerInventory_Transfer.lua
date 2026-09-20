if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Network = PNC.Network
local Inventory = PNC.Inventory
local canGift = Internal.canGift
local canManage = Internal.canManage
local notify = Internal.notify
local checkRevision = Internal.checkRevision
local transferPlayerToNPC = Internal.transferPlayerToNPC
local transferNPCToPlayer = Internal.transferNPCToPlayer
local applyGiftEffect = Internal.applyGiftEffect
local auditInventoryRequest = Internal.auditInventoryRequest

local MAX_PROCESSED_GIFTS = 32

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

local function medicalBandageItemType(fullType)
    local treatment = PNC.Treatment
    local internal = treatment and treatment.Internal or nil
    return internal and type(internal.IsBandageType) == "function"
        and internal.IsBandageType(fullType) == true or false
end

local function inventoryItemSpec(item)
    if not item then return nil end
    local spec = { type = item.type, stack = 1 }
    local fields = {
        "uses", "cond", "ammoCount", "fav", "customName", "maxWeight",
        "weightReduction", "wearableSlot",
    }
    for index = 1, #fields do
        local key = fields[index]
        if item[key] ~= nil then spec[key] = item[key] end
    end
    if type(item.itemState) == "table" then
        spec.itemState = PNC.Core and PNC.Core.DeepCopy
            and PNC.Core.DeepCopy(item.itemState) or item.itemState
    end
    return spec
end

local function medicalSupplyGiftTask(player, record, args)
    local taskService = PNC.MedicalCareService
    local medical = PNC.MedicalCareExecutor
    local medicalInternal = medical and medical.Internal or nil
    local taskID = args and args.medicalSupplyTaskID
    local requestID = args and args.medicalSupplyRequestID
    local task
    local patient
    local transfer = Internal.ItemTransfer
    local resolved
    local reason
    local treatment = PNC.Treatment
    if taskID == nil and requestID == nil then return true, nil end
    if not taskID or not requestID or not taskService
        or type(taskService.Get) ~= "function"
        or not treatment or type(treatment.GetNPCBandagePlan) ~= "function"
        or not transfer or type(transfer.ResolvePlayerItems) ~= "function"
    then
        return false, "medical_supply_request_invalid"
    end
    task = taskService.Get(taskID)
    patient = task and task.patientKind == "npc" and Registry
        and Registry.Get and Registry.Get(task.patientId) or nil
    if not task
        or task.patientKind ~= "npc"
        or task.status ~= taskService.STATUS.WAITING_FOR_SUPPLY
        or task.blockedReason ~= "missing_bandage"
        or tostring(task.supplyRequesterId or "") ~= tostring(record.id)
        or tostring(task.supplyRequestId or "") ~= tostring(requestID)
        or record.alive == false
        or not patient or patient.alive == false
        or not medicalInternal or type(medicalInternal.IsDoctor) ~= "function"
        or medicalInternal.IsDoctor(record) ~= true
        or type(medicalInternal.SameCareGroup) ~= "function"
        or not medicalInternal.SameCareGroup(record, patient)
        or type(medicalInternal.CurrentPart) ~= "function"
        or not medicalInternal.CurrentPart(patient)
    then
        return false, "medical_supply_request_stale"
    end
    if treatment.GetNPCBandagePlan(record, { consumeItem = true }) then
        return false, "medical_supply_already_available"
    end
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    if #itemIDs ~= 1 then
        return false, "medical_supply_requires_one_bandage"
    end
    resolved, reason = transfer.ResolvePlayerItems(player, itemIDs)
    if not resolved then return false, reason or "gift_item_invalid" end
    local description = transfer.DescribeItem
        and transfer.DescribeItem(resolved[1]) or nil
    if not description or not medicalBandageItemType(description.fullType) then
        return false, "medical_supply_item_not_bandage"
    end
    return true, task
end

-- Server-only transfer used by a waiting medical task. The same compact
-- inventory mutation and native projection rules as player gifts are used;
-- this is intentionally not a client-requestable transfer direction.
function Service.TransferMedicalBandageForTask(taskID, donorID, itemID)
    local taskService = PNC.MedicalCareService
    local treatment = PNC.Treatment
    local medical = PNC.MedicalCareExecutor
    local task = taskService and taskService.Get
        and taskService.Get(taskID) or nil
    local donor = Registry and Registry.Get
        and Registry.Get(donorID) or nil
    local requester = task and Registry and Registry.Get
        and Registry.Get(task.supplyRequesterId) or nil
    local patient = task and task.patientKind == "npc" and Registry
        and Registry.Get and Registry.Get(task.patientId) or nil
    local medicalInternal = medical and medical.Internal or nil
    local donorPlan
    local donorInventory
    local item
    local spec
    local canAccept
    local acceptReason
    local consumed
    local consumeReason
    local effect
    local added
    local addReason
    local compactIDs
    local body
    local projected
    local projectionReason
    local projectionUndo
    if not task or not taskService
        or task.patientKind ~= "npc"
        or task.status ~= taskService.STATUS.WAITING_FOR_SUPPLY
        or task.blockedReason ~= "missing_bandage"
        or not requester or requester.alive == false
        or not donor or donor.alive == false
        or not patient or patient.alive == false
        or tostring(donor.id) == tostring(requester.id)
        or tostring(donor.id) == tostring(patient.id)
        or combatActive(requester)
        or combatActive(donor)
        or not treatment or not treatment.GetNPCBandagePlan
        or not medicalInternal or not medicalInternal.SameCareGroup
        or not medicalInternal.IsDoctor
        or not medicalInternal.IsDoctor(requester)
        or not medicalInternal.SameCareGroup(donor, patient)
        or not medicalInternal.SameCareGroup(requester, patient)
        or type(medicalInternal.CurrentPart) ~= "function"
        or not medicalInternal.CurrentPart(patient)
    then
        return false, "medical_bandage_share_unavailable"
    end
    if treatment.GetNPCBandagePlan(requester, { consumeItem = true }) then
        return false, "medical_supply_already_available"
    end
    donorPlan = treatment.GetNPCBandagePlan(donor, { consumeItem = true })
    if not donorPlan
        or tostring(donorPlan.itemID or "") ~= tostring(itemID or "")
    then
        return false, "donor_bandage_unavailable"
    end
    donorInventory = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(donor, {
            reconcileWaterContainer = false,
        }) or donor.inventory
    item = donorInventory and donorInventory.items
        and donorInventory.items[tostring(itemID or "")] or nil
    if not item or not medicalBandageItemType(item.type) then
        return false, "donor_bandage_unavailable"
    end
    spec = inventoryItemSpec(item)
    if not spec or not spec.type then return false, "bandage_item_invalid" end
    canAccept, acceptReason = Inventory.CanAccept(
        requester, { spec }, "root")
    if not canAccept then return false, acceptReason or "inventory_full" end
    if not PNC.SupplyInventory or type(PNC.SupplyInventory.Consume) ~= "function" then
        return false, "supply_consumption_unavailable"
    end
    consumed, consumeReason, effect = PNC.SupplyInventory.Consume(
        donor,
        itemID,
        {
            resourceKind = "MEDICAL",
            treatment = "BANDAGE",
            required = {},
            source = "medical_bandage_share",
        }
    )
    if not consumed then return false, consumeReason or "donor_bandage_unavailable" end
    added, addReason, compactIDs = Inventory.AddItems(
        requester, { spec }, "root", "medical_bandage_share")
    if not added then
        if effect and type(effect.undo) == "function" then pcall(effect.undo) end
        return false, addReason or "recipient_inventory_rejected"
    end
    if not compactIDs or not compactIDs[1] then
        if effect and type(effect.undo) == "function" then pcall(effect.undo) end
        return false, "recipient_inventory_item_missing"
    end
    body = Registry.GetLiveZombie and Registry.GetLiveZombie(requester.id) or nil
    if body then
        if type(Inventory.MaterializeItem) ~= "function" then
            Inventory.RemoveItems(requester, compactIDs,
                "medical_bandage_share_projection_rollback")
            if effect and type(effect.undo) == "function" then pcall(effect.undo) end
            return false, "live_inventory_projection_unavailable"
        end
        projected, projectionReason, projectionUndo = Inventory.MaterializeItem(
            requester, body, compactIDs[1])
        if not projected then
            if projectionUndo then pcall(projectionUndo) end
            Inventory.RemoveItems(requester, compactIDs,
                "medical_bandage_share_projection_rollback")
            if effect and type(effect.undo) == "function" then pcall(effect.undo) end
            return false, projectionReason or "live_inventory_projection_failed"
        end
    end
    if Network and Network.BroadcastRecord then
        Network.BroadcastRecord(donor, "medical_bandage_shared")
        Network.BroadcastRecord(requester, "medical_bandage_shared")
    end
    return true, "bandage_shared", {
        taskID = task.id,
        requesterID = requester.id,
        donorID = donor.id,
        itemType = item.type,
        itemID = compactIDs[1],
    }
end

local function processedGiftCache(lease)
    if type(lease) ~= "table" then return nil end
    lease.processedGiftRequests = lease.processedGiftRequests or {}
    lease.processedGiftRequestOrder = lease.processedGiftRequestOrder or {}
    return lease.processedGiftRequests
end

local function rememberGift(lease, requestID, response)
    local cache = processedGiftCache(lease)
    if not cache or requestID == "" then return end
    if cache[requestID] == nil then
        lease.processedGiftRequestOrder[#lease.processedGiftRequestOrder + 1] =
            requestID
    end
    cache[requestID] = response
    while #lease.processedGiftRequestOrder > MAX_PROCESSED_GIFTS do
        local old = table.remove(lease.processedGiftRequestOrder, 1)
        cache[old] = nil
    end
end

function Service.Transfer(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local giftMode = args.gift == true
    local requestID = tostring(args.requestId or "")
    local lease = record and record.runtime
        and record.runtime.conversationLease or nil
    local processed = giftMode and processedGiftCache(lease) or nil
    local tacticalClass = tostring(record and record.tacticalClass or "")
    local hostileClass = Const and Const.TACTICAL_CLASS_HOSTILE
    local replayEligible = giftMode and player and record
        and args.direction == "player_to_npc"
        and lease and tostring(lease.token or "")
            == tostring(args.conversationToken or "")
        and not (hostileClass ~= nil
            and tacticalClass == tostring(hostileClass))
    if replayEligible and processed and requestID ~= ""
        and processed[requestID]
    then
        local cached = processed[requestID]
        local success, reason, payload = notify(
            player, cached.success, cached.reason, args, cached.details
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "replay", record, args,
                "previously_allowed", "duplicate_request", "cached",
                success, reason
            )
        end
        return success, reason, payload
    end
    local allowed, reason
    local medicalTask
    if giftMode then
        allowed, reason, lease = canGift(player, record, args)
    else
        allowed, reason = canManage(player, record)
    end
    local authorityReason = reason
    if not allowed then
        local failed, failedReason, payload = notify(
            player, false, reason, args
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "rejected", record, args,
                "denied", reason, "not_run", failed, failedReason
            )
        end
        return failed, failedReason, payload
    end
    processed = giftMode and processedGiftCache(lease) or nil
    if processed and requestID ~= "" and processed[requestID] then
        local cached = processed[requestID]
        local success, cachedReason, payload = notify(
            player, cached.success, cached.reason, args, cached.details
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "replay", record, args,
                "allowed", authorityReason, "cached", success, cachedReason
            )
        end
        return success, cachedReason, payload
    end
    local revisionOK, sinceRevision, revisionDetails = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        local failed, failedReason, failedPayload = notify(
            player, false, sinceRevision, args, revisionDetails)
        if giftMode and requestID ~= "" then
            rememberGift(lease, requestID, {
                success = failed,
                reason = failedReason,
                details = revisionDetails,
            })
        end
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "stale_revision", record, args,
                "allowed", authorityReason, "not_run", failed, failedReason,
                revisionDetails and revisionDetails.currentInventoryRevision
            )
        end
        return failed, failedReason, failedPayload
    end
    if args.medicalSupplyTaskID ~= nil
        or args.medicalSupplyRequestID ~= nil
    then
        local supplyValid
        local supplyResult
        if giftMode and args.direction == "player_to_npc" then
            supplyValid, supplyResult = medicalSupplyGiftTask(
                player, record, args)
        else
            supplyValid, supplyResult = false,
                "medical_supply_request_invalid"
        end
        if not supplyValid then
            local failed, failedReason, failedPayload = notify(
                player, false, supplyResult, args)
            if giftMode and requestID ~= "" then
                rememberGift(lease, requestID, {
                    success = failed,
                    reason = failedReason,
                })
            end
            if auditInventoryRequest then
                auditInventoryRequest(
                    "server_transfer", "medical_supply_rejected", record,
                    args, "allowed", authorityReason, "not_run", failed,
                    failedReason, sinceRevision
                )
            end
            return failed, failedReason, failedPayload
        end
        medicalTask = supplyResult
    end
    local success
    local details
    if args.direction == "player_to_npc" then
        success, reason, details = transferPlayerToNPC(
            player, record, args, sinceRevision
        )
    elseif args.direction == "npc_to_player" then
        success, reason = transferNPCToPlayer(player, record, args, sinceRevision)
    else
        success, reason = false, "invalid_direction"
    end
    if success and giftMode then
        details = applyGiftEffect(player, record, args, details)
    end
    if success and medicalTask then
        local medicalExecutor = PNC.MedicalCareExecutor
        if medicalExecutor
            and type(medicalExecutor.FulfillBandageSupport) == "function"
        then
            medicalExecutor.FulfillBandageSupport(medicalTask.id)
        end
    end
    local resultSuccess, resultReason, resultPayload = notify(
        player, success, reason, args, details)
    if giftMode and requestID ~= "" then
        rememberGift(lease, requestID, {
            success = resultSuccess,
            reason = resultReason,
            details = details,
        })
    end
    if auditInventoryRequest then
        local adapterResult = success == true and "committed"
            or (args.direction == "player_to_npc"
                or args.direction == "npc_to_player") and "failed"
            or "not_run"
        auditInventoryRequest(
            "server_transfer",
            resultSuccess and "completed" or "rejected",
            record,
            args,
            "allowed",
            authorityReason,
            adapterResult,
            resultSuccess,
            resultReason,
            sinceRevision
        )
    end
    return resultSuccess, resultReason, resultPayload
end
