-- Road roaming mode provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.RoadMode
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local BehaviorCombat = H.BehaviorCombat
local randomFraction = H.RandomFraction
local beginAreaPause = H.BeginAreaPause
local resolveRoamingThreat = H.ResolveRoamingThreat
local areaMode = H.AreaMode

local function roadBoundsChanged(order, state)
    local bounds = order.roadBounds
    if type(bounds) ~= "table" then return true end
    return state.minX ~= tonumber(bounds.minX)
        or state.minY ~= tonumber(bounds.minY)
        or state.maxX ~= tonumber(bounds.maxX)
        or state.maxY ~= tonumber(bounds.maxY)
end

local function chooseRoadGoal(record, order, state)
    local bounds = order.roadBounds
    if type(bounds) ~= "table"
        or not tonumber(bounds.minX)
        or not tonumber(bounds.minY)
        or not tonumber(bounds.maxX)
        or not tonumber(bounds.maxY)
    then
        return areaMode(record, nil, order)
    end
    local minX = math.min(tonumber(bounds.minX), tonumber(bounds.maxX))
    local maxX = math.max(tonumber(bounds.minX), tonumber(bounds.maxX))
    local minY = math.min(tonumber(bounds.minY), tonumber(bounds.maxY))
    local maxY = math.max(tonumber(bounds.minY), tonumber(bounds.maxY))
    state.minX, state.minY = minX, minY
    state.maxX, state.maxY = maxX, maxY
    state.goalX = minX + randomFraction() * math.max(0, maxX - minX)
    state.goalY = minY + randomFraction() * math.max(0, maxY - minY)
    state.goalZ = tonumber(order.z) or record.anchorZ or record.z
    state.phase = "moving"
end

function H.Run(record, zombie, order)
    record.runtime = record.runtime or {}
    local state = record.runtime.roaming or {}
    local now = Core.Now()
    local target
    record.runtime.roaming = state
    if state.goalX ~= nil
        and record.runtime.pathing
        and record.runtime.pathing.phase == "blocked"
        and (
            record.runtime.pathing.blockReason == "native_path_unreachable"
            or record.runtime.pathing.blockReason == "native_goal_cooldown"
        )
    then
        state.goalX, state.goalY, state.goalZ = nil, nil, nil
        if beginAreaPause(record, zombie, order, state, now) then
            return true
        end
    end
    target = resolveRoamingThreat(
        record,
        state,
        math.max(1, tonumber(order.targetRadius) or Const.ROAM_TARGET_RADIUS),
        now
    )
    if target then
        state.phase = "combat"
        Common.SetCombatTarget(record, target, "roaming_threat")
        BehaviorCombat.TickEngage(record, zombie, target)
        return true
    end
    if record.runtime.target ~= nil then
        Common.ClearCombatTarget(record, "road_target_lost", zombie)
    end
    if roadBoundsChanged(order, state) then
        state.waitUntil = nil
        state.goalX, state.goalY, state.goalZ = nil, nil, nil
    elseif state.waitUntil then
        if now < state.waitUntil then
            state.phase = "idle"
            record.activeBehavior = "Roam:road:idle"
            return true
        end
        state.waitUntil = nil
    end
    if not state.goalX then chooseRoadGoal(record, order, state) end
    if state.goalX
        and Core.Distance(record.x, record.y, state.goalX, state.goalY)
            <= math.max(0.1, tonumber(order.reachedDistance)
                or Const.ROAM_REACHED_DISTANCE)
    then
        if beginAreaPause(record, zombie, order, state, now) then
            return true
        end
        chooseRoadGoal(record, order, state)
    end
    Common.ClearCombatTarget(record, "road_roaming", zombie)
    Common.MoveRecord(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ,
        tostring(order.moveMode or "walk"),
        math.max(0.1, tonumber(order.reachedDistance)
            or Const.ROAM_REACHED_DISTANCE),
        "roam_road"
    )
    return true
end

return Roaming
