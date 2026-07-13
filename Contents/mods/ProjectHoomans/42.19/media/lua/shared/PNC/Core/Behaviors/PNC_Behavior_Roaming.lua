--[[
    PNC Behavior Roaming
    Faction-neutral roaming that scans for configured enemies before moving.
    Roam modes are registered independently so radius, route, or venue-specific
    variants can be added without changing the behavior coordinator.
]]

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local Registry = PNC.BehaviorRegistry
local JobSystem = PNC.JobSystem
local OrderSystem = PNC.OrderSystem
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Const = PNC.Const

Roaming.Modes = Roaming.Modes or {}

local function randomFraction()
    return ZombRandFloat(0, 10000) / 10000
end

local function normalizeOrder(record, spec)
    local pauseMinMs = math.max(0, tonumber(spec.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS)
    local pauseMaxMs = math.max(pauseMinMs, tonumber(spec.pauseMaxMs) or Const.ROAM_PAUSE_MAX_MS)
    return {
        kind = Const.ORDER_ROAM,
        roamMode = tostring(spec.roamMode or Const.ROAM_MODE_AREA),
        x = tonumber(spec.x) or record.anchorX,
        y = tonumber(spec.y) or record.anchorY,
        z = tonumber(spec.z) or record.anchorZ,
        radius = math.max(0.5, tonumber(spec.radius) or Const.ROAM_DEFAULT_RADIUS),
        targetRadius = math.max(1, tonumber(spec.targetRadius) or Const.ROAM_TARGET_RADIUS),
        reachedDistance = math.max(0.1, tonumber(spec.reachedDistance) or Const.ROAM_REACHED_DISTANCE),
        moveMode = tostring(spec.moveMode or "walk"),
        pauseMinMs = pauseMinMs,
        pauseMaxMs = pauseMaxMs,
    }
end

local function chooseAreaGoal(record, order, state)
    local centerX = tonumber(order.x) or record.anchorX or record.x
    local centerY = tonumber(order.y) or record.anchorY or record.y
    local centerZ = tonumber(order.z) or record.anchorZ or record.z
    local radius = math.max(0.5, tonumber(order.radius) or Const.ROAM_DEFAULT_RADIUS)
    local angle = randomFraction() * math.pi * 2
    local distance = math.sqrt(randomFraction()) * radius

    state.centerX = centerX
    state.centerY = centerY
    state.centerZ = centerZ
    state.radius = radius
    state.goalX = centerX + (math.cos(angle) * distance)
    state.goalY = centerY + (math.sin(angle) * distance)
    state.goalZ = centerZ
end

local function areaStateChanged(record, order, state)
    return state.centerX ~= (tonumber(order.x) or record.anchorX or record.x)
        or state.centerY ~= (tonumber(order.y) or record.anchorY or record.y)
        or state.centerZ ~= (tonumber(order.z) or record.anchorZ or record.z)
        or state.radius ~= math.max(0.5, tonumber(order.radius) or Const.ROAM_DEFAULT_RADIUS)
end

local function beginAreaPause(record, zombie, order, state, now)
    local pauseMinMs = math.max(0, tonumber(order.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS)
    local pauseMaxMs = math.max(pauseMinMs, tonumber(order.pauseMaxMs) or Const.ROAM_PAUSE_MAX_MS)
    if pauseMaxMs <= 0 then return false end

    state.waitUntil = now + pauseMinMs + (randomFraction() * (pauseMaxMs - pauseMinMs))
    Common.ClearCombatTarget(record, "roam_pausing")
    Common.HaltMovement(record, zombie, "roam_pause")
    record.activeBehavior = "Roam:area:idle"
    return true
end

local function areaMode(record, zombie, order)
    record.runtime = record.runtime or {}
    local targetRadius = math.max(1, tonumber(order.targetRadius) or Const.ROAM_TARGET_RADIUS)
    local target = Targeting.ResolveRoamingEngageTarget(record, targetRadius)
    if target then
        record.runtime.target = target
        BehaviorCombat.TickEngage(record, zombie, target)
        return true
    end

    local state = record.runtime.roaming or {}
    record.runtime.roaming = state
    local reachedDistance = math.max(0.1, tonumber(order.reachedDistance) or Const.ROAM_REACHED_DISTANCE)
    local now = Core.Now()

    if areaStateChanged(record, order, state) then
        state.waitUntil = nil
        chooseAreaGoal(record, order, state)
    elseif state.waitUntil then
        if now < state.waitUntil then
            record.activeBehavior = "Roam:area:idle"
            return true
        end
        state.waitUntil = nil
        chooseAreaGoal(record, order, state)
    elseif not state.goalX then
        chooseAreaGoal(record, order, state)
    elseif Core.Distance(record.x, record.y, state.goalX, state.goalY) <= reachedDistance then
        if beginAreaPause(record, zombie, order, state, now) then return true end
        chooseAreaGoal(record, order, state)
    end

    Common.ClearCombatTarget(record, "roaming")
    Common.MoveRecord(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ,
        tostring(order.moveMode or "walk"),
        reachedDistance,
        "roam_area"
    )
    return true
end

function Roaming.RegisterMode(mode, handler)
    mode = tostring(mode or "")
    if mode == "" or type(handler) ~= "function" then return false end
    Roaming.Modes[mode] = handler
    return true
end

function Roaming.Tick(record, zombie)
    local order = record.orderSpec or {}
    local mode = tostring(order.roamMode or Const.ROAM_MODE_AREA)
    local handler = Roaming.Modes[mode]
    if not handler then
        mode = Const.ROAM_MODE_AREA
        handler = Roaming.Modes[mode]
    end
    if not handler then return false end
    record.activeBehavior = "Roam:" .. mode
    return handler(record, zombie, order) == true
end

Roaming.RegisterMode(Const.ROAM_MODE_AREA, areaMode)
OrderSystem.RegisterNormalizer(Const.ORDER_ROAM, normalizeOrder)
OrderSystem.RegisterNormalizer(Const.ORDER_HOSTILE_ROAM, normalizeOrder)
JobSystem.RegisterOrder(Const.ORDER_ROAM, Const.JOB_ROAM)
JobSystem.RegisterOrder(Const.ORDER_HOSTILE_ROAM, Const.JOB_ROAM)
Registry.Register(Const.JOB_ROAM, Roaming.Tick)

return Roaming
