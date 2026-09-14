local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Const = PNC.Const or {}

Internal.SCAN_MS = tonumber(Const.THREAT_GUARD_SCAN_MS) or 350
Internal.VALIDATE_MS = tonumber(Const.THREAT_GUARD_VALIDATE_MS) or 250
Internal.RELEASE_GRACE_MS = tonumber(
    Const.THREAT_GUARD_RELEASE_GRACE_MS) or 900

local PASSIVE_ORDERS = {
    [tostring(Const.ORDER_CAMP or "camp")] = true,
    ["colony_home"] = true,
    [tostring(Const.ORDER_GUARD or "guard")] = true,
    [tostring(Const.ORDER_PATROL or "patrol")] = true,
    ["facility_activity"] = true,
    ["production_work"] = true,
    [tostring(Const.ORDER_LUMBER or "lumber")] = true,
    [tostring(Const.ORDER_FISHING or "fishing")] = true,
    [tostring(Const.ORDER_SCAVENGE or "scavenge")] = true,
}

local function firstNumber(...)
    local values = { ... }
    local index
    for index = 1, #values do
        if tonumber(values[index]) ~= nil then
            return tonumber(values[index])
        end
    end
    return nil
end

local function orderKind(record)
    return tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
end

local function ownerToken(record, source, ownerKind)
    local runtime = record and record.runtime or {}
    local activity = runtime.facilityActivity
    local order = record and record.orderSpec or {}
    local token = source .. "|" .. ownerKind
    if activity then
        token = token .. "|" .. tostring(activity.taskLeaseId or "")
            .. "|" .. tostring(activity.startedAt or activity.createdAt or "")
            .. "|" .. tostring(activity.capability or order.capability or "")
    elseif runtime.roamingSeat then
        token = token .. "|" .. tostring(runtime.roamingSeat.startedAt or "")
    end
    return token
end

local function context(source, ownerKind, x, y, z, radius, presentation, token)
    return {
        source = tostring(source or ""),
        ownerKind = tostring(ownerKind or ""),
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        radius = math.max(0.5, tonumber(radius) or 6),
        presentation = presentation,
        token = token,
    }
end

local function facilityContext(record, activity, order)
    local previous = activity.previousOrder or {}
    local previousKind = tostring(previous.kind or "")
    local ownerKind = previousKind ~= "" and previousKind
        or tostring(order.kind or "facility_activity")
    local x = firstNumber(
        previous.x,
        activity.campX,
        activity.x,
        activity.target and activity.target.x,
        activity.seatAnchor and activity.seatAnchor.x,
        order.x,
        record.x
    )
    local y = firstNumber(
        previous.y,
        activity.campY,
        activity.y,
        activity.target and activity.target.y,
        activity.seatAnchor and activity.seatAnchor.y,
        order.y,
        record.y
    )
    local z = firstNumber(
        previous.z,
        activity.campZ,
        activity.z,
        activity.target and activity.target.z,
        activity.seatAnchor and activity.seatAnchor.z,
        order.z,
        record.z
    )
    local radius
    if ownerKind == tostring(Const.ORDER_CAMP or "camp") then
        radius = firstNumber(
            activity.campRadius,
            previous.radius,
            Const.CAMP_ENGAGE_RADIUS,
            Const.CAMP_RADIUS
        )
    else
        radius = firstNumber(
            previous.radius,
            activity.threatRadius,
            order.threatRadius,
            Const.GUARD_ENGAGE_RADIUS,
            Const.TARGET_IMMEDIATE_THREAT_RADIUS
        )
    end
    return context(
        "facility_activity",
        ownerKind,
        x,
        y,
        z,
        radius,
        tostring(activity.capability or "") == "sleep"
            and "sleep"
            or activity.seating == true and "seat" or nil,
        ownerToken(record, "facility_activity", ownerKind)
    )
end

