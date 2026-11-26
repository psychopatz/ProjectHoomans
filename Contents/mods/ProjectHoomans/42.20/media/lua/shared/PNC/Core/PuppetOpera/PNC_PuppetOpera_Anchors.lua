-- Relative tile-anchor planning for Puppet Opera.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Anchors = PNC.PuppetOpera.Anchors or {}

local Anchors = PNC.PuppetOpera.Anchors

local function finite(value)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function cardinal(x, y)
    x = finite(x)
    y = finite(y)
    if not x or not y then return nil end
    if math.abs(x) < 0.0001 and math.abs(y) < 0.0001 then
        return nil
    end
    if math.abs(x) >= math.abs(y) then
        return x >= 0 and 1 or -1, 0
    end
    return 0, y >= 0 and 1 or -1
end

function Anchors.QuantizeForward(x, y)
    local forwardX, forwardY = cardinal(x, y)
    if not forwardX then return nil, "forward_direction_invalid" end
    return {
        x = forwardX,
        y = forwardY,
        rightX = -forwardY,
        rightY = forwardX,
    }
end

function Anchors.ReadForward(actor)
    if not actor then return nil, "actor_missing" end
    if actor.getForwardDirectionX and actor.getForwardDirectionY then
        return Anchors.QuantizeForward(
            actor:getForwardDirectionX(),
            actor:getForwardDirectionY()
        )
    end
    return nil, "forward_direction_api_unavailable"
end

local function integer(value)
    local number = finite(value)
    if not number then return nil end
    return math.floor(number)
end

local function actorPosition(actor)
    if not actor or not actor.getX or not actor.getY then
        return nil, "actor_position_api_unavailable"
    end
    local x = integer(actor:getX())
    local y = integer(actor:getY())
    local z = actor.getZ and integer(actor:getZ()) or 0
    if not x or not y or not z then
        return nil, "actor_position_invalid"
    end
    return x, y, z
end

local function targetKey(x, y, z)
    return table.concat({ tostring(x), tostring(y), tostring(z) }, ":")
end

local function applyInteractionDistance(plan, actorIDs, distance)
    distance = tonumber(distance)
    if not distance or #actorIDs ~= 2 then return end
    local first = plan.actors[actorIDs[1]]
    local second = plan.actors[actorIDs[2]]
    if not first or not second then return end
    local dx = second.worldX - first.worldX
    local dy = second.worldY - first.worldY
    local current = math.sqrt(dx * dx + dy * dy)
    if current < 0.0001 or current <= distance then return end
    local midpointX = (first.worldX + second.worldX) * 0.5
    local midpointY = (first.worldY + second.worldY) * 0.5
    local scale = (distance * 0.5) / current
    local offsetX = dx * scale
    local offsetY = dy * scale
    first.worldX = midpointX - offsetX
    first.worldY = midpointY - offsetY
    second.worldX = midpointX + offsetX
    second.worldY = midpointY + offsetY
end

