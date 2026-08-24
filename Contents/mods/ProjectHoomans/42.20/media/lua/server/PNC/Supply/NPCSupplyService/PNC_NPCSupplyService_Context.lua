-- Shared NPC supply dependencies, runtime, retries, and logging.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}
PNC.NPCSupplyService.Internal = PNC.NPCSupplyService.Internal or {}

local Service = PNC.NPCSupplyService
local Request = PNC.SupplyRequest
local Metrics = PNC.SupplyMetrics
local Selector = PNC.SupplySelector
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Access = PNC.StorageAccessPolicy
local Index = PNC.SupplyIndex
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function worldHour()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours
        and PNC.NeedsUtils.WorldAgeHours() or 0
end

local function runtime(record, kind)
    record.runtime = record.runtime or {}
    record.runtime.supply = record.runtime.supply or { byKind = {} }
    local root = record.runtime.supply
    root.byKind[kind] = root.byKind[kind] or {
        phase = "IDLE", nextRetry = 0,
    }
    return root.byKind[kind], root
end

local function log(record, request, result, details)
    if not ((PNC.NeedsDebug
            and PNC.NeedsDebug.SupplyLoggingEnabled == true)
        or (PNC.Sandbox and PNC.Sandbox.NPCSupplyTransactionLoggingEnabled
            and PNC.Sandbox.NPCSupplyTransactionLoggingEnabled()))
    then return end
    local fields = {
        "[PNC][NPC_SUPPLY]",
        "npc=" .. tostring(record and record.id or "none"),
        "kind=" .. tostring(request and request.resourceKind or "none"),
        "purpose=" .. tostring(request and request.purpose or "none"),
        "priority=" .. tostring(request and request.priority or 0),
        "result=" .. tostring(result or "none"),
        "source=" .. tostring(details and details.source or "none"),
        "storage=" .. tostring(details and details.storageId or "none"),
        "item=" .. tostring(details and details.fullType or "none"),
        "typeId=" .. tostring(details and details.typeId or "none"),
        "quantity=" .. tostring(details and details.quantity or 0),
        "inventoryMode=" .. tostring(PNC.Inventory.GetPersistenceMode(record)),
        "needAfter=" .. tostring(details and details.needAfter or "none"),
        "projectionMissing=" .. tostring(
            details and details.projectionMissing == true
        ),
    }
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat(fields, " "))
    end
end

local function requestCounter(kind)
    if kind == "FOOD" then return "foodRequests" end
    if kind == "HYDRATION" then return "hydrationRequests" end
    return "medicalRequests"
end

local function retryHours(request)
    local definition = PNC.NeedsDefinitions.SUPPLY[
        request.resourceKind == "FOOD" and "hunger"
            or request.resourceKind == "HYDRATION" and "thirst"
            or "medical"
    ]
    local severe = request.priority >= 90
    return severe and definition.urgentRetryHours or definition.retryHours
end

local function fail(record, request, state, reason, details)
    state.phase = "FAILED"
    state.lastResult = "failed"
    state.lastFailureReason = reason
    state.lastAttemptAt = worldHour()
    state.nextRetry = state.lastAttemptAt + retryHours(request)
    state.reservationState = nil
    Metrics.Increment("supplyRequestsFailed")
    log(record, request, reason, details)
    return false, reason, details
end

local Internal = Service.Internal
Internal.WorldHour = worldHour
Internal.Runtime = runtime
Internal.Log = log
Internal.RequestCounter = requestCounter
Internal.RetryHours = retryHours
Internal.Fail = fail

return Internal
