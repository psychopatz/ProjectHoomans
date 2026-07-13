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

local function shouldApplyClientInterpolation()
    return Core and Core.IsClientOnly and Core.IsClientOnly()
end

local function normalize2D(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then
        return nil, nil
    end
    return dx / len, dy / len
end

local function isDebugEnabled(snapshot, state)
    if snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true then
        return true
    end
    if state and state.debugEnabled == true then
        return true
    end
    return PNC.Runtime and PNC.Runtime.debugEnabled == true
end

local function logDebug(snapshot, state, id, event, extra)
    if not isDebugEnabled(snapshot, state) or not Core or not Core.Log then
        return
    end
    Core.Log("DEBUG", "client_interp npc=" .. tostring(id or "nil") .. " event=" .. tostring(event or "unknown") .. (extra and extra ~= "" and (" " .. tostring(extra)) or ""))
end

local function buildStreamKind(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local hint = visualState.motionHint or nil
    if visualState.specialActive == true and visualState.specialAnim then
        return "special:" .. tostring(visualState.specialAnim)
    end
    if hint and hint.kind then
        return tostring(hint.kind)
    end
    return "move"
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
    local dx
    local dy
    local distance
    local currentX
    local currentY
    local currentZ
    local streamKind
    local authoritativeFromX
    local authoritativeFromY
    local authoritativeFromZ
    local hardBoundary
    local snapDistance
    local dirX
    local dirY
    local rewindProjected
    local fromX
    local fromY
    local fromZ
    if not snapshot or not zombie then
        return nil
    end
    if not shouldApplyClientInterpolation() then
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
    currentX = zombie:getX()
    currentY = zombie:getY()
    currentZ = zombie:getZ()
    targetX = tonumber(snapshot.x) or currentX
    targetY = tonumber(snapshot.y) or currentY
    targetZ = tonumber(snapshot.z) or currentZ
    authoritativeFromX = hint and tonumber(hint.fromX) or state.targetX or currentX
    authoritativeFromY = hint and tonumber(hint.fromY) or state.targetY or currentY
    authoritativeFromZ = hint and tonumber(hint.fromZ) or state.targetZ or currentZ
    streamKind = buildStreamKind(snapshot)
    snapDistance = tonumber(Const.CLIENT_INTERP_SNAP_DISTANCE) or 5.0
    dx = targetX - currentX
    dy = targetY - currentY
    distance = math.sqrt((dx * dx) + (dy * dy))
    hardBoundary = state.key == nil
        or tostring(state.presenceRevision or "") ~= tostring(snapshot.presenceRevision or "")
        or tostring(state.liveBodyInstanceID or "") ~= tostring(snapshot.liveBodyInstanceID or "")
        or tostring(state.streamKind or "") ~= tostring(streamKind)
        or math.abs((tonumber(state.targetZ) or currentZ) - targetZ) > 0.01
        or distance > snapDistance

    if hardBoundary then
        fromX = authoritativeFromX
        fromY = authoritativeFromY
        fromZ = authoritativeFromZ
    else
        fromX = currentX
        fromY = currentY
        fromZ = currentZ
        dirX = tonumber(hint and hint.dirX) or tonumber(state.dirX) or (targetX - authoritativeFromX)
        dirY = tonumber(hint and hint.dirY) or tonumber(state.dirY) or (targetY - authoritativeFromY)
        dirX, dirY = normalize2D(dirX, dirY)
        if dirX and dirY then
            rewindProjected = ((currentX - authoritativeFromX) * dirX) + ((currentY - authoritativeFromY) * dirY)
            if rewindProjected > 0.02 then
                logDebug(snapshot, state, id, "interp_rewind_prevented", string.format("from=%.2f,%.2f current=%.2f,%.2f", authoritativeFromX, authoritativeFromY, currentX, currentY))
            end
        end
    end

    dx = targetX - fromX
    dy = targetY - fromY
    distance = math.sqrt((dx * dx) + (dy * dy))
    state.key = key
    state.startedAt = now
    state.durationMs = clamp(hint and hint.durationMs or Const.CLIENT_INTERP_BASE_MS or 150, 40, 1200)
    if visualState.moving == true and streamKind == "move" then
        state.durationMs = math.max(state.durationMs, tonumber(Const.CLIENT_INTERP_MOVE_MIN_MS) or 200)
    end
    state.lastX = fromX
    state.lastY = fromY
    state.lastZ = fromZ
    state.targetX = targetX
    state.targetY = targetY
    state.targetZ = targetZ
    state.snapToTarget = hardBoundary and distance > snapDistance
    state.presenceRevision = snapshot.presenceRevision
    state.liveBodyInstanceID = snapshot.liveBodyInstanceID
    state.streamKind = streamKind
    state.dirX = targetX - fromX
    state.dirY = targetY - fromY
    state.debugEnabled = snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true or false
    Interpolation.StateByID[id] = state
    logDebug(snapshot, state, id, "segment_start", string.format("kind=%s hard=%s from=%.2f,%.2f to=%.2f,%.2f dur=%d", tostring(streamKind), tostring(hardBoundary), fromX, fromY, targetX, targetY, tonumber(state.durationMs) or 0))
    if state.snapToTarget then
        logDebug(snapshot, state, id, "segment_snap", string.format("dist=%.2f", distance))
    end
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
    if not shouldApplyClientInterpolation() then
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
        logDebug(nil, state, id, "stale_clear", "")
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
    if math.abs(dx) > 0.001 or math.abs(dy) > 0.001 then
        local len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.001 then
            state.renderDirX = dx / len
            state.renderDirY = dy / len
            state.renderDirAt = now
        end
    end
    zombie:setX(interpX)
    zombie:setY(interpY)
    if interpZ ~= nil and math.abs(dz) > 0.001 then
        zombie:setZ(interpZ)
    end
    return true
end
