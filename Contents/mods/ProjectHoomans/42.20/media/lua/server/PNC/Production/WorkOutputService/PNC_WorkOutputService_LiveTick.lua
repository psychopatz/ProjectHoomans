-- Live work-output pickup and stockpile deposit state machine.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local nowMs = Internal.Now
local pickupGroundOutput = Internal.PickupGroundOutput
local oneShotAnimation = Internal.OneShotAnimation
local enterStockpileWait = Internal.EnterStockpileWait
local ensureDestinationCapacity = Internal.EnsureDestinationCapacity
local depositOutputItems = Internal.DepositOutputItems
local haltMovement = Internal.HaltMovement
local markDirty = Internal.MarkDirty
local updateContext = Internal.UpdateContext

local function waitFailure(context, record, effect, at, reason, opts)
    context.state = "WAITING"
    effect.waitReason, effect.lastReason, effect.updatedAt = reason, reason, at
    updateContext(opts, record, context, effect)
    markDirty(opts)
    return true, false, reason
end

local function moveToTarget(record, body, x, y, z, reason)
    if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
        PNC.BehaviorCommon.MoveRecord(record, body, x, y, z, "walk", 0.7, reason)
    end
end

local function stepApproachAndPickup(context, record, body, effect, at, opts)
    local square = opts and type(opts.getSquare) == "function"
        and opts.getSquare(effect.x, effect.y, effect.z) or nil
    if not square then
        local cell = getCell and getCell() or nil
        local worldCtx = PNC and PNC.WorldItemContext
        if worldCtx and worldCtx.GetSquareSnapshot and cell then
            local snap = worldCtx.GetSquareSnapshot(cell, effect.x, effect.y, effect.z)
            square = snap and snap.square or nil
        elseif cell and type(cell.getGridSquare) == "function" then
            square = cell:getGridSquare(effect.x, effect.y, effect.z)
        end
    end
    if not square then
        context.phase = opts and opts.chunkWaitPhase or "WAITING_FOR_OUTPUT_CHUNK"
        local waitReason = opts and opts.chunkWaitReason or "OUTPUT_CHUNK_LOADING"
        waitFailure(context, record, effect, at, waitReason, opts)
        return true, false, opts and opts.chunkWaitReturnReason or "output_chunk_loading"
    end
    if context.phase == "OUTPUT_APPROACH" then
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        local stopDist = tonumber(opts and opts.pickupStopDistance) or 1.5
        if math.abs((tonumber(bx) or 0) - (effect.x + 0.5))
            + math.abs((tonumber(by) or 0) - (effect.y + 0.5)) > stopDist
        then
            moveToTarget(record, body, effect.x + 0.5, effect.y + 0.5, effect.z,
                opts and opts.moveReason or "work_output")
            updateContext(opts, record, context, effect)
            return true, false, "traveling_to_work_output"
        end
        haltMovement(record, body, "work_grab")
        context.state, context.phase = "WORKING", "GRAB_PENDING"
    end
    if context.phase == "GRAB_PENDING" then
        local status, reason = oneShotAnimation(context, record, body,
            opts and opts.grabSceneId or "work.grab", "work_output_grab")
        if status == "failed" then return waitFailure(context, record, effect, at, reason, opts) end
        if status ~= "completed" then
            updateContext(opts, record, context, effect)
            return true, false, "grabbing_work_output"
        end
        local picked, pickupReason = pickupGroundOutput(context, record, body, effect, square, opts)
        if not picked then
            effect.phase = "GRAB_PENDING"
            updateContext(opts, record, context, effect)
            return true, false, pickupReason
        end
    end
    return nil
end

---Drives live ground pickup and stockpile capacity-checked delivery to completion.
function Service.TickLiveDelivery(context, record, body, effect, at, opts)
    opts = opts or {}
    at = tonumber(at) or nowMs()
    if type(effect) ~= "table" then
        Service.ReleaseOutputCapacity(context, PNC.ColonyStorageService)
        if context then context.state, context.phase = "FAILED", "FAILED" end
        return false, false, "WORK_OUTPUT_EFFECT_MISSING"
    end
    if tostring(effect.state or "") == "APPLIED" then
        Service.ReleaseOutputCapacity(context, PNC.ColonyStorageService)
        if context then context.pendingOutput, context.state, context.phase = nil, "READY", "RECONCILING" end
        updateContext(opts, record, context, nil)
        return true, true, "work_output_already_delivered"
    end
    if context.phase == "WAITING_FOR_WORKER" or not context.phase then
        context.state = "TRAVELING"
        context.phase = effect.pickupState == "NPC_INVENTORY"
            and "OUTPUT_DESTINATION_APPROACH" or "OUTPUT_APPROACH"
    end
    if context.phase == "OUTPUT_APPROACH" or context.phase == "GRAB_PENDING" then
        local ok, complete, reason = stepApproachAndPickup(context, record, body, effect, at, opts)
        if ok ~= nil then return ok, complete, reason end
    end
    if context.phase == "WAITING_FOR_STOCKPILE" or context.phase == "OUTPUT_DESTINATION_APPROACH" then
        local dest, _, waitReason = ensureDestinationCapacity(context, record, body, effect, at, opts)
        if not dest then return true, false, waitReason end
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        if math.abs((tonumber(bx) or 0) - dest.x)
            + math.abs((tonumber(by) or 0) - dest.y) > (tonumber(opts.depositStopDistance) or 0.8)
        then
            context.state, context.phase = "TRAVELING", "OUTPUT_DESTINATION_APPROACH"
            moveToTarget(record, body, dest.x, dest.y, dest.z, opts.moveReason or "work_stockpile")
            updateContext(opts, record, context, effect)
            return true, false, "traveling_to_work_stockpile"
        end
        haltMovement(record, body, "work_deposit")
        context.state, context.phase = "WORKING", "DEPOSIT_PENDING"
    end
    if context.phase == "DEPOSIT_PENDING" then
        local dest, storage, waitReason = ensureDestinationCapacity(context, record, body, effect, at, opts)
        if not dest then return true, false, waitReason end
        local status, reason = oneShotAnimation(context, record, body,
            opts.depositSceneId or "work.deposit", "work_output_deposit")
        if status == "failed" then return waitFailure(context, record, effect, at, reason, opts) end
        if status ~= "completed" then
            updateContext(opts, record, context, effect)
            return true, false, "depositing_work_output"
        end
        local deposited, depositReason = depositOutputItems(record, body, storage, effect,
            context.outputCapacityReservationId, opts)
        if not deposited then
            effect.waitReason, effect.lastReason, effect.updatedAt = depositReason, depositReason, at
            if depositReason == "storage_full" then
                return enterStockpileWait(context, record, body, effect, at, depositReason,
                    storage, dest.storageId, nil, { retryMs = opts.retryMs, onUpdate = opts.onUpdate,
                        markDirty = opts.markDirty, clearDestinationOnWait = true })
            end
            updateContext(opts, record, context, effect)
            markDirty(opts)
            return true, false, depositReason
        end
        Service.ReleaseOutputCapacity(context, PNC.ColonyStorageService)
        context.pendingOutput, context.outputDestination = nil, nil
        context.state, context.phase = "READY", "RECONCILING"
        updateContext(opts, record, context, nil)
        return true, true, "work_output_deposited"
    end
    updateContext(opts, record, context, effect)
    return true, false, "work_output_pending"
end

return Service
