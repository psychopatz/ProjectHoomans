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

local function aidTransferInRange(donor, patient)
    local medical = PNC.MedicalCareExecutor
    local medicalInternal = medical and medical.Internal or nil
    local donorBody = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(donor.id) or nil
    local patientBody = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(patient.id) or nil
    local perception = PNC.Perception
    if donorBody and patientBody and perception and perception.CanSeeWorldObject
        and perception.CanSeeWorldObject(donor, patientBody) ~= true then return false end
    if medicalInternal and type(medicalInternal.Position) == "function"
        and type(medicalInternal.InTreatmentRange) == "function"
    then
        local dx, dy = medicalInternal.Position(donor, donorBody)
        local px, py = medicalInternal.Position(patient, patientBody)
        if tonumber(dx) == nil or tonumber(dy) == nil
            or tonumber(px) == nil or tonumber(py) == nil
        then
            return false
        end
        return medicalInternal.InTreatmentRange(
            donor, donorBody, patient, patientBody
        ) == true
    end
    local donorX = donorBody and donorBody.getX
        and tonumber(donorBody:getX()) or tonumber(donor.x)
    local donorY = donorBody and donorBody.getY
        and tonumber(donorBody:getY()) or tonumber(donor.y)
    local donorZ = donorBody and donorBody.getZ
        and tonumber(donorBody:getZ()) or tonumber(donor.z) or 0
    local patientX = patientBody and patientBody.getX
        and tonumber(patientBody:getX()) or tonumber(patient.x)
    local patientY = patientBody and patientBody.getY
        and tonumber(patientBody:getY()) or tonumber(patient.y)
    local patientZ = patientBody and patientBody.getZ
        and tonumber(patientBody:getZ()) or tonumber(patient.z) or 0
    local range = tonumber(PNC.Const and PNC.Const.BANDAGE_RANGE) or 3
    if donorX == nil or donorY == nil or patientX == nil or patientY == nil
        or math.abs(donorZ - patientZ) >= 1
    then
        return false
    end
    local deltaX = donorX - patientX
    local deltaY = donorY - patientY
    return deltaX * deltaX + deltaY * deltaY <= range * range
end

local function medicalBandageItemType(fullType)
    local treatment = PNC.Treatment
    return treatment and type(treatment.IsBandageType) == "function"
        and treatment.IsBandageType(fullType) == true or false
end

local function rollbackCallback(callback)
    -- Consume/materialization providers return rollback callbacks across a
    -- service boundary; contain provider failure while preserving this action.
    if type(callback) ~= "function" then return false end
    local ok, result = pcall(callback)
    return ok and result ~= false
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
        or not medical or type(medical.IsDoctor) ~= "function"
        or medical.IsDoctor(record) ~= true
        or type(medical.SameCareGroup) ~= "function"
        or not medical.SameCareGroup(record, patient)
        or type(medical.CurrentPart) ~= "function"
        or not medical.CurrentPart(patient)
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
        or not medical or not medical.SameCareGroup
        or not medical.IsDoctor
        or not medical.IsDoctor(requester)
        or not medical.SameCareGroup(donor, patient)
        or not medical.SameCareGroup(requester, patient)
        or type(medical.CurrentPart) ~= "function"
        or not medical.CurrentPart(patient)
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

