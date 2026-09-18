PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local function isAuthority()
    return not PNC.Core or not PNC.Core.IsAuthority
        or PNC.Core.IsAuthority() ~= false
end

local function canWrite(record, reason)
    if ActorControl and ActorControl.CanWrite then
        return ActorControl.CanWrite(
            record, nil, "sleep_placement", { reason = reason }) == true
    end
    return true
end

local function squareKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function movingObjectCount(square)
    local objects = square and square.getMovingObjects
        and square:getMovingObjects() or nil
    if not objects then return 0, nil end
    if objects.size and objects.get then
        return objects:size(), objects
    end
    return #objects, objects
end

local function movingObjectAt(objects, index)
    if not objects then return nil end
    if objects.get then return objects:get(index) end
    return objects[index + 1]
end

function Internal.ValidateSleepSquare(x, y, z, zombie)
    local square = SquareRules.GetSquare(x, y, z)
    local index
    local count
    local objects
    local occupant
    if not square then
        -- An abstract worker may resolve geometry before its chunk is loaded.
        -- A live worker must not be committed into an unloaded or unknown tile.
        return type(getCell) ~= "function", "SLEEP_SQUARE_UNLOADED"
    end
    if square.isFree then
        local ok, free = pcall(square.isFree, square, false)
        if not ok or free ~= true then
            return false, "SLEEP_SQUARE_BLOCKED"
        end
    end
    count, objects = movingObjectCount(square)
    for index = 0, count - 1 do
        occupant = movingObjectAt(objects, index)
        if occupant and occupant ~= zombie then
            return false, "SLEEP_SQUARE_OCCUPIED"
        end
    end
    return true
end

local function addCandidate(output, seen, candidate)
    local x = tonumber(candidate and candidate.x)
    local y = tonumber(candidate and candidate.y)
    local z = tonumber(candidate and candidate.z)
    local key
    if not x or not y or not z then return end
    key = squareKey(x, y, z)
    if seen[key] then return end
    seen[key] = true
    output[#output + 1] = { x = x, y = y, z = z,
        approachKey = candidate.approachKey or key }
end

local function footprintCandidates(output, seen, order, runtime)
    local anchorX = tonumber(order and (order.sleepAnchorX
        or runtime and runtime.sleepAnchorX))
    local anchorY = tonumber(order and (order.sleepAnchorY
        or runtime and runtime.sleepAnchorY))
    local anchorZ = math.floor(tonumber(order and order.z)
        or tonumber(runtime and runtime.z) or 0)
    local width = math.max(1, math.floor(tonumber(order
        and (order.sleepGridWidth or runtime and runtime.sleepGridWidth)) or 1))
    local height = math.max(1, math.floor(tonumber(order
        and (order.sleepGridHeight or runtime and runtime.sleepGridHeight)) or 1))
    local baseX
    local baseY
    local offsets = {
        { x = 0, y = 1 }, { x = 1, y = 0 },
        { x = 0, y = -1 }, { x = -1, y = 0 },
    }
    local fx
    local fy
    local index
    if not anchorX or not anchorY then return end
    baseX = math.floor(anchorX - width / 2)
    baseY = math.floor(anchorY - height / 2)
    for fy = 0, height - 1 do
        for fx = 0, width - 1 do
            for index = 1, #offsets do
                local offset = offsets[index]
                local x = baseX + fx + offset.x + 0.5
                local y = baseY + fy + offset.y + 0.5
                addCandidate(output, seen, { x = x, y = y, z = anchorZ })
            end
        end
    end
end

local function addLiveBodyCandidate(output, seen, zombie, order, runtime)
    local x
    local y
    local z
    if not zombie or not zombie.getX or not zombie.getY then return end
    x, y = zombie:getX(), zombie:getY()
    if not x or not y then return end
    z = order and tonumber(order.z)
        or runtime and tonumber(runtime.z)
        or zombie.getZ and tonumber(zombie:getZ())
    if not z then return end
    addCandidate(output, seen, { x = x, y = y, z = z })
end

local function addBodyRingCandidates(output, seen, zombie, order, runtime)
    local baseX
    local baseY
    local z
    local radius
    local dx
    local dy
    if not zombie or not zombie.getX or not zombie.getY then return end
    baseX, baseY = math.floor(zombie:getX()), math.floor(zombie:getY())
    z = order and tonumber(order.z)
        or runtime and tonumber(runtime.z)
        or zombie.getZ and tonumber(zombie:getZ())
    if not z then return end
    -- A sleeping body can share the original square with another actor by
    -- the time its scene is interrupted. Search only two bounded rings; the
    -- final validator still rejects solid, unloaded, and occupied squares.
    for radius = 1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) + math.abs(dy) == radius then
                    addCandidate(output, seen, {
                        x = baseX + dx + 0.5,
                        y = baseY + dy + 0.5,
                        z = z,
                    })
                end
            end
        end
    end
end