local function workContext(record, order, kind)
    local runtime = record.runtime or {}
    local lumber = runtime.lumber or {}
    local fishing = runtime.fishing or {}
    local x = firstNumber(
        order.x,
        order.standX,
        lumber.approachX,
        fishing.standX,
        record.x
    )
    local y = firstNumber(
        order.y,
        order.standY,
        lumber.approachY,
        fishing.standY,
        record.y
    )
    local z = firstNumber(
        order.z,
        order.standZ,
        lumber.approachZ,
        fishing.standZ,
        record.z
    )
    local radius = firstNumber(
        order.threatRadius,
        kind == tostring(Const.ORDER_LUMBER or "lumber")
            and Const.LUMBER_DEFAULT_RADIUS or nil,
        kind == tostring(Const.ORDER_FISHING or "fishing")
            and Const.FISHING_DEFAULT_RADIUS or nil,
        kind == tostring(Const.ORDER_SCAVENGE or "scavenge")
            and Const.SCAVENGE_DEFAULT_RADIUS or nil,
        6
    )
    return context(
        kind,
        kind,
        x,
        y,
        z,
        radius,
        nil,
        ownerToken(record, kind, kind)
    )
end

local function travelConversationContext(record)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local journey = record and record.travel or nil
    local order = record and record.orderSpec or nil
    local journeyId
    local token
    if not lease or lease.travelHold ~= true or not journey
        or tostring(order and order.kind or "") ~= tostring(
            Const.ORDER_TRAVEL or "travel")
    then
        return nil
    end
    journeyId = tostring(journey.journeyId or order.journeyId or "")
    token = "conversation|travel|"
        .. tostring(lease.token or "") .. "|" .. journeyId
    return context(
        "conversation",
        "travel",
        record.x,
        record.y,
        record.z,
        firstNumber(
            lease.dangerRadius,
            Const.TARGET_IMMEDIATE_THREAT_RADIUS,
            6
        ),
        "conversation",
        token
    )
end

function Internal.ResolveContext(record)
    local runtime = record and record.runtime or nil
    local order = record and record.orderSpec or {}
    local kind = orderKind(record)
    local activity = runtime and runtime.facilityActivity or nil
    local roamingSeat = runtime and runtime.roamingSeat or nil
    local point
    local radius
    if not record or record.alive == false then return nil end
    if activity then
        if activity.stopRequested == true
            or activity.finishing == true
            or activity.sleepWakePending == true
        then
            return nil
        end
        return facilityContext(record, activity, order)
    end
    point = travelConversationContext(record)
    if point then return point end
    if roamingSeat and kind == tostring(Const.ORDER_ROAM or "roam") then
        return context(
            "roaming_seat",
            kind,
            firstNumber(roamingSeat.x, record.x),
            firstNumber(roamingSeat.y, record.y),
            firstNumber(roamingSeat.z, record.z),
            firstNumber(order.targetRadius, Const.ROAM_TARGET_RADIUS),
            "seat",
            ownerToken(record, "roaming_seat", kind)
        )
    end
    if not PASSIVE_ORDERS[kind] then return nil end
    if kind == tostring(Const.ORDER_CAMP or "camp") then
        return context(
            kind,
            kind,
            firstNumber(order.x, record.anchorX, record.x),
            firstNumber(order.y, record.anchorY, record.y),
            firstNumber(order.z, record.anchorZ, record.z),
            firstNumber(order.threatRadius, Const.CAMP_ENGAGE_RADIUS,
                order.radius, Const.CAMP_RADIUS),
            nil,
            ownerToken(record, kind, kind)
        )
    end
    if kind == "colony_home"
        or kind == tostring(Const.ORDER_GUARD or "guard")
    then
        return context(
            kind,
            kind,
            firstNumber(order.x, record.anchorX, record.x),
            firstNumber(order.y, record.anchorY, record.y),
            firstNumber(order.z, record.anchorZ, record.z),
            firstNumber(order.threatRadius, order.radius,
                Const.GUARD_ENGAGE_RADIUS, Const.GUARD_RADIUS),
            nil,
            ownerToken(record, kind, kind)
        )
    end
    if kind == tostring(Const.ORDER_PATROL or "patrol") then
        point = order.points and order.points[record.patrolIndex or 1] or nil
        radius = firstNumber(order.threatRadius, order.radius,
            Const.GUARD_ENGAGE_RADIUS, Const.GUARD_RADIUS)
        return context(
            kind,
            kind,
            firstNumber(point and point.x, record.x),
            firstNumber(point and point.y, record.y),
            firstNumber(point and point.z, record.z),
            radius,
            nil,
            ownerToken(record, kind, kind)
        )
    end
    return workContext(record, order, kind)
end

return Internal
