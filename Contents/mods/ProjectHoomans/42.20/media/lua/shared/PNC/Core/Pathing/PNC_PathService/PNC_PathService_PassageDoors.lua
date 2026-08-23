-- Door-specific passage execution.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery

local function isDoor(object)
    return instanceof(object, "IsoDoor")
        or (instanceof(object, "IsoThumpable")
            and object.isDoor and object:isDoor() == true)
end

local function rememberDoorHold(context, duration)
    if Internal.MotionHints and Internal.MotionHints.RememberHold then
        Internal.MotionHints.RememberHold(
            context.lane,
            context.zombie:getX(),
            context.zombie:getY(),
            context.zombie:getZ(),
            context.now,
            duration,
            { kind = "door_open", profile = context.lane.motionProfile }
        )
    end
end

function Internal.tryBlockedDoorPassage(context)
    local object = context.blockedPassage
    if not object or not TraversalQuery or not TraversalQuery.IsDoor
        or not TraversalQuery.IsDoor(object)
    then
        return nil, nil, false
    end
    local objectSquare = object.getSquare and object:getSquare()
        or context.blockedSquare
    local actionKey = "door:" .. Internal.describeSquare(objectSquare)
    if not Internal.shouldSuppressSpecialAction(
        context.lane, actionKey, context.now
    ) and Internal.openDoorForNPC(context.zombie, object) then
        Internal.rememberSpecialAction(context.lane, actionKey, context.now)
        rememberDoorHold(context, 180)
        Internal.logMoveDebug(
            context.record,
            context.zombie,
            context.lane,
            "door_open",
            "blocked_passage",
            "from=" .. context.fromPoint
                .. " object=" .. Internal.describeSquare(objectSquare)
                .. " goal=" .. Internal.describePoint(
                    context.goalX, context.goalY, context.goalZ
                )
        )
        return true, "door_open", true
    end
    return nil, nil, false
end

function Internal.tryDoorPassageCandidate(context, object, candidate)
    if not isDoor(object) then return nil, nil, false end
    local zombie = context.zombie
    local facing = zombie.isFacingObject
        and zombie:isFacingObject(object, 0.5)
    if not facing and object == context.blockedPassage
        and zombie.faceThisObject
    then
        zombie:faceThisObject(object)
        facing = true
    end
    if not facing then return nil, nil, false end

    local objectSquare = object:getSquare()
    local objectKey = Internal.passageObstacleSquareKey(objectSquare)
    if object ~= context.blockedPassage
        and not (context.collided and candidate.index <= 4)
        and not Internal.passageIsObstacleAhead(
            zombie,
            objectSquare,
            context.goalX,
            context.goalY,
            candidate.x + 0.5,
            candidate.y + 0.5
        )
    then
        Internal.logTraversalReject(
            context.record, zombie, context.lane,
            "traversal_rejected", "door_not_ahead",
            "object=" .. tostring(objectKey or "nil")
        )
        objectSquare = nil
    end
    if objectSquare and object ~= context.blockedPassage
        and not (context.collided and candidate.index <= 4)
        and not Internal.passageImprovesGoalDistance(
            context.fromX,
            context.fromY,
            objectSquare:getX() + 0.5,
            objectSquare:getY() + 0.5,
            context.goalX,
            context.goalY
        )
    then
        Internal.logTraversalReject(
            context.record, zombie, context.lane,
            "traversal_rejected", "door_not_progressive",
            "object=" .. tostring(objectKey or "nil")
        )
        objectSquare = nil
    end
    if not objectSquare then return nil, nil, false end

    local actionKey = "door:" .. Internal.describeSquare(objectSquare)
    if Internal.shouldSuppressSpecialAction(
        context.lane, actionKey, context.now
    ) then
        Internal.logTraversalReject(
            context.record, zombie, context.lane,
            "traversal_rejected", "door_special_cooldown",
            "object=" .. tostring(objectKey or "nil")
        )
        return false, nil, true
    end
    if Internal.openDoorForNPC(zombie, object) then
        Internal.rememberSpecialAction(context.lane, actionKey, context.now)
        rememberDoorHold(context, 180)
        Internal.logMoveDebug(
            context.record, zombie, context.lane,
            "door_open", "door_open",
            "from=" .. context.fromPoint
                .. " object=" .. Internal.describeSquare(objectSquare)
                .. " goal=" .. Internal.describePoint(
                    context.goalX, context.goalY, context.goalZ
                )
        )
        return true, "door_open", true
    end
    Internal.logTraversalReject(
        context.record, zombie, context.lane,
        "traversal_rejected", "door_open_failed_or_locked",
        "object=" .. tostring(objectKey or "nil")
    )
    return nil, nil, false
end

