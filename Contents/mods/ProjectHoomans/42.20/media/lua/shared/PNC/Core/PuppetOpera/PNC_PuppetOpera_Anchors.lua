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

function Anchors.BuildPlan(blueprint, player, options)
    if type(blueprint) ~= "table" then
        return nil, "blueprint_missing"
    end
    options = type(options) == "table" and options or {}
    local originX
    local originY
    local originZ
    if options.origin then
        originX = integer(options.origin.x)
        originY = integer(options.origin.y)
        originZ = integer(options.origin.z)
    else
        originX, originY, originZ = actorPosition(player)
    end
    if not originX or not originY or not originZ then
        return nil, "anchor_origin_unavailable"
    end

    local orientation = options.orientation
    local orientationError
    if type(orientation) ~= "table" then
        orientation, orientationError = Anchors.ReadForward(player)
        if not orientation then return nil, orientationError end
    end
    local forwardX = integer(orientation.x)
    local forwardY = integer(orientation.y)
    local rightX = integer(orientation.rightX)
    local rightY = integer(orientation.rightY)
    if not forwardX or not forwardY or not rightX or not rightY then
        return nil, "anchor_orientation_invalid"
    end

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
        actors = {},
        occupied = {},
    }

    local actorID
    local actorDefinition
    local anchor
    local x
    local y
    local z
    local key
    for actorID, actorDefinition in pairs(actors) do
        anchor = anchors[actorDefinition.anchor]
        if not anchor then
            return nil, "anchor_missing:" .. tostring(actorID)
        end
        x = originX + rightX * (tonumber(anchor.right) or 0)
            + forwardX * (tonumber(anchor.forward) or 0)
        y = originY + rightY * (tonumber(anchor.right) or 0)
            + forwardY * (tonumber(anchor.forward) or 0)
        z = originZ + (tonumber(anchor.z) or 0)
        x, y, z = integer(x), integer(y), integer(z)
        key = targetKey(x, y, z)
        if plan.occupied[key] then
            return nil, "anchors_overlap:" .. tostring(actorID)
        end
        plan.occupied[key] = actorID
        plan.actors[actorID] = {
            id = actorID,
            anchor = actorDefinition.anchor,
            x = x,
            y = y,
            z = z,
            worldX = x + 0.5,
            worldY = y + 0.5,
            worldZ = z,
            faceTarget = anchor.faceTarget,
        }
    end
    return plan
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
    if length < 0.0001 then return false, "facing_target_too_close" end
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
