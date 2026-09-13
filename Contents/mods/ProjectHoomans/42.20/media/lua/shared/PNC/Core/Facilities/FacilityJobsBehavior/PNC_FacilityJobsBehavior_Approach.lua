PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal

function Internal.ResetPath(record, zombie, reason)
    if not PNC.PathService or not PNC.PathService.Reset then return end
    if PNC.PathService.Commands and PNC.PathService.Commands.Reset then
        PNC.PathService.Commands.Reset(record, zombie, reason)
    else
        PNC.PathService.Reset(zombie, record)
    end
end

function Internal.BodyDistance(zombie, x, y)
    if zombie and zombie.getX and zombie.getY then
        return PNC.Core.Distance(zombie:getX(), zombie:getY(), x, y)
    end
    return nil
end

local function retryApproach(record, zombie, order, runtime, options)
    local forceRetry = options.forceRetry
        and options.forceRetry(runtime) == true
    if options.guard and not options.guard(runtime) then return true end
    local lane = record.runtime and record.runtime.pathing or nil
    if not forceRetry
        and (not lane
            or (lane.phase ~= "blocked" and lane.ownerMode ~= "blocked"))
    then
        return true
    end
    if forceRetry and options.clearRetry then options.clearRetry(runtime) end
    local candidates = runtime.approachCandidates or {}
    runtime.failedApproaches = runtime.failedApproaches or {}
    local current = math.max(1, tonumber(runtime.approachIndex) or 1)
    local active = candidates[current]
    if options.markActive then
        options.markActive(runtime, active, current)
    end
    local nextIndex = current + 1
    local candidate
    while candidates[nextIndex] do
        candidate = candidates[nextIndex]
        if options.usable(candidate, runtime.failedApproaches, nextIndex)
            and tonumber(candidate.x) and tonumber(candidate.y)
            and tonumber(candidate.z)
        then
            break
        end
        nextIndex = nextIndex + 1
        candidate = nil
    end
    if not candidate then
        runtime.failedReason = options.failureReason
        if options.onExhausted then options.onExhausted(runtime) end
        return false
    end
    runtime.approachIndex = nextIndex
    order.x, order.y, order.z = candidate.x, candidate.y, candidate.z
    options.apply(order, runtime, candidate)
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = nil
    runtime.phase = "REPATHING"
    Internal.ResetPath(record, zombie, options.resetReason)
    return true
end

function Internal.RetrySeatApproach(record, zombie, order, runtime)
    return retryApproach(record, zombie, order, runtime, {
        guard = function(activity) return activity and activity.seating == true end,
        usable = function(candidate, failedApproaches, index)
            return Internal.SeatSpotUsable(candidate, failedApproaches, index)
        end,
        markActive = function(activity, active, current)
            local activeKey = active and tostring(active.approachKey or "") or ""
            if activeKey ~= "" then
                activity.failedApproaches[activeKey] = true
            else
                activity.failedApproaches["index:" .. tostring(current)] = true
            end
        end,
        failureReason = "SEAT_APPROACH_UNREACHABLE",
        onExhausted = function(activity)
            activity.seatRouteStatus = "BLOCKED"
        end,
        apply = function(target, activity, candidate)
            target.x, target.y, target.z = candidate.x, candidate.y, candidate.z
            target.seatAnchorX = candidate.seatAnchorX or candidate.x
            target.seatAnchorY = candidate.seatAnchorY or candidate.y
            target.seatAnchorZ = candidate.seatAnchorZ or candidate.z
            target.seatDirection = candidate.seatDirection or candidate.direction
            target.seatSide = candidate.seatSide or candidate.side
            target.approachKey = candidate.approachKey
            target.validSpot = candidate.validSpot ~= false
                and candidate.approachValid ~= false
            target.validationState = candidate.validationState or "VALID"
            target.rejectionReason = candidate.rejectionReason
            target.routeStatus = "RETRYING"
            activity.seatAnchor = {
                x = tonumber(target.seatAnchorX),
                y = tonumber(target.seatAnchorY),
                z = tonumber(target.seatAnchorZ),
            }
            activity.seatDirection = tostring(target.seatDirection or "")
            activity.seatSide = tostring(target.seatSide or "")
            activity.approachKey = tostring(target.approachKey or "")
            activity.validSpot = target.validSpot
            activity.seatValidation = tostring(target.validationState or "")
            activity.seatRejectionReason = tostring(
                target.rejectionReason or "")
            activity.seatRouteStatus = "RETRYING"
            activity.arrivalSettled = false
            activity.positioned = false
            activity.seatEntered = false
            activity.phase = "REPATHING"
        end,
        resetReason = "seat_approach_retry",
    })
end

function Internal.RetryWaterApproach(record, zombie, order, runtime)
    return retryApproach(record, zombie, order, runtime, {
        guard = function(activity)
            return activity.resourceKind == "world_water"
                or activity.resourceKind == "water_refill"
        end,
        forceRetry = function(activity)
            return activity.worldWaterApproachRetry == true
                or activity.waterRefillApproachRetry == true
        end,
        clearRetry = function(activity)
            activity.worldWaterApproachRetry = nil
            activity.waterRefillApproachRetry = nil
        end,
        usable = function(candidate, failedApproaches)
            return not failedApproaches[candidate.approachKey]
        end,
        markActive = function(activity, active)
            if active and active.approachKey then
                activity.failedApproaches[active.approachKey] = true
            end
        end,
        failureReason = "WATER_APPROACH_UNREACHABLE",
        apply = function(target, _, candidate)
            target.interactionFacing = candidate.interactionFacing or ""
        end,
        resetReason = "water_approach_retry",
    })
end

return Internal
