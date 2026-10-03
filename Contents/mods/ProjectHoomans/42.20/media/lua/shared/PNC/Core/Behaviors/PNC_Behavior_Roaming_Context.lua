-- Shared roaming context provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.Context
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Targeting = H.Targeting
local Common = H.Common
local LEGACY_PAUSE_MIN_MS = 2500
local LEGACY_PAUSE_MAX_MS = 7000
local PREVIOUS_DEFAULT_PAUSE_MIN_MS = 5000
local PREVIOUS_DEFAULT_PAUSE_MAX_MS = 12000

local function randomFraction()
    return ZombRandFloat(0, 10000) / 10000
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
    state.phase = "moving"
end

local function syncAreaBounds(record, order, state)
    state.centerX =
        tonumber(order.x) or record.anchorX or record.x
    state.centerY =
        tonumber(order.y) or record.anchorY or record.y
    state.centerZ =
        tonumber(order.z) or record.anchorZ or record.z
    state.radius = math.max(
        0.5,
        tonumber(order.radius) or Const.ROAM_DEFAULT_RADIUS
    )
    state.goalX = nil
    state.goalY = nil
    state.goalZ = nil
end

local function areaStateChanged(record, order, state)
    return state.centerX ~= (tonumber(order.x) or record.anchorX or record.x)
        or state.centerY ~= (tonumber(order.y) or record.anchorY or record.y)
        or state.centerZ ~= (tonumber(order.z) or record.anchorZ or record.z)
        or state.radius ~= math.max(0.5, tonumber(order.radius) or Const.ROAM_DEFAULT_RADIUS)
end

local function hasActivePassage(record)
    local pathing = record and record.runtime
        and record.runtime.pathing or nil
    return pathing ~= nil
        and (
            pathing.traversalAction ~= nil
            or pathing.vanillaFenceAction ~= nil
            or pathing.blockedStepToX ~= nil
        )
end

local function beginAreaPause(record, zombie, order, state, now)
    local pauseMinMs = math.max(0, tonumber(order.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS)
    local pauseMaxMs = math.max(pauseMinMs, tonumber(order.pauseMaxMs) or Const.ROAM_PAUSE_MAX_MS)
    -- Existing saves materialized the old defaults into orderSpec. Treat that
    -- exact pair as a default profile so the calmer dwell policy applies
    -- without requiring players to recreate every roaming order.
    if (pauseMinMs == LEGACY_PAUSE_MIN_MS
        and pauseMaxMs == LEGACY_PAUSE_MAX_MS)
        or (pauseMinMs == PREVIOUS_DEFAULT_PAUSE_MIN_MS
            and pauseMaxMs == PREVIOUS_DEFAULT_PAUSE_MAX_MS)
    then
        pauseMinMs = tonumber(Const.ROAM_PAUSE_MIN_MS)
            or pauseMinMs
        pauseMaxMs = math.max(
            pauseMinMs,
            tonumber(Const.ROAM_PAUSE_MAX_MS)
                or pauseMaxMs
        )
    end
    if pauseMaxMs <= 0 then return false end

    -- A roam goal can be reached while a window/fence passage still owns the
    -- movement lane. Do not publish an idle pause over that traversal: the
    -- traversal intent deliberately outranks a hold and would otherwise keep
    -- the NPC in an idle-looking, timing-out passage state.
    if hasActivePassage(record) then
        state.pausePending = true
        return false, true
    end

    state.pausePending = nil
    state.waitUntil = now + pauseMinMs + (randomFraction() * (pauseMaxMs - pauseMinMs))
    state.idleSince = now
    state.phase = "idle"
    Common.ClearCombatTarget(record, "roam_pausing")
    Common.HaltMovement(record, zombie, "roam_pause")
    record.activeBehavior = "Roam:area:idle"
    return true
end

local function resolveRoamingThreat(
    record,
    state,
    targetRadius,
    now
)
    local activePath = record.runtime
        and record.runtime.pathing
        and (
            record.runtime.pathing.phase == "requested"
            or record.runtime.pathing.phase == "active"
        )
    local interval = activePath
        and (
            tonumber(Const.ROAM_THREAT_MOVING_SCAN_MS)
                or 250
        )
        or (
            tonumber(Const.ROAM_THREAT_IDLE_SCAN_MS)
                or 500
        )
    if record.runtime.target == nil
        and now < (tonumber(state.nextThreatScanAt) or 0)
    then
        return nil
    end
    state.nextThreatScanAt = now + interval
    return Targeting.ResolveRoamingEngageTarget(
        record,
        targetRadius
    )
end

H.RandomFraction = randomFraction
H.ChooseAreaGoal = chooseAreaGoal
H.SyncAreaBounds = syncAreaBounds
H.AreaStateChanged = areaStateChanged
H.HasActivePassage = hasActivePassage
H.BeginAreaPause = beginAreaPause
H.ResolveRoamingThreat = resolveRoamingThreat

return Roaming

