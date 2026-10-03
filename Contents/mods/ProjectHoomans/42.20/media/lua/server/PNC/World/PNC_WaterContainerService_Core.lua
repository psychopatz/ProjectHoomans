-- Server-authoritative refill transactions for NPC liquid containers.
-- Destination state is committed before source water is debited; if the
-- source cannot be consumed, both compact and physical destination state are
-- restored. This keeps a failed path/interaction from duplicating water.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WaterContainerService = PNC.WaterContainerService or {}

local Service = PNC.WaterContainerService
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Inventory = PNC.Inventory
local NearbyWater = PNC.NearbyWaterService
local SupplyInternal = PNC.SupplyInventoryInternal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local EPSILON = 0.0001

-- Project Zomboid exposes Java members through a curated allowlist
-- (zombie.Lua.LuaManager$Exposer). Reading a member that is not exposed on a
-- Java object raises a Java RuntimeException instead of returning nil, so the
-- read itself has to be guarded for this helper to honour its own contract.
local function indexMember(object, member)
    return object[member]
end

local function call(object, method, ...)
    if object == nil then return nil end
    local loaded, fn = pcall(indexMember, object, method)
    if not loaded or type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

-- java.lang.Class is itself not exposed, so object:getClass():getName() throws
-- ("attempted index: getName of non-table: class ..."). Use the Java-backed
-- global the base game also uses, then fall back to plain Lua fields.
local classNameOf = getClassSimpleName

local function objectType(object)
    if object == nil then return "" end
    if classNameOf then
        local ok, name = pcall(classNameOf, object)
        if ok and name ~= nil then return tostring(name) end
    end
    return tostring(call(object, "getClassName")
        or call(object, "className")
        or call(object, "__type")
        or "")
end

local function fluidType(object)
    local container = call(object, "getFluidContainer")
    local fluid = call(object, "getPrimaryFluid")
        or call(container, "getPrimaryFluid")
    local value = call(fluid, "getFluidTypeString")
    if value then return tostring(value) end
    return call(object, "hasWater") == true and "Water" or ""
end

