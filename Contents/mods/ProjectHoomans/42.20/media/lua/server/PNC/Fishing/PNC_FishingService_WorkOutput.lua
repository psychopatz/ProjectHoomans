-- Fishing WorkToilRunner live approach and WorkOutputService stockpile catch routing.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local H = Service.Internal

local function rejectOutput(job, zone, record, body, spec, required, reason, finish)
    if Service.FishingDiagnostics and Service.FishingDiagnostics.RecordAttempt then
        Service.FishingDiagnostics.RecordAttempt(record, job, body, job.lastRoll, {
            reason = "output_rejected",
            itemType = spec and spec.type or nil,
            output = "rejected",
            outputReason = reason,
        })
    end
    job.lastFailureReason = reason
    job.workPoints = (tonumber(job.workPoints) or 0) + required
    job.attemptIndex = math.max(0, (tonumber(job.attemptIndex) or 1) - 1)
    job.state, job.phase = "WAITING", "WAITING_FOR_OUTPUT"
    job.lastReason = reason
    H.UpdateFishingRuntime(record, job, zone, job.phase)
    H.MarkDirty()
    return false, finish(true, false, reason, { event = "output_wait" })
end

---Returns true when colony storage can receive fishing outputs via WorkOutputService.
function H.CanBypassInventoryGate(record)
    if not PNC.WorkOutputService then return false end
    if PNC.ProductionContext and type(PNC.ProductionContext.ForWorker) == "function" then
        local resolved = PNC.ProductionContext.ForWorker(record)
        if resolved and resolved.storage then return true end
    end
    local repo = PNC.ColonyStorageRepository
    if repo and type(repo.ListForColony) == "function" and record and record.affiliation then
        local cid = record.affiliation.communityID or record.affiliation.communityId
        local list = cid and repo.ListForColony(cid) or nil
        if type(list) == "table" and #list > 0 then return true end
    end
    return false
end

---Begins or ticks live stockpile hauling for caught fish in WorkOutputService.
function H.TickPendingOutputDelivery(live, job, zone, record, body, at, finish, isTiredResult, trigger)
    if not live or not job or not job.pendingOutput
        or tostring(job.pendingOutput.state or "") == "APPLIED"
        or not PNC.WorkOutputService
        or type(PNC.WorkOutputService.TickLiveDelivery) ~= "function"
    then
        return nil
    end
    if trigger and not job.pendingOutput.delivering then
        if #(job.pendingOutput.items or {}) < 1 or not H.CanBypassInventoryGate(record) then
            return nil
        end
        job.pendingOutput.delivering = true
        job.state, job.phase = "TRAVELING", "OUTPUT_DESTINATION_APPROACH"
        job.lastReason = "fishing_output_haul"
    end
    if job.pendingOutput.delivering ~= true then return nil end
    local ok, complete, reason = PNC.WorkOutputService.TickLiveDelivery(
        job, record, body, job.pendingOutput, at, {
            markDirty = H.MarkDirty,
            moveReason = "fishing_stockpile",
            depositSceneId = "work.deposit",
            fallbackToInventory = false,
        })
    if complete then
        job.pendingOutput = nil
        if isTiredResult then return true, finish(false, false, "fishing_npc_tired") end
        job.state, job.phase = "READY", "TRAVEL"
        job.lastReason = "fishing_output_delivered"
        job.lastProgressAt = at
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        return true, finish(true, false, job.lastReason, { event = "output_delivered" })
    end
    H.UpdateFishingRuntime(record, job, zone, job.phase)
    return true, finish(ok, false, reason or job.phase, { event = "output_delivery" })
end

