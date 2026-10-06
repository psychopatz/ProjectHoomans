if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

function H.CancelActiveTask(record, reason)
    local lease
    local stopped
    local stopReason
    local fishing
    local job
    if not record then return false, "NPC_MISSING" end
    lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(record.id) or nil
    if lease and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelForNPC
    then
        stopped, stopReason = PNC.Tasking.Commands.CancelForNPC(
            record.id, reason or "return_home_command")
        if stopped == false or stopReason == "CANCELLATION_DEFERRED" then
            return false, stopReason or "TASK_CANCELLATION_FAILED"
        end
    end
    -- A persisted fishing job can outlive a missing task lease after a load.
    -- Cancel it through FishingService so its executor cannot reassert the
    -- old order after an explicit player home command.
    fishing = PNC.FishingService
    job = fishing and fishing.GetJob and fishing.GetJob(record.id) or nil
    if job and job.active == true and fishing.CancelJob then
        stopped, stopReason = fishing.CancelJob(
            record.id, reason or "return_home_command")
        if stopped == false then
            return false, stopReason or "FISHING_CANCELLATION_FAILED"
        end
    end
    return true
end

function Service.SendHome(record, baseId, reason, options)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    local allowFollowOverride = type(options) == "table"
        and options.allowFollowOverride == true
    -- Work/fatigue/courier/home reconciliation is not allowed to replace a
    -- player-follow order. An explicit player "go home" command opts into
    -- the replacement; all implicit callers must leave Follow authoritative.
    if Service.IsFollowing and Service.IsFollowing(record)
        and not allowFollowOverride
    then
        return false, "FOLLOWING_PLAYER"
    end
    local point, pointReason, base = Service.GetHomePoint(record, baseId)
    if not point then return false, pointReason end
    local forceDestination = type(options) == "table"
        and (options.forceDestination == true or allowFollowOverride)
    if Service.IsReturningHome(record, base.id) then
        -- A stale colony_home order can outlive the travel journey that was
        -- created to repair it. Without restoring the travel order here,
        -- AtHome keeps owning the behavior tick and freezes the active
        -- return-home journey at its last percentage.
        local travel = record.travel
        local travelKind = PNC.Const and PNC.Const.ORDER_TRAVEL or "travel"
        local current = record.orderSpec
        if not current
            or tostring(current.kind or "") ~= tostring(travelKind)
            or tostring(current.journeyId or "")
                ~= tostring(travel and travel.journeyId or "")
        then
            local travelOrder = {
                kind = travelKind,
                journeyId = travel and travel.journeyId or nil,
            }
            if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
                PNC.OrderSystem.SetOrder(record, travelOrder)
            else
                record.orderSpec = travelOrder
            end
        end
        return true, "RETURNING_HOME", record.travel
    end
    if Service.IsAtHome(record, base.id) and not forceDestination then
        return H.SetAtHome(record, base, point)
    end
    local journey, journeyReason = PNC.Travel.Service.Start(record, {
        destination = { x = point.x, y = point.y, z = point.z },
        arrivalRadius = point.radius,
        routeProvider = "direct",
        speedProfile = "walk",
        ownerMod = "ProjectHoomans",
        ownerRef = "colony_return_home",
        visibility = "all",
        arrivalAction = {
            type = "colony_home", baseId = base.id,
            x = point.x, y = point.y, z = point.z,
            radius = point.radius,
            homeZoneId = point.homeZoneId,
            stockpileNodeId = point.stockpileNodeId,
        },
        metadata = {
            purpose = "return_home", baseId = base.id,
            reason = tostring(reason or "duty_required"),
        },
        allowFollowOverride = allowFollowOverride,
    })
    if not journey then return false, journeyReason end
    record.runtime = record.runtime or {}
    record.runtime.homeBaseId = base.id
    if journey.state == "arrived" then
        record.runtime.homeState = "AT_HOME"
        record.runtime.homeJourneyId = nil
    else
        record.runtime.homeState = "RETURNING_HOME"
        record.runtime.homeJourneyId = journey.journeyId
    end
    return true, "RETURNING_HOME", journey
end