local function rawSourceAmount(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    return tonumber(call(object, "getFluidAmount"))
        or tonumber(call(object, "getWaterAmount"))
        or tonumber(call(container, "getAmount"))
end

local function setStateDetails(details, prefix, state)
    if type(state) ~= "table" then return end
    details[prefix .. "Amount"] = state.fluidAmount
    details[prefix .. "Capacity"] = state.fluidCapacity
    details[prefix .. "PrimaryType"] = state.fluidPrimaryType
    details[prefix .. "InputLocked"] = state.fluidInputLocked
    if type(state.fluids) == "table" then
        local entries = {}
        for index = 1, #state.fluids do
            local entry = state.fluids[index]
            entries[#entries + 1] = tostring(entry and entry.type or "")
                .. ":" .. tostring(entry and entry.amount or "")
        end
        details[prefix .. "Fluids"] = table.concat(entries, ",")
    end
end

local function activityDetails(record, details)
    local runtime = record and record.runtime
    local activity = runtime and runtime.facilityActivity
    local scene = runtime and runtime.animationScene
    details.currentActivity = activity and activity.capability or ""
    details.currentActivityPhase = activity and activity.phase or ""
    details.currentScene = scene and scene.id or ""
    details.currentSceneStep = scene and scene.step or ""
end

local function logRefill(event, record, item, source, details)
    local itemID
    local itemType
    local sourceKey
    local fields
    if not Diagnostics or Diagnostics.InventoryAuditEnabled ~= true
        or not Diagnostics.LogInventoryAudit
    then
        return
    end
    itemID = type(item) == "table" and item.id or item
    itemType = type(item) == "table"
        and (item.type or item.fullType) or nil
    sourceKey = type(source) == "table" and source.key or nil
    fields = {
        "npc=" .. tostring(record and record.id or ""),
        "item=" .. tostring(itemID or ""),
        "type=" .. tostring(itemType or ""),
        "source=" .. tostring(sourceKey or ""),
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        if type(value) ~= "table" and type(value) ~= "function" then
            fields[#fields + 1] = tostring(key) .. "=" .. tostring(value)
        end
    end
    Diagnostics.LogInventoryAudit("refill_" .. tostring(event), fields)
end

local function logRefillAdmission(record, item, itemID, compactDescription,
    native, nativeDescription, candidateCount, accepted, reason)
    local compact
    if not Diagnostics or Diagnostics.InventoryAuditEnabled ~= true
        or not Diagnostics.LogInventoryAudit
    then
        return
    end
    compact = type(compactDescription) == "table"
        and compactDescription or nil
    logRefill("admission", record, item or itemID, nil, {
        result = accepted == true and "accepted" or "rejected",
        reason = reason,
        requestedItemID = itemID,
        resolvedItemID = item and item.id or nil,
        candidateCount = candidateCount,
        physicalPresent = native ~= nil,
        physicalID = native and (call(native, "getID") or native.id) or nil,
        physicalType = native and (call(native, "getFullType") or native.type)
            or nil,
        compactAmount = compact and compact.amount,
        compactCapacity = compact and compact.capacity,
        compactFreeCapacity = compact and compact.freeCapacity,
        compactPrimaryType = compact and compact.primaryType,
        compactCanFill = compact and compact.canFill,
        physicalAmount = nativeDescription and nativeDescription.amount,
        physicalCapacity = nativeDescription and nativeDescription.capacity,
        physicalFreeCapacity = nativeDescription
            and nativeDescription.freeCapacity,
        physicalPrimaryType = nativeDescription
            and nativeDescription.primaryType,
        physicalCanFill = nativeDescription and nativeDescription.canFill,
    })
end

local function deepCopy(value)
    if PNC.Core and PNC.Core.DeepCopy then return PNC.Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = deepCopy(entry) end
    return result
end

local function sameFluidDescription(left, right)
    local capacityMatches
    if not left or not right then return false end
    capacityMatches = left.capacity == nil or right.capacity == nil
        or math.abs((tonumber(left.capacity) or 0)
            - (tonumber(right.capacity) or 0)) <= EPSILON
    return math.abs((tonumber(left.amount) or 0)
            - (tonumber(right.amount) or 0)) <= EPSILON
        and capacityMatches
        and tostring(left.primaryType or "")
            == tostring(right.primaryType or "")
        and (left.inputLocked == true) == (right.inputLocked == true)
end

local function reconcileCompactDescription(record, item, compactDescription,
    authoritativeDescription)
    if sameFluidDescription(compactDescription, authoritativeDescription) then
        return false
    end
    if not Inventory.ApplyDelta or not authoritativeDescription
        or not authoritativeDescription.state
    then
        return false
    end
    return Inventory.ApplyDelta(record, {{
        op = "update",
        itemID = item.id,
        itemState = authoritativeDescription.state,
    }}, "water_refill_state_reconcile") == true
end

local function syncNative(item)
    if item and type(item.syncItemFields) == "function" then
        item:syncItemFields()
    end
    if sendItemStats and item then sendItemStats(item) end
end

local function sourceAmount(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    if NearbyWater.IsInfiniteFaucet(object) then return nil end
    return tonumber(call(object, "getFluidAmount"))
        or tonumber(call(object, "getWaterAmount"))
        or tonumber(call(container, "getAmount"))
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function ownerPlayer(record)
    local core = PNC.Core
    local order = record and record.orderSpec or {}
    local activity = record and record.runtime
        and record.runtime.facilityActivity or {}
    local previousOrder = activity.previousOrder or {}
    local player
    local onlineID = record and record.ownerOnlineID
        or order and order.ownerOnlineID
        or previousOrder.ownerOnlineID
    local username = record and record.ownerUsername
        or order and order.ownerUsername
        or previousOrder.ownerUsername
    if not core or not record then return nil end
    if core.ResolvePlayerByOnlineID and onlineID ~= nil then
        player = core.ResolvePlayerByOnlineID(onlineID)
        if player then return player end
    end
    if core.ResolvePlayerByUsername and username then
        player = core.ResolvePlayerByUsername(username)
        if player then return player end
    end
    return nil
end

-- Inventory.ApplyDelta is the authoritative server mutation, but it does not
-- know which client has a character window open. Push the committed full
-- payload to the owner so the compact itemState decoder on the client cannot
-- remain at the pre-refill amount.
local function syncOwnerInventory(record)
    local network = PNC.Network
    local player = ownerPlayer(record)
    local ok
    local result
    if not network or type(network.SendCharacterPayload) ~= "function" then
        return false, "network_unavailable"
    end
    if not player then return false, "owner_unavailable" end
    ok, result = pcall(network.SendCharacterPayload, player, record)
    if not ok then return false, tostring(result or "payload_send_failed") end
    return true, "character_payload"
end

local function captureSource(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    local infinite = NearbyWater.IsInfiniteFaucet(object) == true
    return {
        fluid = not infinite and container and Portable.CaptureFluid(object)
            or nil,
        amount = sourceAmount(entry),
        rawAmount = rawSourceAmount(entry),
    }
end

local function restoreSource(entry, before)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    local restored = true
    local currentAmount
    if not object or not before then return true end
    if before.fluid then
        restored = Portable.ApplyFluid(object, before.fluid) == true
    end
    if before.amount ~= nil and not restored
        or before.amount ~= nil and before.rawAmount ~= nil
            and rawSourceAmount(entry) ~= before.rawAmount
    then
        if container and type(container.adjustAmount) == "function" then
            container:adjustAmount(before.amount)
            restored = true
        end
        if (not restored or not container)
            and type(object.setWaterAmount) == "function"
        then
            local ok, value = pcall(object.setWaterAmount, object,
                before.amount)
            restored = ok and value ~= false
        end
    end
    if restored and type(object.sync) == "function" then
        object:sync()
    end
    if restored and before.rawAmount ~= nil then
        currentAmount = rawSourceAmount(entry)
        restored = currentAmount ~= nil
            and math.abs(currentAmount - before.rawAmount) <= EPSILON
    end
    return restored
end

local function targetState(before, capacity, amount)
    local state = {
        fluidAmount = amount,
        fluidCapacity = capacity,
        fluidPrimaryType = "Water",
        fluidInputLocked = false,
        fluids = { { type = "Water", amount = amount } },
    }
    if before and before.fluidCanPlayerEmpty ~= nil then
        state.fluidCanPlayerEmpty = before.fluidCanPlayerEmpty
    end
    if before and before.fluidRainCatcher ~= nil then
        state.fluidRainCatcher = before.fluidRainCatcher
    end
    return state
end

local function rollbackDestination(record, item, native, beforeState, oldState,
    materializeUndo)
    local physicalRestored = true
    local compactRestored = true
    if native and beforeState then
        physicalRestored = Portable.ApplyFluid(native, beforeState) == true
        syncNative(native)
    end
    if Inventory.ApplyDelta and item then
        compactRestored = Inventory.ApplyDelta(record, {{
            op = "update", itemID = item.id,
            itemState = oldState or {},
        }}, "water_refill_rollback")
    end
    if materializeUndo then pcall(materializeUndo) end
    return physicalRestored, compactRestored
end


Service.Internal = Service.Internal or {}
Service.Internal.Portable = Portable
Service.Internal.Events = Events
Service.Internal.EventTypes = EventTypes
Service.Internal.Inventory = Inventory
Service.Internal.NearbyWater = NearbyWater
Service.Internal.SupplyInternal = SupplyInternal
Service.Internal.Diagnostics = Diagnostics
Service.Internal.EPSILON = EPSILON
Service.Internal.call = call
Service.Internal.objectType = objectType
Service.Internal.fluidType = fluidType
Service.Internal.rawSourceAmount = rawSourceAmount
Service.Internal.setStateDetails = setStateDetails
Service.Internal.activityDetails = activityDetails
Service.Internal.logRefill = logRefill
Service.Internal.logRefillAdmission = logRefillAdmission
Service.Internal.deepCopy = deepCopy
Service.Internal.sameFluidDescription = sameFluidDescription
Service.Internal.reconcileCompactDescription = reconcileCompactDescription
Service.Internal.syncNative = syncNative
Service.Internal.sourceAmount = sourceAmount
Service.Internal.liveBody = liveBody
Service.Internal.ownerPlayer = ownerPlayer
Service.Internal.syncOwnerInventory = syncOwnerInventory
Service.Internal.captureSource = captureSource
Service.Internal.restoreSource = restoreSource
Service.Internal.targetState = targetState
Service.Internal.rollbackDestination = rollbackDestination

return Service
