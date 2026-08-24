if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

function H.ColonyId(record)
    local affiliation = record and record.affiliation or {}
    return tostring(affiliation.communityID or affiliation.communityId
        or record and record.communityId or "")
end

function H.BaseFor(record, baseId)
    if baseId and tostring(baseId) ~= "" then
        return PNC.BaseService and PNC.BaseService.Get(baseId) or nil
    end
    local remembered = record and record.runtime
        and record.runtime.homeBaseId
        or record and record.orderSpec
            and record.orderSpec.kind == "colony_home"
            and record.orderSpec.baseId
        or nil
    if remembered and tostring(remembered) ~= "" then
        local base = PNC.BaseService and PNC.BaseService.Get(remembered) or nil
        if base then return base end
    end
    local id = H.ColonyId(record)
    return id ~= "" and PNC.BaseService
        and PNC.BaseService.GetForColony(id) or nil
end

function Service.GetColonyId(record)
    local id = H.ColonyId(record)
    if id ~= "" then return id end
    local base = H.BaseFor(record)
    return base and tostring(base.colonyId or "") or ""
end

function H.HomePoint(record, base)
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

function H.SetAtHome(record, base, point)
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

function H.SetFollowing(record, username, onlineID)
    record.runtime = record.runtime or {}
    record.runtime.homeState = "AWAY"
    record.runtime.homeJourneyId = nil
    local order = {
        kind = PNC.Const.ORDER_FOLLOW,
        ownerUsername = username,
        ownerOnlineID = onlineID,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "follow_player")
    end
    return true, "FOLLOWING_PLAYER"
end

function Service.GetBase(record, baseId)
    return H.BaseFor(record, baseId)
end

function Service.GetHomePoint(record, baseId)
    local base = H.BaseFor(record, baseId)
    local point, reason = H.HomePoint(record, base)
    return point, reason, base
end

return Service

