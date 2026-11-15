-- Unified work-output ledger, capture, and stockpile/abstract delivery service.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkOutputService = PNC.WorkOutputService or {}
PNC.WorkOutputService.Internal = PNC.WorkOutputService.Internal or {}

require "PNC/Production/WorkOutputService/PNC_WorkOutputService_CaptureGround"
require "PNC/Production/WorkOutputService/PNC_WorkOutputService_CaptureInventory"
require "PNC/Production/WorkOutputService/PNC_WorkOutputService_Deposit"
require "PNC/Production/WorkOutputService/PNC_WorkOutputService_Storage"
require "PNC/Production/WorkOutputService/PNC_WorkOutputService_LiveTick"
require "PNC/Production/WorkOutputService/PNC_WorkOutputService_Abstract"

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local nowMs = Internal.Now

local function copyItems(items)
    local output, count, total = {}, 0, 0
    for _, entry in ipairs(type(items) == "table" and items or {}) do
        if type(entry) == "table" then
            count = count + 1
            local qty = math.max(1, math.floor(tonumber(
                entry.quantity or entry.stack or entry.count) or 1))
            total = total + qty
            output[#output + 1] = {
                id = entry.id,
                fullType = entry.fullType or entry.type,
                quantity = qty,
                collected = entry.collected == true,
                delivered = entry.delivered == true,
            }
        end
    end
    return output, count, total
end

---Creates or returns the durable output effect attached to target.
function Service.EnsureOutputEffect(target, mode, items, opts)
    if type(target) ~= "table" then return nil end
    opts = opts or {}
    if type(target.outputEffect) == "table" and opts.replaceExisting ~= true then
        return target.outputEffect
    end
    local createdAt = nowMs()
    local sourceMode = tostring(mode or "ABSTRACT")
    local ownerKey = opts.ownerKey or opts.treeKey or opts.orderId or target.key or target.id
    local effectID = opts.id or (PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("work_output"))
        or ("work_output:" .. tostring(ownerKey or createdAt))
    local storedItems, itemCount, actualQuantity = copyItems(items)
    local qty = tonumber(opts.quantity) or actualQuantity
    local effect = {
        id = tostring(effectID),
        kind = tostring(opts.kind or "WORK_OUTPUT"),
        operation = tostring(opts.operation or opts.kind or "WORK_OUTPUT"),
        state = tostring(opts.state or "PENDING"),
        phase = tostring(opts.phase or (sourceMode == "LIVE"
            and "OUTPUT_PENDING" or "ABSTRACT_PENDING")),
        ownerKey = ownerKey,
        treeKey = opts.treeKey,
        orderId = opts.orderId,
        x = opts.x, y = opts.y, z = opts.z,
        sourceX = opts.sourceX or opts.x,
        sourceY = opts.sourceY or opts.y,
        sourceZ = opts.sourceZ or opts.z,
        sourceMode = sourceMode,
        deliveryMode = tostring(opts.deliveryMode or (sourceMode == "LIVE"
            and "WORLD_FLOOR" or "ABSTRACT_INVENTORY")),
        pickupState = tostring(opts.pickupState or (sourceMode == "LIVE"
            and "ON_GROUND" or "ABSTRACT_PENDING")),
        lootSource = opts.lootSource,
        workerId = opts.workerId or opts.workerID,
        workerID = opts.workerId or opts.workerID,
        quantity = qty,
        expectedQuantity = tonumber(opts.expectedQuantity) or qty,
        items = storedItems,
        itemCount = itemCount,
        totalQuantity = actualQuantity,
        actualQuantity = actualQuantity,
        createdAt = createdAt,
        updatedAt = createdAt,
        waitReason = opts.reason,
        lastReason = opts.reason,
        identity = opts.identity or {
            ownerKey = ownerKey,
            sourceMode = sourceMode,
        },
    }
    target.outputEffect = effect
    if type(opts.markDirty) == "function" then opts.markDirty() end
    return effect
end

---Updates durable output effect state and timestamps.
function Service.SetOutputEffectState(effect, state, reason, opts)
    if type(effect) ~= "table" then return end
    local at = nowMs()
    effect.state = tostring(state or "PENDING")
    effect.updatedAt = at
    effect.lastReason = reason
    effect.waitReason = effect.state == "APPLIED" and nil or reason
    effect.phase = effect.state == "APPLIED" and "DELIVERED"
        or effect.phase or "OUTPUT_PENDING"
    if effect.state == "APPLIED" then
        effect.pickupState = effect.pickupState == "STOCKPILE"
            and "STOCKPILE" or "DELIVERED"
        effect.appliedAt = at
    end
    if opts and type(opts.markDirty) == "function" then opts.markDirty() end
end

---Releases any output capacity reservation held by context.
function Service.ReleaseOutputCapacity(context, storageService)
    storageService = storageService or PNC.ColonyStorageService
    local owner = context and context.outputCapacityReservationId or nil
    if owner and storageService
        and type(storageService.ReleaseOutputCapacity) == "function"
    then
        storageService.ReleaseOutputCapacity(owner)
    end
    if context then
        context.outputCapacityReservationId = nil
        context.outputCapacityDetails = nil
        context.outputWaitReason = nil
        context.outputWaitStorageId = nil
        context.outputWaitStorageRevision = nil
    end
end

return Service