---Observes live travel to the fishing spot via WorkToilRunner when loaded.
function H.ObserveLiveTravel(job, zone, record, body, at, finish, distanceToSpot)
    if not PNC.WorkToilRunner or type(PNC.WorkToilRunner.ObserveLiveApproach) ~= "function" then
        return nil
    end
    local distance = distanceToSpot(record, body, job.spot)
    local targetPos = { x = job.spot.standX, y = job.spot.standY, z = job.spot.z or zone.z or 0 }
    local status = PNC.WorkToilRunner.ObserveLiveApproach(
        record, body, "fishing_spot:" .. tostring(job.spotId or ""), targetPos, at, {
            watchSlot = "fishing",
            issueMove = false,
            haltOnArrival = false,
            isArrived = function(r, b) return Service.IsNearby(r, zone, nil, job.spot, b) end,
        })
    if status == "arrived" then return "arrived" end
    if status == "stalled" then
        local failedSpot = tostring(job.spotId or "")
        job.failedSpots = job.failedSpots or {}
        job.failedSpots[failedSpot] = true
        if H.ReleaseFishingSpot then H.ReleaseFishingSpot(job, zone) end
        local replacement = H.ReserveFishingSpot(zone, job, record)
        if replacement and tostring(replacement.id) ~= failedSpot then
            job.state, job.phase = "READY", "TRAVEL"
            job.lastReason, job.spotRetryAt, job.travel = "fishing_spot_rerouted", nil, nil
            job.lastProgressAt = at
            H.UpdateFishingRuntime(record, job, zone, job.phase)
            H.MarkDirty()
            return "handled", finish(true, false, job.lastReason, {
                event = "travel_reroute", distance = distance,
            })
        end
        job.state, job.phase = "WAITING", "WAITING_FOR_SPOT"
        job.lastReason, job.lastFailureReason = "fishing_spot_unreachable", "fishing_spot_unreachable"
        job.spotRetryAt = at + Service.SPOT_RETRY_COOLDOWN_MS
        job.lastProgressAt = at
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        return "handled", finish(true, false, job.lastReason, {
            event = "travel_stalled", distance = distance,
        })
    end
    job.state, job.phase = "READY", "TRAVEL"
    job.lastReason, job.lastProgressAt = "traveling", at
    H.UpdateFishingRuntime(record, job, zone, job.phase)
    H.MarkDirty()
    return "handled", finish(true, false, "traveling", {
        event = "travel", toolID = job.activityItemID,
        tool = job.activityItemFullType,
        recordPrimary = job.recordPrimary,
        nativePrimary = job.nativePrimary,
        distance = distance,
    })
end

---Routes a caught fish through WorkOutputService (abstract flush or live inventory capture).
function H.CommitCatchOutput(live, job, zone, record, body, spec, required, finish, canAccept, addCatch)
    if not live and PNC.WorkOutputService
        and type(PNC.WorkOutputService.FlushAbstractDelivery) == "function"
    then
        if not H.CanBypassInventoryGate(record) and not canAccept(record, spec) then
            return rejectOutput(job, zone, record, body, spec, required,
                "fishing_inventory_full", finish)
        end
        local effect = PNC.WorkOutputService.EnsureOutputEffect(job, "FISHING", {})
        local flushed, flushReason = PNC.WorkOutputService.FlushAbstractDelivery(
            job, record, effect, { { fullType = spec.type, quantity = 1 } }, {
                deliveryTarget = "AUTO", fallbackToInventory = true,
                activityTag = "fishing", reason = "fishing_catch", markDirty = H.MarkDirty,
            })
        if not flushed then
            return rejectOutput(job, zone, record, body, spec, required,
                flushReason or "fishing_inventory_full", finish)
        end
        return true, nil
    end
    if live and PNC.WorkOutputService
        and type(PNC.WorkOutputService.CaptureInventoryOutput) == "function"
    then
        if not canAccept(record, spec) then
            if job.pendingOutput and #(job.pendingOutput.items or {}) > 0
                and H.CanBypassInventoryGate(record)
            then
                job.workPoints = (tonumber(job.workPoints) or 0) + required
                job.attemptIndex = math.max(0, (tonumber(job.attemptIndex) or 1) - 1)
                job.pendingOutput.delivering = true
                job.state, job.phase = "TRAVELING", "OUTPUT_DESTINATION_APPROACH"
                job.lastReason = "fishing_output_haul"
                H.UpdateFishingRuntime(record, job, zone, job.phase)
                H.MarkDirty()
                return false, finish(true, false, "fishing_output_haul", { event = "output_haul" })
            end
            return rejectOutput(job, zone, record, body, spec, required,
                "fishing_inventory_full", finish)
        end
        local effect = job.pendingOutput or PNC.WorkOutputService.EnsureOutputEffect(job, "FISHING", {})
        local ok, resOrReason = PNC.WorkOutputService.CaptureInventoryOutput(
            effect, { { fullType = spec.type, quantity = 1 } }, {
                record = record, addToInventory = true, collected = true,
                reason = "fishing_catch", phase = "CARRYING", markDirty = H.MarkDirty,
            })
        if not ok then
            return rejectOutput(job, zone, record, body, spec, required,
                tostring(resOrReason or "fishing_inventory_full"), finish)
        end
        job.pendingOutput = effect
        return true, nil
    end
    if not canAccept(record, spec) then
        return rejectOutput(job, zone, record, body, spec, required,
            "fishing_inventory_full", finish)
    end
    local added, addReason = addCatch(record, spec)
    if not added then
        return rejectOutput(job, zone, record, body, spec, required,
            addReason or "fishing_inventory_full", finish)
    end
    return true, nil
end

return Service
