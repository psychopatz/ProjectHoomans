--[[
    PNC Client Interpolation
    Visual-only client smoothing for server-owned NPC transport snapshots.
]]

PNC = PNC or {}
PNC.ClientInterpolation = PNC.ClientInterpolation or {}

local Interpolation = PNC.ClientInterpolation
local Const = PNC.Const
local Core = PNC.Core

Interpolation.StateByID = Interpolation.StateByID or {}

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function getNowMs()
    return Core and Core.Now and Core.Now() or 0
end

local function buildHintKey(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local hint = visualState.motionHint or nil
    return table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(snapshot and snapshot.x or 0),
        tostring(snapshot and snapshot.y or 0),
        tostring(snapshot and snapshot.z or 0),
        tostring(hint and hint.fromX or ""),
        tostring(hint and hint.fromY or ""),
        tostring(hint and hint.toX or ""),
        tostring(hint and hint.toY or ""),
        tostring(hint and hint.toZ or ""),
        tostring(hint and hint.durationMs or ""),
        tostring(hint and hint.kind or ""),
        tostring(visualState.specialActive == true),
        tostring(visualState.specialAnim or ""),
    }, "|")
end

function Interpolation.ClearNPC(id)
    if id == nil then
        return
    end
    Interpolation.StateByID[tostring(id)] = nil
end

function Interpolation.ClearAll()
    Interpolation.StateByID = {}
end

function Interpolation.RecordSnapshot(snapshot, zombie, now)
    local id
    local visualState
    local hint
    local key
    local state
    local targetX
    local targetY
    local targetZ
    local fromX
    local fromY
    local fromZ
    local dx
    local dy
    local distance
    if not snapshot or not zombie then
        return nil
    end
    id = snapshot.id ~= nil and tostring(snapshot.id) or nil
    if not id then
        return nil
    end
    now = tonumber(now) or getNowMs()
    visualState = snapshot.visualState or {}
    hint = type(visualState.motionHint) == "table" and visualState.motionHint or nil
    key = buildHintKey(snapshot)
    state = Interpolation.StateByID[id] or {}
    if state.key == key then
        return state
    end
    targetX = tonumber(snapshot.x) or zombie:getX()
    targetY = tonumber(snapshot.y) or zombie:getY()
    targetZ = tonumber(snapshot.z) or zombie:getZ()
    fromX = hint and tonumber(hint.fromX) or state.targetX or zombie:getX()
    fromY = hint and tonumber(hint.fromY) or state.targetY or zombie:getY()
    fromZ = hint and tonumber(hint.fromZ) or state.targetZ or zombie:getZ()
    dx = targetX - fromX
    dy = targetY - fromY
    distance = math.sqrt((dx * dx) + (dy * dy))
    state.key = key
    state.startedAt = now
    state.durationMs = clamp(hint and hint.durationMs or Const.CLIENT_INTERP_BASE_MS or 150, 40, 1200)
    state.lastX = fromX
    state.lastY = fromY
    state.lastZ = fromZ
    state.targetX = targetX
    state.targetY = targetY
    state.targetZ = targetZ
    state.snapToTarget = distance > (tonumber(Const.CLIENT_INTERP_SNAP_DISTANCE) or 5.0)
    Interpolation.StateByID[id] = state
    return state
end

function Interpolation.ApplyToZombie(snapshot, zombie, now)
    local id
    local state
    local progress
    local interpX
    local interpY
    local interpZ
    local dx
    local dy
    local dz
    if not snapshot or not zombie then
        return false
    end
    id = snapshot.id ~= nil and tostring(snapshot.id) or nil
    if not id then
        return false
    end
    state = Interpolation.StateByID[id]
    if not state or state.targetX == nil or state.targetY == nil then
        return false
    end
    now = tonumber(now) or getNowMs()
    if (now - (tonumber(state.startedAt) or now)) > (tonumber(Const.CLIENT_INTERP_STALE_MS) or 2200) then
        Interpolation.StateByID[id] = nil
        return false
    end
    if state.snapToTarget then
        interpX = state.targetX
        interpY = state.targetY
        interpZ = state.targetZ
    else
        progress = clamp((now - (tonumber(state.startedAt) or now)) / math.max(1, tonumber(state.durationMs) or 1), 0, 1)
        interpX = state.lastX + ((state.targetX - state.lastX) * progress)
        interpY = state.lastY + ((state.targetY - state.lastY) * progress)
        interpZ = state.lastZ + ((state.targetZ - state.lastZ) * progress)
    end
    dx = interpX - zombie:getX()
    dy = interpY - zombie:getY()
    dz = (interpZ or zombie:getZ()) - zombie:getZ()
    if math.abs(dx) <= 0.001 and math.abs(dy) <= 0.001 and math.abs(dz) <= 0.001 then
        return false
    end
    zombie:setX(interpX)
    zombie:setY(interpY)
    if interpZ ~= nil and math.abs(dz) > 0.001 then
        zombie:setZ(interpZ)
    end
    return true
end