local function callSafe(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    return fn(object, ...)
end

local function squareUsable(square)
    if not square then return false end
    if callSafe(square, "isSolid") == true
        or callSafe(square, "isSolidTrans") == true
    then
        return false
    end
    local free = callSafe(square, "isFree", false)
    return free ~= false
end

local function isPlanWalkable(plan, cell, originSq)
    if not cell or type(cell.getGridSquare) ~= "function" then return true end
    local originIndoor = originSq and callSafe(originSq, "isInARoom") or nil
    local planOriginSq = cell:getGridSquare(
        plan.origin.x, plan.origin.y, plan.origin.z)
    if not squareUsable(planOriginSq) then return false end
    if originIndoor == true and callSafe(planOriginSq, "isInARoom") == false then
        return false
    end
    for _, target in pairs(plan.actors) do
        local sq = cell:getGridSquare(target.x, target.y, target.z)
        if not squareUsable(sq) then return false end
        if originIndoor == true and callSafe(sq, "isInARoom") == false then
            return false
        end
        local manhattan = math.abs(target.x - plan.origin.x)
            + math.abs(target.y - plan.origin.y)
        if manhattan == 1 and planOriginSq
            and callSafe(planOriginSq, "isBlockedTo", sq) == true
        then
            return false
        end
    end
    return true
end

local function projectPlan(blueprint, originX, originY, originZ,
    forwardX, forwardY, rightX, rightY)
    local frame = blueprint.anchorFrame or {}
    local anchors = frame.anchors or {}
    local actors = blueprint.actors or {}
    local plan = {
        origin = { x = originX, y = originY, z = originZ },
        orientation = {
            x = forwardX,
            y = forwardY,
            rightX = rightX,
            rightY = rightY,
        },
        tolerance = tonumber(frame.tolerance) or 0.75,
        interactionDistance = tonumber(frame.interactionDistance),
        movementStopDistance = tonumber(frame.movementStopDistance),
        arrivalTolerance = tonumber(frame.arrivalTolerance)
            or tonumber(frame.movementStopDistance)
            or tonumber(frame.tolerance)
            or 0.75,
        actors = {},
        occupied = {},
    }
    local allowOverlap = frame.allowOverlap == true
    local originWorldX = originX + 0.5
    local originWorldY = originY + 0.5
    for actorID, actorDefinition in pairs(actors) do
        local anchor = anchors[actorDefinition.anchor]
        if not anchor then
            return nil, "anchor_missing:" .. tostring(actorID)
        end
        local anchorRight = tonumber(anchor.right) or 0
        local anchorForward = tonumber(anchor.forward) or 0
        local worldX = originWorldX + rightX * anchorRight
            + forwardX * anchorForward
        local worldY = originWorldY + rightY * anchorRight
            + forwardY * anchorForward
        local worldZ = originZ + (tonumber(anchor.z) or 0)
        local x, y, z = integer(worldX), integer(worldY), integer(worldZ)
        local key = targetKey(x, y, z)
        if not allowOverlap and plan.occupied[key] then
            return nil, "anchors_overlap:" .. tostring(actorID)
        end
        plan.occupied[key] = actorID
        plan.actors[actorID] = {
            id = actorID,
            anchor = actorDefinition.anchor,
            x = x,
            y = y,
            z = z,
            worldX = worldX,
            worldY = worldY,
            worldZ = worldZ,
            faceTarget = anchor.faceTarget,
        }
    end
    local actorIDs = {}
    for actorID in pairs(plan.actors) do actorIDs[#actorIDs + 1] = actorID end
    table.sort(actorIDs)
    applyInteractionDistance(plan, actorIDs, plan.interactionDistance)
    return plan
end

local function buildCandidateOrientations(fx, fy, rx, ry)
    -- Preferred forward, right, left, back (all orthonormal cardinal bases).
    return {
        { x = fx, y = fy, rightX = rx, rightY = ry },
        { x = rx, y = ry, rightX = -fx, rightY = -fy },
        { x = -rx, y = -ry, rightX = fx, rightY = fy },
        { x = -fx, y = -fy, rightX = -rx, rightY = -ry },
    }
end

function Anchors.BuildPlan(blueprint, player, options)
    if type(blueprint) ~= "table" then
        return nil, "blueprint_missing"
    end
    options = type(options) == "table" and options or {}
    local originX
    local originY
    local originZ
    local originActor = options.leadActor or player
    if options.origin then
        originX = integer(options.origin.x)
        originY = integer(options.origin.y)
        originZ = integer(options.origin.z)
    else
        originX, originY, originZ = actorPosition(originActor)
    end
    if not originX or not originY or not originZ then
        return nil, "anchor_origin_unavailable"
    end

    local explicitOrientation = type(options.orientation) == "table"
    local orientation = options.orientation
    if not explicitOrientation then
        orientation = Anchors.ReadForward(originActor)
        if not orientation then
            orientation = { x = 0, y = 1, rightX = -1, rightY = 0 }
        end
    end
    local forwardX = integer(orientation.x)
    local forwardY = integer(orientation.y)
    local rightX = integer(orientation.rightX)
    local rightY = integer(orientation.rightY)
    if not forwardX or not forwardY or not rightX or not rightY then
        return nil, "anchor_orientation_invalid"
    end

    local primaryPlan, primaryErr = projectPlan(
        blueprint, originX, originY, originZ,
        forwardX, forwardY, rightX, rightY
    )
    if not primaryPlan then return nil, primaryErr end

    -- When world squares are loaded and orientation was not explicitly locked,
    -- auto-rotate or shift up to 3 tiles to find an open, unblocked rendezvous
    -- so actors never try to pathfind through walls or counters.
    local cell = options.cell or (type(getCell) == "function" and getCell() or nil)
    if explicitOrientation or options.disableAutoRendezvous == true
        or not cell or type(cell.getGridSquare) ~= "function"
    then
        return primaryPlan
    end
    local originSq = cell:getGridSquare(originX, originY, originZ)
    if isPlanWalkable(primaryPlan, cell, originSq) then
        return primaryPlan
    end

    local orientations = buildCandidateOrientations(
        forwardX, forwardY, rightX, rightY)
    for oIdx = 2, #orientations do
        local o = orientations[oIdx]
        local alt = projectPlan(
            blueprint, originX, originY, originZ,
            o.x, o.y, o.rightX, o.rightY
        )
        if alt and isPlanWalkable(alt, cell, originSq) then
            alt.rendezvousAdjusted = "rotated"
            return alt
        end
    end

    local searchRadius = math.max(1, math.min(4,
        math.floor(tonumber(options.searchRadius)
            or tonumber(blueprint.anchorFrame
                and blueprint.anchorFrame.searchRadius)
            or 3)))
    for ring = 1, searchRadius do
        for dx = -ring, ring do
            for dy = -ring, ring do
                if math.max(math.abs(dx), math.abs(dy)) == ring then
                    for oIdx = 1, #orientations do
                        local o = orientations[oIdx]
                        local shifted = projectPlan(
                            blueprint, originX + dx, originY + dy, originZ,
                            o.x, o.y, o.rightX, o.rightY
                        )
                        if shifted and isPlanWalkable(shifted, cell, originSq) then
                            shifted.rendezvousAdjusted = "shifted"
                            return shifted
                        end
                    end
                end
            end
        end
    end
    return primaryPlan
end

function Anchors.WorldPoint(target)
    if type(target) ~= "table" then return nil end
    return {
        x = tonumber(target.worldX) or (tonumber(target.x) or 0) + 0.5,
        y = tonumber(target.worldY) or (tonumber(target.y) or 0) + 0.5,
        z = tonumber(target.worldZ) or tonumber(target.z) or 0,
    }
end

function Anchors.IsAt(actor, target, tolerance)
    if not actor or type(target) ~= "table"
        or not actor.getX or not actor.getY
    then
        return false, "actor_position_api_unavailable"
    end
    local x = tonumber(actor:getX())
    local y = tonumber(actor:getY())
    local z = tonumber(actor.getZ and actor:getZ() or target.z)
    local point = Anchors.WorldPoint(target)
    if not x or not y or not z or not point then
        return false, "actor_position_invalid"
    end
    local dz = math.abs(z - point.z)
    local dx = x - point.x
    local dy = y - point.y
    local allowed = tonumber(tolerance) or 0.75
    return dz < 0.5 and (dx * dx) + (dy * dy) <= allowed * allowed
end

function Anchors.IsFacing(actor, target, tolerance)
    if not actor or type(target) ~= "table"
        or not actor.getX or not actor.getY
        or not actor.getForwardDirectionX
        or not actor.getForwardDirectionY
    then
        return false, "facing_observation_unavailable"
    end
    local targetPoint = Anchors.WorldPoint(target)
    local dx = targetPoint.x - tonumber(actor:getX())
    local dy = targetPoint.y - tonumber(actor:getY())
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.15 then return true, 1.0 end
    local forwardX = tonumber(actor:getForwardDirectionX())
    local forwardY = tonumber(actor:getForwardDirectionY())
    if not forwardX or not forwardY then
        return false, "facing_observation_invalid"
    end
    local dot = (forwardX * dx + forwardY * dy) / length
    return dot >= (tonumber(tolerance) or 0.70), dot
end

function Anchors.GetGridPreview(blueprint)
    local result = {}
    local frame = blueprint and blueprint.anchorFrame or {}
    local anchors = frame and frame.anchors or {}
    local id
    local anchor
    for id, anchor in pairs(anchors) do
        result[#result + 1] = {
            id = id,
            right = tonumber(anchor.right) or 0,
            forward = tonumber(anchor.forward) or 0,
            z = tonumber(anchor.z) or 0,
            faceTarget = anchor.faceTarget,
        }
    end
    table.sort(result, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return result
end

return Anchors