-- Called by the travel service when a return-home journey ends without
-- arriving (unreachable live lane, lost owner). The home duty owns the retry:
-- restore the durable home order so the AtHome behavior ticks again and
-- EnsureHomeAnchor re-issues the journey once the retry cooldown expires.
function Service.OnTravelFailed(record, reason, journey)
    local runtime = record and record.runtime or nil
    local base
    local point
    local order
    if not runtime then return false end
    if Service.IsFollowing and Service.IsFollowing(record) then
        return false, "FOLLOWING_PLAYER"
    end
    runtime.homeState = "RETURN_HOME_FAILED"
    runtime.homeJourneyId = nil
    runtime.homeFailureReason = tostring(reason or "travel_failed")
    runtime.homeRetryAt = (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
        + (tonumber(PNC.Const and PNC.Const.TRAVEL_HOME_RETRY_COOLDOWN_MS)
            or 60000)
    base = H.BaseFor(record, runtime.homeBaseId)
    if not base then return false end
    runtime.homeBaseId = base.id
    point = PNC.HomeDutyService.GetHomePoint(record, base.id)
    if not point then return false end
    order = {
        kind = "colony_home",
        baseId = base.id,
        x = point.x,
        y = point.y,
        z = point.z,
        radius = point.radius,
        homeZoneId = point.homeZoneId,
        stockpileNodeId = point.stockpileNodeId,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "home_state")
    end
    return true
end

function Service.SendToPlayer(record, player, reason)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    if not player then return false, "PLAYER_MISSING" end
    local username = player.getUsername and player:getUsername() or nil
    local onlineID = player.getOnlineID and player:getOnlineID() or nil
    if (username == nil or tostring(username) == "") and onlineID == nil then
        return false, "PLAYER_IDENTITY_MISSING"
    end
    -- Home-bound construction work must not be torn out by follow. Provision
    -- pickups and corpse hauls are interruptible field tasks, so an explicit
    -- follow command cancels either one through its registered cleanup path.
    if record.runtime and record.runtime.workOrderId then
        local work = PNC.WorkService
        local order = work and work.Queries and work.Queries.Get
            and work.Queries.Get(record.runtime.workOrderId) or nil
        local operation = tostring(order and order.operation or "")
        if not order
            or (operation ~= "PROVISION_PICKUP"
                and operation ~= "CORPSE_HAUL")
            or not work.Commands
            or type(work.Commands.Cancel) ~= "function"
        then
            return false, "WORK_ORDER_IN_PROGRESS"
        end
        local cancelled, cancelResult = work.Commands.Cancel(
            order.id, "follow_player_requested")
        if not cancelled then
            return false, cancelResult or "WORK_ORDER_CANCELLATION_FAILED"
        end
        if cancelResult == "CANCELLATION_DEFERRED" then
            return false, "WORK_ORDER_CANCELLING"
        end
    end
    local courier = record.runtime and record.runtime.storageCourier or nil
    if courier and (courier.state == "RETURNING_HOME"
        or courier.state == "DEPOSITING")
    then
        courier.state = "CANCELLED"
        courier.reason = "follow_player_requested"
        courier.updatedAt = PNC.Core.Now()
        courier.revision = math.max(0,
            math.floor(tonumber(courier.revision) or 0)) + 1
    end
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id,
            "follow_player_requested")
    end
    if PNC.Travel and PNC.Travel.Service
        and type(PNC.Travel.Service.Supersede) == "function"
    then
        local superseded, supersedeReason = PNC.Travel.Service.Supersede(
            record, "follow_player_requested")
        if superseded == false and supersedeReason ~= "journey_missing" then
            return false, supersedeReason or "TRAVEL_SUPERSEDE_FAILED"
        end
    elseif PNC.Travel and PNC.Travel.Service and PNC.Travel.Model
        and type(PNC.Travel.Service.Cancel) == "function"
        and PNC.Travel.Model.IsActive(record.travel)
    then
        PNC.Travel.Service.Cancel(record, "follow_player_requested")
    end
    return H.SetFollowing(record, username, onlineID)
end

function Service.Recover(record, baseId)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    local point, reason, base = Service.GetHomePoint(record, baseId)
    if not point then return false, reason end
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id, "colonist_recovered")
    end
    if PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Model and PNC.Travel.Model.IsActive(record.travel)
    then
        PNC.Travel.Service.Cancel(record, "colonist_recovered")
    end
    if record.presenceState == PNC.Const.PRESENCE_LIVE
        and PNC.Presence and PNC.Presence.Abstract
    then
        PNC.Presence.Abstract(record, "colonist_recovery")
    end
    record.x, record.y, record.z = point.x, point.y, point.z
    record.runtime = record.runtime or {}
    record.runtime.forcePresenceCheck = true
    record.runtime.homeRecoveredAt = PNC.Core.Now()
    H.SetAtHome(record, base, point)
    if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
        PNC.SpatialIndex.UpdateNPC(record)
    end
    if PNC.Presence and PNC.Presence.Reconcile then
        PNC.Presence.Reconcile(record)
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "colonist_recovered")
    end
    return true, "COLONIST_RECOVERED", {
        npcID = record.id, baseId = base.id,
        x = record.x, y = record.y, z = record.z,
        stockpileNodeId = point.stockpileNodeId,
    }
end

return Service
