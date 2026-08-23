-- Interaction provider: window open, smash, and climb execution.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles

local function rejectClimbStart(context, actionKey, objectKey)
    if Internal.isRepeatedTraversalAttempt
        and Internal.isRepeatedTraversalAttempt(
            context.lane,
            actionKey,
            context.fromX,
            context.fromY,
            context.fromZ,
            context.lane and context.lane.goalRevision or 0,
            context.now
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_repeat_same_side",
            "object=" .. tostring(objectKey or "nil")
        )
        return true
    end
    if Internal.shouldSuppressSpecialAction(
        context.lane, actionKey, context.now
    ) then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_climb_special_cooldown",
            "object=" .. tostring(objectKey or "nil")
        )
        return true
    end
    return false
end

local function resolveClimbDestination(context, object, actionKey, objectKey)
    local destSquare
    if context.blockedFromSquare and context.blockedSquare
        and TraversalQuery and TraversalQuery.GetPassageBetween
        and TraversalQuery.GetPassageBetween(
            context.blockedFromSquare,
            context.blockedSquare
        ) == object
    then
        destSquare = context.blockedSquare
    elseif object.getOppositeSquare then
        destSquare = Internal.passageWindowDestination(
            object, context.actorSquare
        )
    end
    if not destSquare or not Internal.isSquareWalkable(
        destSquare:getX() + 0.5,
        destSquare:getY() + 0.5,
        destSquare:getZ()
    ) then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_dest_blocked",
            "object=" .. tostring(objectKey or "nil")
        )
        return nil, nil, nil, nil, true
    end

    local destX = destSquare:getX() + 0.5
    local destY = destSquare:getY() + 0.5
    local destZ = destSquare:getZ()
    if object ~= context.blockedPassage
        and not Internal.passageImprovesGoalDistance(
            context.fromX,
            context.fromY,
            destX,
            destY,
            context.goalX,
            context.goalY
        )
    then
        if Internal.noteTraversalAttempt then
            Internal.noteTraversalAttempt(
                context.lane,
                "window_climb",
                actionKey,
                context.fromX,
                context.fromY,
                context.fromZ,
                destX,
                destY,
                destZ,
                context.now,
                context.lane and context.lane.goalRevision or 0
            )
        end
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_dest_not_progressive",
            "object=" .. tostring(objectKey or "nil")
                .. " to=" .. Internal.describeSquare(destSquare)
        )
        return nil, nil, nil, nil, true
    end
    return destSquare, destX, destY, destZ, false
end

local function beginWindowClimb(
    context, object, objectSquare, objectKey, actionKey,
    destSquare, destX, destY, destZ
)
    local profile = TraversalProfiles and TraversalProfiles.Resolve
        and TraversalProfiles.Resolve(
            "window_climb",
            {
                record = context.record,
                body = context.zombie,
                lane = context.lane,
                obstacle = object,
            },
            "default"
        ) or {}
    if not Internal.beginTraversalAction
        or not Internal.beginTraversalAction(
            context.zombie,
            context.record,
            context.lane,
            {
                kind = "window_climb",
                anim = profile.anim or "PNC_ClimbWindow",
                fromX = context.fromX,
                fromY = context.fromY,
                fromZ = context.fromZ,
                toX = destX,
                toY = destY,
                toZ = destZ,
                travelDurationMs = tonumber(profile.travelDurationMs) or 700,
                finishHoldMs = tonumber(profile.finishHoldMs) or 320,
            }
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_runtime_unavailable",
            "object=" .. tostring(objectKey or "nil")
        )
        return false, nil, true
    end
    Internal.rememberSpecialAction(context.lane, actionKey, context.now)
    if Internal.noteTraversalAttempt then
        Internal.noteTraversalAttempt(
            context.lane,
            "window_climb",
            actionKey,
            context.fromX,
            context.fromY,
            context.fromZ,
            destX,
            destY,
            destZ,
            context.now,
            context.lane and context.lane.goalRevision or 0
        )
    end
    Internal.logMoveDebug(
        context.record,
        context.zombie,
        context.lane,
        "window_climb",
        "window_climb",
        "from=" .. context.fromPoint
            .. " object=" .. Internal.describeSquare(objectSquare)
            .. " to=" .. Internal.describeSquare(destSquare)
            .. " goal=" .. Internal.describePoint(
                context.goalX, context.goalY, context.goalZ
            )
    )
    return true, "window_climb", true
end

local function tryClimb(context, object, objectSquare, objectKey)
    if not object:canClimbThrough(context.zombie) then
        return nil, nil, false
    end
    local actionKey = "window_climb:"
        .. Internal.describeSquare(objectSquare)
    if rejectClimbStart(context, actionKey, objectKey) then
        return false, nil, true
    end
    local destSquare, destX, destY, destZ, rejected =
        resolveClimbDestination(context, object, actionKey, objectKey)
    if rejected then return false, nil, true end
    return beginWindowClimb(
        context,
        object,
        objectSquare,
        objectKey,
        actionKey,
        destSquare,
        destX,
        destY,
        destZ
    )
end

function Internal.tryWindowPassageCandidate(context, object, candidate)
    if not instanceof(object, "IsoWindow") then return nil, nil, false end
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
            "traversal_rejected", "window_not_ahead",
            "object=" .. tostring(objectKey or "nil")
        )
        return nil, nil, false
    end
    if not objectSquare then return nil, nil, false end

    local handled, reason, decided = Internal.tryWindowBreach(
        context, object, objectSquare, objectKey
    )
    if decided then return handled, reason, true end
    return tryClimb(context, object, objectSquare, objectKey)
end
