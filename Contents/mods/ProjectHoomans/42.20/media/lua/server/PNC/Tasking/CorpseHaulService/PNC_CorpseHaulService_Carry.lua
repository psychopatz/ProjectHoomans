-- Non-grapple visible corpse carry.
--
-- Project Hoomans does not use IsoGameCharacter:pickUpCorpse(), because that
-- API enters the engine's grapple/reanimation path. Instead, this module
-- keeps the real IsoDeadBody in the world and advances its coordinates with
-- the authoritative worker. Crossing a tile performs the required
-- removeCorpse/addCorpse handoff; movement itself remains PathService-owned.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Lifecycle = PNC.BodyLifecycle
local WorkRepository = PNC.WorkRepository

local function pointKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function addPoint(points, seen, x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    local key = pointKey(x, y, z)
    if seen[key] then return end
    seen[key] = true
    points[#points + 1] = { x = x, y = y, z = z }
end

local function resolveCorpse(order, task, body)
    local payload = order and order.payload or nil
    local points, seen = {}, {}
    local corpse = task and task.corpse or nil
    local carryX = task and task.carryX or payload and payload.carryX
    local carryY = task and task.carryY or payload and payload.carryY
    local carryZ = task and task.carryZ or payload and payload.carryZ

    if corpse and corpse.getSquare and corpse:getSquare() then
        return corpse
    end
    addPoint(points, seen, carryX, carryY, carryZ)
    addPoint(points, seen, payload and payload.sourceX,
        payload and payload.sourceY, payload and payload.sourceZ)
    addPoint(points, seen, payload and payload.dropX,
        payload and payload.dropY, payload and payload.dropZ)

    if body and body.getX and body.getY and body.getZ then
        local bx, by, bz = body:getX(), body:getY(), body:getZ()
        local radius
        local dx
        local dy
        for radius = 0, 2 do
            for dx = -radius, radius do
                for dy = -radius, radius do
                    addPoint(points, seen, math.floor(bx) + dx,
                        math.floor(by) + dy, math.floor(bz))
                end
            end
        end
    end

    for _, point in ipairs(points) do
        corpse = Service.GetCorpseAt(point.x, point.y, point.z,
            payload and payload.haulToken,
            payload and (payload.deathMarkerId or payload.corpseId))
        if corpse then return corpse end
    end
    return nil
end

local function carryPosition(body, assignment)
    local x = body and body.getX and tonumber(body:getX()) or nil
    local y = body and body.getY and tonumber(body:getY()) or nil
    local z = body and body.getZ and tonumber(body:getZ()) or nil
    local forward = body and body.getForwardDirection
        and body:getForwardDirection() or nil
    local fx = forward and tonumber(forward.x) or 0
    local fy = forward and tonumber(forward.y) or 0
    local length = math.sqrt(fx * fx + fy * fy)
    local targetX = assignment and tonumber(assignment.dropX) or x
    local targetY = assignment and tonumber(assignment.dropY) or y

    if not x or not y or not z then return nil end
    if length < 0.05 then
        fx, fy = (targetX or x) - x, (targetY or y) - y
        length = math.sqrt(fx * fx + fy * fy)
    end
    if length < 0.05 then fx, fy, length = 0, 1, 1 end
    fx, fy = fx / length, fy / length
    local offset = tonumber(Service.CORPSE_CARRY_OFFSET) or 0.65
    return x - fx * offset, y - fy * offset, z
end

local function transmit(corpse)
    if corpse and corpse.transmitModData then corpse:transmitModData() end
end

local function markCarrying(corpse, order)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local owner = tostring(order and order.id or "")
    if not data then return false end
    if tostring(data.PNC_CorpseHaulCarriedBy or "") ~= owner then
        data.PNC_CorpseHaulCarriedBy = owner
        transmit(corpse)
    end
    return true
end

function Internal.beginCorpseCarry(order, task, body, assignment)
    local corpse = resolveCorpse(order, task, body)
    if not corpse then return false, "CORPSE_NOT_FOUND_AFTER_GRAB" end
    task.corpse = corpse
    task.carrying = true
    markCarrying(corpse, order)
    return true, corpse
end

function Internal.tickCorpseCarry(order, task, record, body, assignment, now)
    local corpse = resolveCorpse(order, task, body)
    local x
    local y
    local z
    local moved
    local reason
    local payload
    local currentNow = tonumber(now) or (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0)

    if not corpse then return false, "CORPSE_NOT_FOUND_WHILE_CARRYING" end
    x, y, z = carryPosition(body, assignment)
    if not x then return false, "LIVE_BODY_REQUIRED" end
    if not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.followCorpse
    then
        return false, "CORPSE_FOLLOW_UNAVAILABLE"
    end

    -- The body is a static moving object, not an actor. Rewriting its
    -- coordinates every task tick needlessly dirties the render chunk and can
    -- make the corpse shadow smear/duplicate. Keep the visible attachment
    -- responsive, but only publish a new position when the worker has moved a
    -- meaningful amount or the bounded cadence has elapsed.
    local updateMs = math.max(
        40,
        tonumber(Service.CORPSE_CARRY_UPDATE_MS) or 100
    )
    local lastX = tonumber(task.lastCarryFollowX)
    local lastY = tonumber(task.lastCarryFollowY)
    local lastZ = tonumber(task.lastCarryFollowZ)
    local dx = lastX and x - lastX or math.huge
    local dy = lastY and y - lastY or math.huge
    local dz = lastZ and z - lastZ or math.huge
    if lastX and lastY and lastZ
        and currentNow - (tonumber(task.lastCarryFollowAt) or 0) < updateMs
        and (dx * dx) + (dy * dy) + (dz * dz) < 0.0016
    then
        task.corpse = corpse
        task.carrying = true
        markCarrying(corpse, order)
        if record then
            record.runtime = record.runtime or {}
            record.runtime.corpseHaulCarrying = true
        end
        if body and body.setVariable then
            body:setVariable("PNCCorpseCarrying", true)
        end
        return true
    end
    moved, reason = Lifecycle.Internal.followCorpse(corpse, x, y, z)
    if not moved then return false, reason end

    task.corpse = corpse
    task.carrying = true
    task.carryX, task.carryY, task.carryZ = x, y, z
    task.lastCarryFollowX, task.lastCarryFollowY, task.lastCarryFollowZ = x, y, z
    task.lastCarryFollowAt = currentNow
    markCarrying(corpse, order)

    -- Persist a recovery coordinate at a bounded cadence. The actual corpse
    -- object remains authoritative in the world, while this projection lets a
    -- server restart reacquire it without assuming it is still at source.
    payload = order and order.payload or nil
    if payload and currentNow >= (tonumber(task.lastCarryPersistAt) or 0)
        + (tonumber(Service.CORPSE_CARRY_PERSIST_MS) or 500)
    then
        payload.carryX, payload.carryY, payload.carryZ = x, y, z
        task.lastCarryPersistAt = currentNow
        order.updatedAt = currentNow
        order.revision = (tonumber(order.revision) or 0) + 1
        if WorkRepository and WorkRepository.MarkDirty then
            WorkRepository.MarkDirty()
        end
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.corpseHaulCarrying = true
    end
    if body and body.setVariable then
        body:setVariable("PNCCorpseCarrying", true)
    end
    return true
end

function Internal.clearCorpseCarry(order, task, body)
    local corpse = resolveCorpse(order, task, body)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local orderId = tostring(order and order.id or "")
    if data and tostring(data.PNC_CorpseHaulCarriedBy or "") == orderId then
        data.PNC_CorpseHaulCarriedBy = nil
        transmit(corpse)
    end
    if task then
        task.corpse = nil
        task.carrying = nil
        task.lastCarryFollowX = nil
        task.lastCarryFollowY = nil
        task.lastCarryFollowZ = nil
        task.lastCarryFollowAt = nil
    end
    return corpse
end

Internal.resolveCorpseForCarry = resolveCorpse

return Service
