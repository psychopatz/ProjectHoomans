-- Server-authoritative world-item removal and inventory transfer/rip commits.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

PNC = PNC or {}
PNC.WorldItemExecutor = PNC.WorldItemExecutor or {}
PNC.WorldItemExecutor.Internal = PNC.WorldItemExecutor.Internal or {}

local Executor = PNC.WorldItemExecutor
local Internal = Executor.Internal

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    if not ok then return nil end
    return value
end

local function removeFromWorldSource(cand)
    if cand.sourceType == "curtain" then
        local sq, obj = cand.square, cand.object
        if not obj then return false, "curtain_missing" end
        if sq and sq.transmitRemoveItemFromSquare then
            sq:transmitRemoveItemFromSquare(obj)
        elseif sq and sq.RemoveTileObject then
            sq:RemoveTileObject(obj)
        elseif obj.removeFromSquare then
            obj:removeFromSquare()
        else
            return false, "curtain_remove_failed"
        end
        if IsoGridSquare and IsoGridSquare.setRecalcLightTime then
            pcall(IsoGridSquare.setRecalcLightTime, -1.0)
        end
        return true
    end
    if cand.sourceType == "floor" then
        local sq, wo = cand.square, cand.worldObject
        if sq and sq.transmitRemoveItemFromSquare and wo then
            sq:transmitRemoveItemFromSquare(wo)
            return true
        end
        if wo and wo.removeFromWorld then
            wo:removeFromWorld()
            if wo.removeFromSquare then wo:removeFromSquare() end
            return true
        end
        return false, "floor_remove_failed"
    end
    local container, item = cand.container, cand.item
    local removed = false
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
        removed = true
    elseif container.Remove then
        container:Remove(item)
        removed = true
    elseif container.RemoveItem then
        container:RemoveItem(item)
        removed = true
    end
    if not removed then return false, "container_remove_failed" end
    if isServer and isServer() == true and sendRemoveItemFromContainer then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return true
end

local function encodeSpecFromWorldItem(cand)
    local fullType = cand.itemCtx and cand.itemCtx.fullType
        or tostring(safeCall(cand.item, "getFullType") or "")
    local fallback = { type = fullType, stack = 1 }
    if not CoreInventory or type(CoreInventory.encodeItem) ~= "function" then
        return fallback
    end
    local ok, encoded = pcall(CoreInventory.encodeItem, cand.item, 1)
    if not ok or type(encoded) ~= "table" then return fallback end
    local bridge = PNC.Inventory and PNC.Inventory.CoreBridge or nil
    local stateCodec = bridge and bridge.StateCodec or nil
    if stateCodec and type(stateCodec.readValidatedState) == "function" then
        local decoded = stateCodec.readValidatedState(encoded)
        if type(decoded) == "table" then
            decoded.type = fullType
            decoded.stack = 1
            return decoded
        end
    end
    return fallback
end

function Internal.CommitAction(intent, record, body)
    local valid, validReason = Internal.IsCandidateStillValid(intent)
    if not valid then return false, validReason end
    local inv = PNC.Inventory
    if not inv or type(inv.AddItems) ~= "function" then
        return false, "inventory_unavailable"
    end
    local cand = intent.candidate
    local specs, reasonTag
    if intent.action == "rip_bandage" then
        local rip = cand.itemCtx and cand.itemCtx.rippable
        if not rip then return false, "not_rippable" end
        specs = { { type = rip.outputType, stack = math.max(1, tonumber(rip.outputCount) or 2) } }
        reasonTag = "world_item_rip"
    else
        specs = { encodeSpecFromWorldItem(cand) }
        reasonTag = "world_item_" .. tostring(intent.purpose or "grab")
    end

    if type(inv.CanAccept) == "function" then
        local canAccept, acceptReason = inv.CanAccept(record, specs, "root")
        if not canAccept then return false, acceptReason or "no_capacity" end
    end

    local removed, remReason = removeFromWorldSource(cand)
    if not removed then return false, remReason or "remove_failed" end

    local addedOK, addReason, addedIds = inv.AddItems(record, specs, "root", reasonTag)
    if not addedOK then
        return false, addReason or "inventory_add_failed"
    end
    if body and addedIds and type(inv.MaterializeItem) == "function" then
        for index = 1, #addedIds do
            inv.MaterializeItem(record, body, addedIds[index])
        end
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    if intent.action == "rip_bandage" then
        local rip = cand.itemCtx.rippable
        intent.collectedCount = intent.collectedCount + (tonumber(rip.outputCount) or 2)
        if PNC.ProvisionScheduler and PNC.ProvisionScheduler.MarkDirty then
            PNC.ProvisionScheduler.MarkDirty(record, "bandage", 0)
        end
        if intent.medicalTaskId
            and PNC.MedicalCareExecutor
            and type(PNC.MedicalCareExecutor.FulfillBandageSupport) == "function"
        then
            PNC.MedicalCareExecutor.FulfillBandageSupport(intent.medicalTaskId)
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = intent.action == "rip_bandage"
        and "world_item_ripped" or "world_item_grabbed"
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, record.runtime.forceSyncEvent)
    end
    return true
end

return Executor
