-- Fence probing and traversal-action creation.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles

local function resolveFence(context)
    local blockedFence
    local blockedFenceTall
    if context.blockedFromSquare and context.blockedSquare
        and TraversalQuery and TraversalQuery.GetFenceBetween
    then
        blockedFence, blockedFenceTall = TraversalQuery.GetFenceBetween(
            context.blockedFromSquare,
            context.blockedSquare
        )
    end
    if blockedFence then
        return {
            object = blockedFence,
            tall = blockedFenceTall == true,
            square = blockedFence.getSquare and blockedFence:getSquare()
                or context.blockedFromSquare,
            fromSquare = context.blockedFromSquare,
            landingSquare = context.blockedSquare,
        }, true
    end
    return Internal.passageFindFenceAhead(
        context.cell,
        context.zombie,
        context.goalX,
        context.goalY
    ), false
end

local function resolveFromSquare(context, fence)
    local square = fence.fromSquare or context.blockedFromSquare
    if not square and TraversalQuery and TraversalQuery.GetSquare then
        square = TraversalQuery.GetSquare(
            context.fromX,
            context.fromY,
            context.fromZ,
            context.cell
        )
    end
    return square
end

local function rejectFence(
    context, fence, exactBlockedEdge, fromSquare,
    landingX, landingY, fenceKey
)
    if TraversalQuery and TraversalQuery.IsFenceApproachReady
        and not TraversalQuery.IsFenceApproachReady(
            context.fromX,
            context.fromY,
            fromSquare,
            fence.landingSquare,
            fence.dirX,
            fence.dirY
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_not_ready",
            "from=" .. tostring(
                fromSquare and Internal.describeSquare(fromSquare) or "nil"
            )
        )
        return true
    end
    if not exactBlockedEdge
        and not Internal.passageImprovesGoalDistance(
            context.fromX,
            context.fromY,
            landingX,
            landingY,
            context.goalX,
            context.goalY
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_not_progressive",
            "object=" .. tostring(fenceKey)
        )
        return true
    end
    if Internal.isRepeatedTraversalAttempt
        and Internal.isRepeatedTraversalAttempt(
            context.lane,
            fenceKey,
            context.fromX,
            context.fromY,
            context.fromZ,
            context.lane and context.lane.goalRevision or 0,
            context.now
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_repeat_same_side",
            "object=" .. tostring(fenceKey)
        )
        return true
    end
    if Internal.shouldSuppressSpecialAction(
        context.lane, fenceKey, context.now
    ) then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_special_cooldown",
            "object=" .. tostring(fenceKey)
        )
        return true
    end
    return false
end

local function beginFenceAction(
    context, fence, fromSquare, landingX, landingY, landingZ, fenceKey
)
    local profile = TraversalProfiles and TraversalProfiles.Resolve
        and TraversalProfiles.Resolve(
            "fence_climb",
            {
                record = context.record,
                body = context.zombie,
                lane = context.lane,
                obstacle = fence.object,
                tall = fence.tall == true,
            },
            fence.tall == true and "tall" or "low"
        ) or {}
    local duration = tonumber(profile.travelDurationMs)
        or (fence.tall == true and 900 or 600)
    local started = Internal.beginTraversalAction
        and Internal.beginTraversalAction(
            context.zombie,
            context.record,
            context.lane,
            {
                kind = "fence_climb",
                anim = profile.anim or (
                    fence.tall == true
                    and "PNC_ClimbFenceTall" or "PNC_ClimbFence"
                ),
                fromX = context.fromX,
                fromY = context.fromY,
                fromZ = context.fromZ,
                fromSquare = fromSquare,
                toSquare = fence.landingSquare,
                toX = landingX,
                toY = landingY,
                toZ = landingZ,
                travelDurationMs = duration,
                startAnim = fence.tall ~= true and profile.startAnim or nil,
                endAnim = fence.tall ~= true and profile.endAnim or nil,
                upDurationMs = fence.tall ~= true
                    and profile.upDurationMs or nil,
                crossingDurationMs = fence.tall ~= true
                    and profile.crossingDurationMs or nil,
                finishHoldMs = tonumber(profile.finishHoldMs)
                    or (fence.tall == true and 420 or 320),
            }
        )
    if started then return true end
    Internal.logTraversalReject(
        context.record, context.zombie, context.lane,
        "traversal_rejected", "fence_runtime_unavailable",
        "object=" .. tostring(fenceKey)
    )
    return false
end

local function recordFenceAction(
    context, fence, fenceKey, landingX, landingY, landingZ
)
    Internal.rememberSpecialAction(context.lane, fenceKey, context.now)
    if Internal.noteTraversalAttempt then
        Internal.noteTraversalAttempt(
            context.lane,
            "fence_climb",
            fenceKey,
            context.fromX,
            context.fromY,
            context.fromZ,
            landingX,
            landingY,
            landingZ,
            context.now,
            context.lane and context.lane.goalRevision or 0
        )
    end
    Internal.logMoveDebug(
        context.record,
        context.zombie,
        context.lane,
        "fence_climb",
        "fence_climb",
        "from=" .. context.fromPoint
            .. " object=" .. Internal.describeSquare(fence.square)
            .. " to=" .. Internal.describeSquare(fence.landingSquare)
            .. " goal=" .. Internal.describePoint(
                context.goalX, context.goalY, context.goalZ
            )
    )
end

function Internal.tryFencePassage(context)
    local fence, exactBlockedEdge = resolveFence(context)
    if not fence or not fence.landingSquare then
        return nil, nil, false
    end
    local fromSquare = resolveFromSquare(context, fence)
    local landingX = fence.landingSquare:getX() + 0.5
    local landingY = fence.landingSquare:getY() + 0.5
    local landingZ = fence.landingSquare:getZ()
    local fenceKey = "fence:" .. Internal.describeSquare(fence.square)
    if rejectFence(
        context,
        fence,
        exactBlockedEdge,
        fromSquare,
        landingX,
        landingY,
        fenceKey
    ) then
        return false, nil, true
    end
    if not beginFenceAction(
        context,
        fence,
        fromSquare,
        landingX,
        landingY,
        landingZ,
        fenceKey
    ) then
        return false, nil, true
    end
    recordFenceAction(
        context, fence, fenceKey, landingX, landingY, landingZ
    )
    return true, "fence_climb", true
end
