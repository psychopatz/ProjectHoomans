if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.HomeDutyService = PNC.HomeDutyService or {}

local Service = PNC.HomeDutyService
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function colonyId(record)
    local affiliation = record and record.affiliation or {}
    return tostring(affiliation.communityID or affiliation.communityId
        or record and record.communityId or "")
end

local function baseFor(record, baseId)
    if baseId and tostring(baseId) ~= "" then
        return PNC.BaseService and PNC.BaseService.Get(baseId) or nil
    end
    local id = colonyId(record)
    return id ~= "" and PNC.BaseService
        and PNC.BaseService.GetForColony(id) or nil
end

local function homePoint(record, base)
    if not base then return nil, "BASE_NOT_FOUND" end
    local node = PNC.StockpileAccessService
        and PNC.StockpileAccessService.FindNearest
        and PNC.StockpileAccessService.FindNearest(
            base.id,
            tonumber(record and record.x) or 0,
            tonumber(record and record.y) or 0,
            tonumber(record and record.z) or 0
        ) or nil
    if node then
        return {
            x = tonumber(node.x), y = tonumber(node.y),
            z = tonumber(node.z) or 0,
            radius = math.max(1, tonumber(node.radius) or 2),
            stockpileNodeId = node.id,
        }
    end
    local snapshot = PNC.BaseService and PNC.BaseService.BuildSnapshot
        and PNC.BaseService.BuildSnapshot(base) or nil
    local bounds = snapshot and snapshot.geometry
        and snapshot.geometry.bounds or nil
    if not bounds then return nil, "HOME_LOCATION_MISSING" end
    return {
        x = math.floor(((tonumber(bounds.minX) or 0)
            + (tonumber(bounds.maxX) or 0)) / 2),
        y = math.floor(((tonumber(bounds.minY) or 0)
            + (tonumber(bounds.maxY) or 0)) / 2),
        z = tonumber(bounds.z) or tonumber(record and record.z) or 0,
        radius = 3,
    }
end

local function setAtHome(record, base, point)
    record.runtime = record.runtime or {}
    record.runtime.homeState = "AT_HOME"
    record.runtime.homeBaseId = base.id
    record.runtime.homeJourneyId = nil
    local order = {
        kind = "colony_home", baseId = base.id,
        x = point.x, y = point.y, z = point.z,
        radius = point.radius,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "home_state")
    end
    return true, "AT_HOME"
end

function Service.GetBase(record, baseId)
    return baseFor(record, baseId)
end

function Service.GetHomePoint(record, baseId)
    local base = baseFor(record, baseId)
    local point, reason = homePoint(record, base)
    return point, reason, base
end

function Service.IsAtHome(record, baseId)
    local base = baseFor(record, baseId)
    local zone = base and Zones.get(base.baseZoneId) or nil
    if not zone or not zone.geometry or not record then return false end
    return GridRegion.containsXY(
        zone.geometry,
        math.floor(tonumber(record.x) or 0),
        math.floor(tonumber(record.y) or 0)
    )
end

function Service.IsReturningHome(record, baseId)
    local travel = record and record.travel or nil
    local metadata = travel and travel.metadata or nil
    return travel and (travel.state == "en_route" or travel.state == "waiting")
        and metadata and metadata.purpose == "return_home"
        and (not baseId or tostring(metadata.baseId or "") == tostring(baseId))
        or false
end

function Service.BuildState(record)
    local base = baseFor(record)
    if not base then return { state = "NO_BASE" } end
    local returning = Service.IsReturningHome(record, base.id)
    return {
        state = returning and "RETURNING_HOME"
            or Service.IsAtHome(record, base.id) and "AT_HOME" or "AWAY",
        baseId = base.id,
        returning = returning,
        atHome = Service.IsAtHome(record, base.id),
    }
end

function Service.SendHome(record, baseId, reason)
    if not record or record.alive == false then return false, "NPC_MISSING" end
    local point, pointReason, base = Service.GetHomePoint(record, baseId)
    if not point then return false, pointReason end
    if Service.IsAtHome(record, base.id) then
        return setAtHome(record, base, point)
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
    setAtHome(record, base, point)
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

if PNC.Travel and PNC.Travel.Arrivals then
    PNC.Travel.Arrivals.RegisterHandler("colony_home",
        function(record, _, action)
            local point, reason, base = Service.GetHomePoint(
                record, action and action.baseId)
            if not point then return false, reason end
            return setAtHome(record, base, point)
        end)
end

return Service
