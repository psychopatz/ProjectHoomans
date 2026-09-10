-- Shared, engine-free presentation helpers for mobile-group diagnostics.

PNC = PNC or {}
PNC.MobileGroupDebugModel = PNC.MobileGroupDebugModel or {}

local Model = PNC.MobileGroupDebugModel

function Model.State(mobile, group)
    if type(mobile) ~= "table" or mobile.active ~= true then
        return "not_mobile"
    end
    if mobile.debugState then return tostring(mobile.debugState) end
    if mobile.activity == "traveling_to_settlement" then
        local traveling = group and group.state == "TRAVELING"
            or mobile.groupState == "TRAVELING"
        return traveling and "en_route" or "arrival_pending"
    end
    if mobile.ambient and mobile.ambient.objective == "road" then
        return "road_roaming"
    end
    return "street_roaming"
end

function Model.StateText(mobile, group)
    local state = Model.State(mobile, group)
    local labels = {
        road_roaming = "ROAD ROAMING",
        street_roaming = "STREET ROAMING",
        en_route = "EN ROUTE",
        arrival_pending = "ARRIVAL PENDING",
        not_mobile = "NOT MOBILE",
    }
    return labels[state] or string.upper(state)
end

function Model.Target(mobile, group)
    if mobile and mobile.destination then return mobile.destination end
    if mobile and mobile.travel and mobile.travel.destination then
        return mobile.travel.destination
    end
    if mobile and mobile.ambient and mobile.ambient.target then
        return mobile.ambient.target
    end
    if mobile and mobile.controlMode == "strategic" then
        return mobile.strategicTarget
    end
    if group and group.targetLocation then return group.targetLocation end
    return mobile and mobile.ambient and mobile.ambient.target or nil
end

function Model.TargetText(mobile, group)
    local target = Model.Target(mobile, group)
    if not target then return "none" end
    return tostring(target.kind or "location") .. " / "
        .. tostring(target.baseID or target.siteID
            or target.communityID or target.locationID or "anonymous")
        .. " @ " .. string.format("%.0f, %.0f, %.0f",
            tonumber(target.x) or 0,
            tonumber(target.y) or 0,
            tonumber(target.z) or 0)
end

function Model.Presence(mobile, group)
    if mobile and mobile.presence then return mobile.presence end
    if group and group.mobile and group.mobile.presence then
        return group.mobile.presence
    end
    if group and group.simulation and group.simulation.lod then
        return group.simulation.lod == "ACTIVE" and "live" or "abstract"
    end
    return "unknown"
end

function Model.Progress(mobile, group, now)
    local travel = mobile and mobile.travel or nil
    local started = tonumber(travel and travel.startedAt)
    local ends = tonumber(group and group.stateEndsAt)
    now = tonumber(now)
    if not started or not ends or not now or ends <= started then
        return nil
    end
    return math.max(0, math.min(1, (now - started) / (ends - started)))
end

return Model
