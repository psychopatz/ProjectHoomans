-- Interaction provider: shared probing geometry and special-action suppression policy.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery

local function hasPrefix(value, prefix)
    return string.sub(tostring(value or ""), 1, #prefix) == prefix
end

local function normalize2D(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then return nil, nil end
    return dx / len, dy / len
end

local function sameSquare(left, right)
    return left ~= nil and right ~= nil
        and left:getX() == right:getX()
        and left:getY() == right:getY()
        and left:getZ() == right:getZ()
end

local function indexField(object, key)
    return object[key]
end

function Internal.passageMethodReturnsTrue(object, names)
    local method
    local ok
    local value
    if not object then return false end
    for i = 1, #names do
        -- Probe compatibly with zero closure allocation: names differ between
        -- PZ point releases and an unknown member may resolve to nil or raise.
        ok, method = pcall(indexField, object, names[i])
        if ok and type(method) == "function" then
            ok, value = pcall(method, object)
            if ok and value == true then
                return true
            end
        end
    end
    return false
end

function Internal.passageImprovesGoalDistance(
    fromX, fromY, toX, toY, goalX, goalY
)
    return Internal.Core.Distance(toX, toY, goalX, goalY) + 0.05
        < Internal.Core.Distance(fromX, fromY, goalX, goalY)
end

function Internal.passageObstacleSquareKey(square)
    return square and ("sq:" .. Internal.describeSquare(square)) or nil
end

function PNC.PathService.PassageWindowDestination(object, actorSquare)
    local objectSquare = object and object.getSquare
        and object:getSquare() or nil
    local oppositeSquare = object and object.getOppositeSquare
        and object:getOppositeSquare() or nil
    if sameSquare(actorSquare, objectSquare) then return oppositeSquare end
    if sameSquare(actorSquare, oppositeSquare) then return objectSquare end
    return nil
end
Internal.passageWindowDestination = PNC.PathService.PassageWindowDestination

function Internal.windowDestinationForContext(context, object)
    if context and context.blockedFromSquare and context.blockedSquare
        and TraversalQuery and TraversalQuery.GetPassageBetween
        and TraversalQuery.GetPassageBetween(
            context.blockedFromSquare,
            context.blockedSquare
        ) == object
    then
        return context.blockedSquare
    end
    return Internal.passageWindowDestination(
        object,
        context and context.actorSquare or nil
    )
end

local function isCampAnchorMovement(context)
    local lane = context and context.lane or nil
    local record = context and context.record or nil
    if lane and lane.intentReason == "camp_anchor" then
        return true
    end
    return record
        and record.activeBehavior == "AtCamp:returning"
        and record.orderSpec
        and tostring(record.orderSpec.kind or "") == "camp"
        or false
end

local function isFollowOwnerMovement(context)
    local lane = context and context.lane or nil
    local record = context and context.record or nil
    local reason = lane and lane.intentReason or nil
    if hasPrefix(reason, "follow_owner") then return true end
    if reason == "owner_missing_return_anchor"
        and record and record.orderSpec
        and tostring(record.orderSpec.kind or "") == "follow"
    then
        return true
    end
    return hasPrefix(lane and lane.requestedByBehavior, "FollowOwner:moving")
        or false
end

local function protectedMovementKind(context)
    if isCampAnchorMovement(context) then return "camp" end
    if isFollowOwnerMovement(context) then return "follow" end
    return nil
end

local function resolveProtectedGoalState(context, movementKind, goalSquare)
    local record = context and context.record or nil
    local common
    local owner
    local ownerSquare
    local ownerState
    if movementKind ~= "follow" then
        return TraversalQuery.GetInteriorState(goalSquare)
    end
    common = PNC.BehaviorCommon
    owner = common and common.GetOwner and common.GetOwner(record) or nil
    ownerSquare = owner and owner.getSquare and owner:getSquare() or nil
    ownerState = TraversalQuery.GetInteriorState(ownerSquare)
    if ownerState ~= nil then return ownerState end
    return TraversalQuery.GetInteriorState(goalSquare)
end

-- Hoomans owns the final passage decision, including native-path handoff. An
-- indoor camp/follow goal may be approached from outside, but once the NPC is
-- inside it must not voluntarily leave through an exterior window.
function Internal.isInteriorBoundaryBlocked(context, object)
    local goalSquare
    local goalIndoor
    local fromIndoor
    local destinationSquare
    local destinationIndoor
    local movementKind = protectedMovementKind(context)
    if not movementKind
        or not TraversalQuery
        or not TraversalQuery.GetSquare
        or not TraversalQuery.GetInteriorState
    then
        return false, nil
    end
    goalSquare = TraversalQuery.GetSquare(
        context.goalX,
        context.goalY,
        context.goalZ,
        context.cell
    )
    goalIndoor = resolveProtectedGoalState(
        context,
        movementKind,
        goalSquare
    )
    if goalIndoor ~= true then
        return false, nil
    end
    fromIndoor = TraversalQuery.GetInteriorState(context.actorSquare)
    destinationSquare = Internal.windowDestinationForContext(
        context,
        object
    )
    destinationIndoor = TraversalQuery.GetInteriorState(destinationSquare)
    if fromIndoor == true and destinationIndoor == false then
        return true, movementKind == "follow"
            and "follow_owner_indoor_boundary"
            or "camp_indoor_boundary"
    end
    return false, nil
end

-- Compatibility name retained for existing diagnostics and callers.
function Internal.isCampIndoorBoundary(context, object)
    return Internal.isInteriorBoundaryBlocked(context, object)
end

function Internal.logTraversalReject(
    record, zombie, lane, event, reason, extra
)
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        event or "traversal_rejected",
        reason or "rejected",
        extra or ""
    )
end

function Internal.passageFindFenceAhead(cell, zombie, goalX, goalY)
    if TraversalQuery and TraversalQuery.FindFenceAhead then
        return TraversalQuery.FindFenceAhead(zombie, goalX, goalY, cell)
    end
    return nil
end

function Internal.passageIsObstacleAhead(
    zombie, square, goalX, goalY, fallbackX, fallbackY
)
    if not zombie then return false end
    local goalDirX, goalDirY = normalize2D(
        (tonumber(goalX) or zombie:getX()) - zombie:getX(),
        (tonumber(goalY) or zombie:getY()) - zombie:getY()
    )
    if not goalDirX then return true end
    local objectX = square and (square:getX() + 0.5) or fallbackX
    local objectY = square and (square:getY() + 0.5) or fallbackY
    local obstacleDirX, obstacleDirY = normalize2D(
        (tonumber(objectX) or zombie:getX()) - zombie:getX(),
        (tonumber(objectY) or zombie:getY()) - zombie:getY()
    )
    if not obstacleDirX and fallbackX and fallbackY then
        obstacleDirX, obstacleDirY = normalize2D(
            fallbackX - zombie:getX(),
            fallbackY - zombie:getY()
        )
    end
    if not obstacleDirX then return true end
    return ((goalDirX * obstacleDirX)
        + (goalDirY * obstacleDirY)) >= 0.25
end

function Internal.rememberSpecialAction(lane, key, now)
    if not lane then return end
    lane.lastSpecialActionKey = key
    lane.lastSpecialActionAt = now
end

function Internal.shouldSuppressSpecialAction(lane, key, now)
    if not lane or not key then return false end
    return lane.lastSpecialActionKey == key
        and (now - (tonumber(lane.lastSpecialActionAt) or 0))
            < Internal.SPECIAL_ACTION_COOLDOWN_MS
end

function Internal.isDoorCollision(zombie)
    if not zombie then return false end
    local method = zombie.isCollidedWithDoor
    if type(method) == "function" then return method(zombie) == true end
    return Internal.passageMethodReturnsTrue(
        zombie,
        { "isCollidedThisFrame", "isCollided" }
    )
end

local PASSAGE_RESERVATION_MAX_TTL_MS = 2000
local PASSAGE_RESERVATION_PRUNE_THRESHOLD = 64

Internal.PassageReservations = Internal.PassageReservations or {}

local function prunePassageReservations(now)
    local reservations = Internal.PassageReservations
    local count = 0
    local key
    local entry
    for key, entry in pairs(reservations) do
        if not entry or (now > 0 and (tonumber(entry.expiresAt) or 0) <= now) then
            reservations[key] = nil
        else
            count = count + 1
        end
    end
    if count >= PASSAGE_RESERVATION_PRUNE_THRESHOLD then
        Internal.PassageReservations = {}
    end
end

function Internal.IsPassageReservedByOther(key, ownerId, now)
    if not key then return false end
    local reservations = Internal.PassageReservations
    local entry = reservations[key]
    if not entry then return false end
    local checkNow = tonumber(now) or 0
    if checkNow > 0 and (tonumber(entry.expiresAt) or 0) <= checkNow then
        reservations[key] = nil
        return false
    end
    if entry.ownerLane ~= nil
        and entry.ownerLane.traversalAction == nil
        and entry.ownerLane.vanillaFenceAction == nil
    then
        reservations[key] = nil
        return false
    end
    return entry.ownerId ~= nil and entry.ownerId ~= ownerId
end

function Internal.ReservePassage(key, ownerId, now, ttlMs, ownerLane)
    if not key or not ownerId then return false end
    local checkNow = tonumber(now) or 0
    local duration = math.min(
        PASSAGE_RESERVATION_MAX_TTL_MS,
        math.max(100, tonumber(ttlMs) or 1200)
    )
    local reservations = Internal.PassageReservations
    local existing = reservations[key]
    if existing then
        existing.ownerId = ownerId
        existing.expiresAt = checkNow + duration
        existing.ownerLane = ownerLane
        return true
    end
    local count = 0
    for _ in pairs(reservations) do
        count = count + 1
        if count >= PASSAGE_RESERVATION_PRUNE_THRESHOLD then
            prunePassageReservations(checkNow)
            reservations = Internal.PassageReservations
            break
        end
    end
    reservations[key] = {
        ownerId = ownerId,
        expiresAt = checkNow + duration,
        ownerLane = ownerLane,
    }
    return true
end

function Internal.ReleasePassageReservation(key, ownerId)
    if not key then return end
    local reservations = Internal.PassageReservations
    local entry = reservations[key]
    if not entry then return end
    if ownerId == nil or entry.ownerId == ownerId then
        reservations[key] = nil
    end
end

function Internal.ResetPassageReservations()
    Internal.PassageReservations = {}
end

function Internal.holdQueuedPassage(context, ownerMode, reason, keyText)
    local lane = context and context.lane or nil
    local now = context and context.now or 0
    if lane then
        lane.ownerMode = ownerMode
        lane.specialMoveUntil = now + 220
        lane.lastProgressAt = now
        lane.lastGoalProgressAt = now
        lane.lastIssueAt = now
    end
    Internal.logMoveDebug(
        context and context.record or nil,
        context and context.zombie or nil,
        lane,
        "passage_queued",
        reason,
        "object=" .. tostring(keyText or "nil")
    )
    return true, "passage_queued", true
end

function Internal.releaseLanePassageReservation(record, zombie, lane)
    local key = lane and lane.reservedPassageKey or nil
    if not key then return end
    Internal.ReleasePassageReservation(key, (record and record.id) or zombie)
    lane.reservedPassageKey = nil
end
