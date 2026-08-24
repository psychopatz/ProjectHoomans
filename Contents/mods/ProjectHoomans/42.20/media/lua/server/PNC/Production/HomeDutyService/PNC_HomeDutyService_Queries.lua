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

return Service

