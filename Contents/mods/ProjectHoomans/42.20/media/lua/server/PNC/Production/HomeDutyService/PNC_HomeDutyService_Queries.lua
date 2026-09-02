if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

function Service.IsAtHome(record, baseId)
    local base = H.BaseFor(record, baseId)
    local zone = base and Zones.get(base.baseZoneId) or nil
    if not zone or not zone.geometry or not record then return false end
    return GridRegion.containsXY(
        zone.geometry,
        math.floor(tonumber(record.x) or 0),
        math.floor(tonumber(record.y) or 0)
    )
end

function Service.IsFollowing(record)
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

function Service.IsCamped(record)
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_CAMP or "camp")
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
    local base = H.BaseFor(record)
    local camped = Service.IsCamped(record)
    if camped then
        return {
            state = "AT_CAMP",
            baseId = base and base.id or nil,
            returning = false,
            atHome = false,
            atCamp = true,
        }
    end
    if not base then return { state = "NO_BASE", atCamp = false } end
    local returning = Service.IsReturningHome(record, base.id)
    local workState
    if PNC.WorkService and PNC.WorkService.Internal
        and PNC.WorkService.Internal.workLocationState
    then
        local orderId = record and record.runtime
            and record.runtime.workOrderId or nil
        local order = orderId and PNC.WorkRepository
            and PNC.WorkRepository.Get(orderId) or nil
        workState = PNC.WorkService.Internal.workLocationState(record, order)
    end
    local atHome = Service.IsAtHome(record, base.id)
    return {
        state = returning and "RETURNING_HOME"
            or workState == "AWAY_FOR_WORK" and "AWAY_FOR_WORK"
            or atHome and "AT_HOME" or "AWAY",
        baseId = base.id,
        returning = returning,
        atHome = atHome,
        atCamp = false,
        workLocation = workState,
    }
end

return Service