-- Direct NPC-to-NPC bandage gift used by an explicitly accepted injury-aid
-- action. The caller owns proximity and social policy; this authority boundary
-- rechecks patient need and both compact inventories before committing.
function Service.TransferMedicalBandageForAid(donorID, patientID, itemID)
    local donor = Registry and Registry.Get and Registry.Get(donorID) or nil
    local patient = Registry and Registry.Get and Registry.Get(patientID) or nil
    local treatment = PNC.Treatment
    local wounds = PNC.NPCWounds
    local donorPlan
    local patientPlan
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
    local removed
    local nativeRollbackOk
    local donorRollbackOk
    if not (PNC.Core and type(PNC.Core.IsAuthority) == "function"
        and PNC.Core.IsAuthority() == true)
    then
        return false, "not_authority"
    end
    if not donor or donor.alive == false
        or not patient or patient.alive == false
        or tostring(donor.id) == tostring(patient.id)
    then
        return false, "invalid_aid_participant"
    end
    if combatActive(donor) or combatActive(patient) then
        return false, "combat_active"
    end
    if not aidTransferInRange(donor, patient) then
        return false, "out_of_range"
    end
    if not treatment or type(treatment.GetNPCBandagePlan) ~= "function"
        or type(treatment.IsBandageType) ~= "function"
        or not wounds or type(wounds.GetTreatableWounds) ~= "function"
        or not Inventory or type(Inventory.CanAccept) ~= "function"
        or type(Inventory.AddItems) ~= "function"
        or type(Inventory.RemoveItems) ~= "function"
    then
        return false, "medical_transfer_unavailable"
    end
    if #wounds.GetTreatableWounds(patient) == 0 then
        return false, "patient_has_no_treatable_wound"
    end
    patientPlan = treatment.GetNPCBandagePlan(patient, { consumeItem = true })
    if patientPlan and patientPlan.itemID then
        return false, "medical_supply_already_available"
    end
    donorPlan = treatment.GetNPCBandagePlan(donor, { consumeItem = true })
    if not donorPlan
        or tostring(donorPlan.itemID or "") ~= tostring(itemID or "")
        or treatment.IsBandageType(donorPlan.fullType) ~= true
    then
        return false, "donor_bandage_unavailable"
    end
    donorInventory = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(donor, {
            reconcileWaterContainer = false,
        }) or donor.inventory
    item = donorInventory and donorInventory.items
        and donorInventory.items[tostring(itemID or "")] or nil
    if not item or not treatment.IsBandageType(item.type) then
        return false, "donor_bandage_unavailable"
    end
    spec = inventoryItemSpec(item)
    if not spec or not spec.type then return false, "bandage_item_invalid" end
    canAccept, acceptReason = Inventory.CanAccept(patient, { spec }, "root")
    if not canAccept then return false, acceptReason or "inventory_full" end
    if not PNC.SupplyInventory
        or type(PNC.SupplyInventory.Consume) ~= "function"
    then
        return false, "supply_consumption_unavailable"
    end
    consumed, consumeReason, effect = PNC.SupplyInventory.Consume(
        donor,
        itemID,
        {
            resourceKind = "MEDICAL",
            treatment = "BANDAGE",
            required = {},
            source = "injury_aid_bandage_gift",
        }
    )
    if not consumed then
        return false, consumeReason or "donor_bandage_unavailable"
    end
    added, addReason, compactIDs = Inventory.AddItems(
        patient, { spec }, "root", "injury_aid_bandage_gift")
    if not added then
        donorRollbackOk = effect and rollbackCallback(effect.undo) or false
        if not donorRollbackOk then
            return false, "donor_inventory_rollback_failed"
        end
        return false, addReason or "recipient_inventory_rejected"
    end
    if not compactIDs or not compactIDs[1] then
        -- The recipient may already own a compact copy; retain the donor
        -- consumption rather than risking a duplicated physical bandage.
        return false, "recipient_inventory_item_missing"
    end
    body = Registry.GetLiveZombie and Registry.GetLiveZombie(patient.id) or nil
    if body then
        if type(Inventory.MaterializeItem) ~= "function" then
            removed = Inventory.RemoveItems(patient, compactIDs,
                "injury_aid_bandage_gift_projection_rollback")
            if removed ~= true then
                return false, "recipient_inventory_rollback_failed"
            end
            donorRollbackOk = effect and rollbackCallback(effect.undo) or false
            if not donorRollbackOk then
                return false, "donor_inventory_rollback_failed"
            end
            return false, "live_inventory_projection_unavailable"
        end
        projected, projectionReason, projectionUndo = Inventory.MaterializeItem(
            patient, body, compactIDs[1])
        if not projected then
            nativeRollbackOk = projectionUndo == nil
                or rollbackCallback(projectionUndo)
            if not nativeRollbackOk then
                return false, "native_projection_rollback_failed"
            end
            removed = Inventory.RemoveItems(patient, compactIDs,
                "injury_aid_bandage_gift_projection_rollback")
            if removed ~= true then
                return false, "recipient_inventory_rollback_failed"
            end
            donorRollbackOk = effect and rollbackCallback(effect.undo) or false
            if not donorRollbackOk then
                return false, "donor_inventory_rollback_failed"
            end
            return false, projectionReason or "live_inventory_projection_failed"
        end
    end
    if Network and Network.BroadcastRecord then
        Network.BroadcastRecord(donor, "medical_bandage_shared")
        Network.BroadcastRecord(patient, "medical_bandage_received")
    end
    return true, "bandage_gifted", {
        donorID = donor.id,
        patientID = patient.id,
        itemType = item.type,
        itemID = compactIDs[1],
    }
end


-- Inventory application query used by the generic transfer validator.
Internal.medicalSupplyGiftTask = medicalSupplyGiftTask
return Service
