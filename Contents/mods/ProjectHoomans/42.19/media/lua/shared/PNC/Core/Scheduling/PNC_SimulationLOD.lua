-- Central simulation level-of-detail policy. This module decides cadence;
-- gameplay modules remain unaware of population-scale scheduling concerns.

PNC = PNC or {}
PNC.SimulationLOD = PNC.SimulationLOD or {}

local LOD = PNC.SimulationLOD
local Const = PNC.Const

local function isVehiclePassenger(record)
    return record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
end

local function isMoving(record)
    local path = record.runtime and record.runtime.pathing or nil
    local intent = record.runtime and record.runtime.moveIntent or nil
    return (path and (path.phase == "requested" or path.phase == "active"))
        or (intent and intent.kind == "move")
        or false
end

local function isTraveling(record)
    return PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.IsActive
        and PNC.Travel.Model.IsActive(record and record.travel)
        or false
end

local function isFollowingOwner(record)
    local order = record and record.orderSpec or {}
    return tostring(order.kind or "") == tostring(
        Const.ORDER_FOLLOW or "follow"
    )
end

local function isAbstractDormant(record)
    local order = record.orderSpec or {}
    local health = record.health or {}
    local kind = tostring(order.kind or "")
    local targetX
    local targetY
    local dx
    local dy
    if record.runtime and record.runtime.target then return false end
    if health.state == "incapacitated"
        or (tonumber(health.current) or 100) < (tonumber(health.max) or 100)
    then
        return false
    end
    if kind == "" then return true end
    if kind ~= tostring(Const.ORDER_GUARD or "guard") then return false end
    targetX = tonumber(order.x) or tonumber(record.anchorX) or record.x
    targetY = tonumber(order.y) or tonumber(record.anchorY) or record.y
    dx = (tonumber(targetX) or 0) - (tonumber(record.x) or 0)
    dy = (tonumber(targetY) or 0) - (tonumber(record.y) or 0)
    return (dx * dx) + (dy * dy) <= 1
end

function LOD.Resolve(record)
    local runtime = record.runtime or {}
    local distSq = tonumber(runtime.nearestPlayerDistSq)
    local nearDistance = tonumber(Const.ABSTRACT_NEAR_DISTANCE) or 80
    if runtime.forcePresenceCheck == true then
        return "presence_wake"
    end
    if isVehiclePassenger(record) then return "vehicle" end
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        if runtime.forceLive == true
            or (distSq and distSq <= nearDistance * nearDistance)
        then
            return "abstract_near"
        end
        if record.runtime and record.runtime.target then
            return "abstract_active"
        end
        if isTraveling(record) then
            return "abstract_travel"
        end
        if isAbstractDormant(record) then
            return "abstract_dormant"
        end
        return "abstract_far"
    end
    if record.runtime and record.runtime.attackAction then return "combat_action" end
    if record.runtime and record.runtime.target then return "combat" end
    if record.health and record.health.state == "incapacitated" then
        return "incapacitated"
    end
    -- A live follower is never truly idle: its goal is another moving actor.
    -- Keeping this tier hot removes the one-second wake-up delay without
    -- increasing cadence for unrelated stationary NPCs.
    if isFollowingOwner(record) then return "follow_owner" end
    if isMoving(record) then return "moving" end
    return "live_idle"
end

function LOD.GetCadence(record)
    local tier = LOD.Resolve(record)
    if tier == "presence_wake" then return 50 end
    if tier == "vehicle" then
        return math.min(
            tonumber(Const.FOLLOW_VEHICLE_TICK_MS) or 100,
            tonumber(Const.TICK_LIVE_WARM_MS) or 250
        )
    end
    if tier == "combat_action" then return 50 end
    if tier == "combat" then
        return math.min(tonumber(Const.TICK_LIVE_HOT_MS) or 100, 75)
    end
    if tier == "follow_owner" then
        return tonumber(Const.FOLLOW_TICK_INTERVAL_MS) or 100
    end
    if tier == "moving" or tier == "incapacitated" then
        return math.min(tonumber(Const.TICK_LIVE_WARM_MS) or 250, 100)
    end
    if tier == "abstract_near" or tier == "abstract_active"
        or tier == "abstract_travel"
    then
        return tonumber(Const.TICK_ABSTRACT_MS) or 3000
    end
    if tier == "abstract_far" then
        return tonumber(Const.TICK_ABSTRACT_FAR_MS) or 15000
    end
    if tier == "abstract_dormant" then
        return tonumber(Const.TICK_ABSTRACT_DORMANT_MS) or 60000
    end
    return tonumber(Const.SIMULATION_LIVE_IDLE_MS)
        or tonumber(Const.TICK_LIVE_COLD_MS)
        or 1000
end

function LOD.GetDecisionInterval(record)
    local tier = LOD.Resolve(record)
    if tier == "presence_wake" then return 50 end
    if tier == "combat_action" then return 50 end
    if tier == "combat" then return 100 end
    if tier == "follow_owner" then
        return tonumber(Const.FOLLOW_DECISION_INTERVAL_MS) or 100
    end
    if tier == "moving" or tier == "vehicle" then return 250 end
    if tier == "incapacitated" then return 250 end
    if tier == "abstract_near" or tier == "abstract_active"
        or tier == "abstract_travel"
    then
        return tonumber(Const.TICK_ABSTRACT_MS) or 3000
    end
    if tier == "abstract_far" then
        return tonumber(Const.TICK_ABSTRACT_FAR_MS) or 15000
    end
    if tier == "abstract_dormant" then
        return tonumber(Const.TICK_ABSTRACT_DORMANT_MS) or 60000
    end
    return tonumber(Const.SIMULATION_LIVE_IDLE_MS) or 1000
end

function LOD.GetVitalsInterval(record)
    local tier = LOD.Resolve(record)
    if tier == "combat_action" or tier == "combat"
        or tier == "incapacitated"
    then
        return tonumber(Const.SIMULATION_VITALS_HOT_MS) or 250
    end
    if tier == "abstract_near" or tier == "abstract_active"
        or tier == "abstract_travel"
    then
        return tonumber(Const.SIMULATION_VITALS_ABSTRACT_MS) or 5000
    end
    if tier == "abstract_far" then
        return tonumber(Const.TICK_ABSTRACT_FAR_MS) or 15000
    end
    if tier == "abstract_dormant" then
        return tonumber(Const.TICK_ABSTRACT_DORMANT_MS) or 60000
    end
    return tonumber(Const.SIMULATION_VITALS_LIVE_MS) or 1000
end

function LOD.GetPresenceInterval(record)
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        return tonumber(Const.SIMULATION_PRESENCE_ABSTRACT_MS) or 3000
    end
    return tonumber(Const.SIMULATION_PRESENCE_LIVE_MS) or 500
end

function LOD.GetPathInterval(record)
    local tier = LOD.Resolve(record)
    if tier == "combat_action" then
        return tonumber(Const.SIMULATION_PATH_HOT_MS) or 50
    end
    if tier == "combat" or tier == "follow_owner"
        or tier == "moving" or tier == "vehicle"
        or tier == "incapacitated"
    then
        return tonumber(Const.SIMULATION_PATH_MOVING_MS) or 100
    end
    return tonumber(Const.SIMULATION_PATH_IDLE_MS) or 500
end