local function exitCandidates(runtime, order, zombie)
    local output, seen = {}, {}
    local index
    addCandidate(output, seen, runtime and runtime.approachPosition)
    -- Floor sleep has no furniture interaction pose. Retain the live body's
    -- current square as the first safe exit candidate instead of requiring a
    -- nonexistent pre-snap coordinate.
    addLiveBodyCandidate(output, seen, zombie, order, runtime)
    for index = 1, #(runtime and runtime.approachCandidates or {}) do
        addCandidate(output, seen, runtime.approachCandidates[index])
    end
    footprintCandidates(output, seen, order, runtime)
    addBodyRingCandidates(output, seen, zombie, order, runtime)
    return output
end

function Internal.FindSleepExit(record, zombie, runtime, order)
    local candidates = exitCandidates(
        runtime,
        order or record and record.orderSpec,
        zombie
    )
    local index
    local valid
    local reason
    if not isAuthority() then return nil, "SLEEP_NOT_AUTHORITY" end
    for index = 1, #candidates do
        valid, reason = Internal.ValidateSleepSquare(
            candidates[index].x, candidates[index].y, candidates[index].z,
            zombie)
        if valid then return candidates[index] end
    end
    return nil, reason or "SLEEP_EXIT_UNAVAILABLE"
end

function Internal.CommitSleepExit(record, zombie, runtime, candidate)
    local ok
    local reason
    if not candidate then return false, "SLEEP_EXIT_UNAVAILABLE" end
    if not isAuthority() then return false, "SLEEP_NOT_AUTHORITY" end
    if not canWrite(record, "sleep_exit_placement") then
        return false, "puppet_opera_writer_blocked:sleep_placement"
    end
    ok, reason = Internal.ValidateSleepSquare(
        candidate.x, candidate.y, candidate.z, zombie)
    if not ok then return false, reason end
    if zombie and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        if PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, candidate.x, candidate.y, candidate.z) == false
        then
            return false, "SLEEP_EXIT_WRITE_FAILED"
        end
    end
    record.x, record.y, record.z = candidate.x, candidate.y, candidate.z
    runtime.approachPosition = nil
    runtime.sleepExitPosition = {
        x = candidate.x, y = candidate.y, z = candidate.z,
    }
    runtime.positioned = false
    runtime.phase = "WAKING_EXITED"
    return true
end

function Internal.TrySnapToSleep(record, zombie, runtime, order)
    local x
    local y
    local z
    local distance
    local arrivalDistance
    local valid
    local reason
    if not runtime or (runtime.capability ~= "sleep"
        and runtime.action ~= "sleep")
    then
        return true, "NOT_SLEEP"
    end
    if not order then return true, "NO_SLEEP_INTERACTION" end
    if not isAuthority() then return true, "SLEEP_NOT_AUTHORITY" end
    if not zombie or not zombie.getX or not zombie.getY
        or not PNC.LiveBodyControl
        or not PNC.LiveBodyControl.SetAuthoritativePosition
    then
        return true, "SLEEP_ABSTRACT"
    end
    x, y, z = zombie:getX(), zombie:getY(), zombie:getZ()
    distance = PNC.Core and PNC.Core.Distance
        and PNC.Core.Distance(x, y, order.x, order.y)
        or math.sqrt((x - order.x) * (x - order.x)
            + (y - order.y) * (y - order.y))
    arrivalDistance = tonumber(order.arrivalDistance) or 0.85
    if distance > arrivalDistance
        or math.abs(z - (tonumber(order.z) or z)) >= 0.5
    then
        return false, "SLEEP_NOT_CLOSE"
    end
    if not order.interactionX or not order.interactionY then
        -- Floor sleep intentionally has no object interaction pose. Preserve
        -- the live approach position so wake cleanup can validate and commit
        -- a real free square instead of waiting forever with no candidates.
        runtime.approachPosition = { x = x, y = y, z = z }
        runtime.positioned = false
        return true, "SLEEP_APPROACH_RECORDED"
    end
    valid, reason = Internal.ValidateSleepSquare(order.x, order.y, order.z,
        zombie)
    if not valid then return false, reason end
    if not canWrite(record, "sleep_entry_placement") then
        return false, "puppet_opera_writer_blocked:sleep_placement"
    end
    if Internal.ResetPath then
        Internal.ResetPath(record, zombie, "sleep_entry_snap")
    end
    runtime.approachPosition = { x = x, y = y, z = z }
    if PNC.LiveBodyControl.SetAuthoritativePosition(
        zombie, order.interactionX, order.interactionY,
        order.interactionZ or order.z) == false
    then
        return false, "SLEEP_ENTRY_WRITE_FAILED"
    end
    record.x, record.y, record.z = order.interactionX,
        order.interactionY, order.interactionZ or order.z
    runtime.positioned = true
    runtime.sleepSlotId = tostring(order.sleepSlotId
        or runtime.sleepSlotId or "")
    runtime.sleepCapacity = tonumber(order.sleepCapacity
        or runtime.sleepCapacity)
    return true, "SLEEP_POSITIONED"
end

function Internal.RestoreSleepPosition(record, zombie, runtime, order)
    if not runtime or runtime.positioned ~= true then return true end
    local candidate, reason = Internal.FindSleepExit(
        record, zombie, runtime, order or record and record.orderSpec)
    if not candidate then return false, reason end
    return Internal.CommitSleepExit(record, zombie, runtime, candidate)
end

return Internal
