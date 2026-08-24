if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

function Service.SendHome(record, baseId, reason)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    local point, pointReason, base = Service.GetHomePoint(record, baseId)
    if not point then return false, pointReason end
    if Service.IsAtHome(record, base.id) then
        return H.SetAtHome(record, base, point)
    end
    if Service.IsReturningHome(record, base.id) then
        return true, "RETURNING_HOME", record.travel
    end
    local journey, journeyReason = PNC.Travel.Service.Start(record, {
        destination = { x = point.x, y = point.y, z = point.z },
        routeProvider = "direct",
        speedProfile = "walk",
        ownerMod = "ProjectHoomans",
        ownerRef = "colony_return_home",
        visibility = "all",
        arrivalAction = {
            type = "colony_home", baseId = base.id,
            x = point.x, y = point.y, z = point.z,
            radius = point.radius,
        },
        metadata = {
            purpose = "return_home", baseId = base.id,
            reason = tostring(reason or "duty_required"),
        },
    })
    if not journey then return false, journeyReason end
    record.runtime = record.runtime or {}
    record.runtime.homeState = "RETURNING_HOME"
    record.runtime.homeBaseId = base.id
    record.runtime.homeJourneyId = journey.journeyId
    return true, "RETURNING_HOME", journey
end

function Service.SendToPlayer(record, player, reason)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    if not player then return false, "PLAYER_MISSING" end
    -- Construction, reconstruction, and deconstruction are home chores. A
    -- follow command must not tear the worker out of the job and strand its
    -- progress behind a blocked order. The player can still use the explicit
    -- return-home command, which releases the claim safely and leaves the
    -- durable order resumable.
    if record.runtime and record.runtime.workOrderId then
        return false, "WORK_ORDER_IN_PROGRESS"
    end
    local x = player.getX and tonumber(player:getX()) or nil
    local y = player.getY and tonumber(player:getY()) or nil
    local z = player.getZ and tonumber(player:getZ()) or 0
    if not x or not y then return false, "PLAYER_LOCATION_MISSING" end
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
    local username = player.getUsername and player:getUsername() or nil
    local onlineID = player.getOnlineID and player:getOnlineID() or nil
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id,
            "follow_player_requested")
    end
    if PNC.Travel and PNC.Travel.Service and PNC.Travel.Model
        and PNC.Travel.Model.IsActive(record.travel)
    then
        PNC.Travel.Service.Cancel(record, "follow_player_requested")
    end
    local dx = (tonumber(record.x) or 0) - x
    local dy = (tonumber(record.y) or 0) - y
    if dx * dx + dy * dy <= 100 then
        return H.SetFollowing(record, username, onlineID)
    end
    local journey, journeyReason = PNC.Travel.Service.Start(record, {
        destination = { x = x, y = y, z = z },
        routeProvider = "direct",
        speedProfile = "walk",
        ownerMod = "ProjectHoomans",
        ownerRef = "colony_follow_player",
        visibility = "all",
        arrivalAction = {
            type = "colony_follow_player",
            ownerUsername = username,
            ownerOnlineID = onlineID,
        },
        metadata = {
            purpose = "follow_player",
            reason = tostring(reason or "player_requested"),
            ownerUsername = username,
        },
    })
    if not journey then return false, journeyReason end
    record.runtime = record.runtime or {}
    record.runtime.homeState = "AWAY"
    record.runtime.homeJourneyId = journey.journeyId
    return true, "TRAVELING_TO_PLAYER", journey
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

