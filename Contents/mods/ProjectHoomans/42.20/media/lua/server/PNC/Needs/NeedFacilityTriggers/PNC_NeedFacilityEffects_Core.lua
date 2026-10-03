if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

local Effects = PNC.NeedFacilityEffects
local afterDelay
local WORLD_WATER_RETRY_COOLDOWN_MS = 5000
local WATER_REFILL_RETRY_COOLDOWN_MS = 5000
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function resolveActivityOwner(record)
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
    if core and core.ResolvePlayerByOnlineID and onlineID ~= nil then
        player = core.ResolvePlayerByOnlineID(onlineID)
        if player then return player end
    end
    if core and core.ResolvePlayerByUsername and username then
        player = core.ResolvePlayerByUsername(username)
        if player then return player end
    end
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

-- The initial command reply only says that an activity was accepted. The
-- refill transaction happens later at the scene effect boundary, so publish
-- that final result through the same existing command-result transport.
function Effects.ReportWaterRefillResult(record, state, accepted, reason, details)
    local commandID
    local player
    local payload
    if not state or state.manual ~= true
        or state.manualActivityResultReported == true
    then
        return false
    end
    commandID = tostring(state.manualCommandID or "")
    if commandID == "" then commandID = "manual_refill" end
    state.manualActivityResultReported = true
    payload = {
        commandID = commandID,
        id = record and record.id,
        affected = accepted == true and 1 or 0,
        accepted = accepted == true,
        reason = tostring(reason or (accepted and "commanded"
            or "WATER_REFILL_FAILED")),
        targets = { record and tostring(record.id) or "" },
        requestID = state.manualRequestID,
        commandSource = state.manualCommandSource ~= ""
            and state.manualCommandSource or "colonist_activities",
        details = details,
    }
    player = resolveActivityOwner(record)
    if player and type(sendServerCommand) == "function" then
        sendServerCommand(player, PNC.Const.MODULE,
            PNC.Const.CMD_COMPANION_COMMAND_RESULT, payload)
    elseif type(triggerEvent) == "function" then
        triggerEvent("OnServerCommand", PNC.Const.MODULE,
            PNC.Const.CMD_COMPANION_COMMAND_RESULT, payload)
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("manual_activity_result npc="
            .. tostring(record and record.id or "")
            .. " command=" .. commandID
            .. " accepted=" .. tostring(accepted == true)
            .. " reason=" .. tostring(payload.reason)
            .. " requestID=" .. tostring(payload.requestID or ""))
    end
    return true
end

-- A successful bottle fill is also a hydration completion. Keep this effect
-- shared by facility, manual, and semantic refill callers so none of those
-- paths can silently refill a bottle while leaving thirst active.
function Effects.ApplyWaterRefillSuccess(record, state, filled)
    state = type(state) == "table" and state or {}
    local needs = PNC.IndividualNeeds
    local thirstBefore = needs and needs.Get
        and tonumber(needs.Get(record, "thirst")) or nil
    if not needs or not needs.Set then return false end
    local cleared = needs.Set(record, "thirst", 0, "water_refill_drink")
    if cleared == nil then return false end
    Events.emit(EventTypes.NPC_WATER_REFILL_DRANK, record,
        tostring(state.activityItemFullType or state.activityItemID or ""),
        thirstBefore or 0, tonumber(filled) or 0,
        tostring(state.resourceKey or ""))
    return true
end

local function hasLiveWaterSource(source)
    return source and (source.object ~= nil or source.item ~= nil)
end

local function worldWaterFailure(record, now, reason)
    local runtime = record and record.runtime or nil
    local current = tonumber(now)
    if not current and PNC.Core and PNC.Core.Now then
        current = tonumber(PNC.Core.Now())
    end
    if runtime then
        runtime.worldWaterRetryAt = (current or 0)
            + WORLD_WATER_RETRY_COOLDOWN_MS
    end
    return false, true, reason
end

local function optionalBottleRefill(record, state, source)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local policy = PNC.WaterHydrationPolicy
    local inventory = PNC.Inventory
    local water = PNC.WaterContainerService
    local item
    local context
    local reason
    if not activity or not policy or not policy.GetContext then
        return nil, nil, "WATER_REFILL_NOT_AUTHORIZED"
    end
    context, reason = policy.GetContext(record, {
        manualOverride = activity.manualOverride == true,
        manual = activity.manual == true,
        capability = activity.capability,
        resourceKind = activity.resourceKind,
    })
    if not context then return nil, nil, reason end
    if not inventory then return nil, nil, "WATER_CONTAINER_UNAVAILABLE" end
    item = inventory.GetWaterContainer
        and inventory.GetWaterContainer(record)
        or inventory.FindWaterContainer
        and inventory.FindWaterContainer(record)
        or nil
    if not item or not inventory.IsRefillableWaterContainer
        or not inventory.IsRefillableWaterContainer(item)
    then
        return nil, nil, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    if not source or not source.object or not water
        or not water.Refill
    then
        return nil, nil, "WATER_SOURCE_NOT_REFILLABLE"
    end
    if water.IsFillableFaucet
        and water.IsFillableFaucet(source.object) ~= true
    then
        return nil, nil, "WATER_SOURCE_NOT_REFILLABLE"
    end
    local ok, filled, refillReason = water.Refill(record, item.id, source)
    if ok ~= true then
        return nil, nil, refillReason or "WATER_REFILL_FAILED"
    end
    return filled, item.id, nil
end

Effects.Internal = Effects.Internal or {}
local Internal = Effects.Internal
Internal.ResolveActivityOwner = resolveActivityOwner
Internal.HasLiveWaterSource = hasLiveWaterSource
Internal.WorldWaterFailure = worldWaterFailure
Internal.OptionalBottleRefill = optionalBottleRefill
Internal.WORLD_WATER_RETRY_COOLDOWN_MS = WORLD_WATER_RETRY_COOLDOWN_MS
Internal.WATER_REFILL_RETRY_COOLDOWN_MS = WATER_REFILL_RETRY_COOLDOWN_MS

return Effects
