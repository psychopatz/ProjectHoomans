-- Interaction provider: fence probing and traversal-action creation.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles
local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core
local VANILLA_FENCE_TIMEOUT_MS = 4000
local VANILLA_FENCE_START_GRACE_MS = 300

local function actionStateName(zombie)
    if not zombie or not zombie.getActionStateName then return "" end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

local function fenceDirection(fromSquare, landingSquare)
    local dx = landingSquare and fromSquare
        and landingSquare:getX() - fromSquare:getX() or 0
    local dy = landingSquare and fromSquare
        and landingSquare:getY() - fromSquare:getY() or 0
    if not IsoDirections then return nil end
    if dx > 0 then return IsoDirections.E end
    if dx < 0 then return IsoDirections.W end
    if dy > 0 then return IsoDirections.S end
    if dy < 0 then return IsoDirections.N end
    return nil
end

local function enterVanillaFenceState(zombie, direction)
    local result
    if Core and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(zombie)
    then
        -- Managed NPC carriers are IsoZombie instances without player
        -- BodyDamage. Their traversal must stay inside the PNC action runtime.
        return false
    end
    if zombie and zombie.climbOverFence then
        result = zombie:climbOverFence(direction)
        if result ~= false
            and actionStateName(zombie) == "climbfence"
        then
            return true
        end
    end
    if ClimbOverFenceState
        and ClimbOverFenceState.instance
        and zombie
        and zombie.changeState
    then
        local climbState = ClimbOverFenceState.instance()
        if climbState and climbState.setParams then
            climbState:setParams(zombie, direction)
            zombie:changeState(climbState)
            return true
        end
    end
    return result ~= false and zombie ~= nil
end

local function fenceCrossed(zombie, action)
    if TraversalQuery and TraversalQuery.IsFenceCrossed then
        return TraversalQuery.IsFenceCrossed(
            zombie and zombie:getX() or nil,
            zombie and zombie:getY() or nil,
            zombie and zombie:getZ() or nil,
            action and action.fromSquare or nil,
            action and action.toSquare or nil
        )
    end
    return zombie ~= nil
        and action ~= nil
        and action.toSquare ~= nil
        and math.floor(zombie:getX()) == action.toSquare:getX()
        and math.floor(zombie:getY()) == action.toSquare:getY()
        and math.floor(zombie:getZ()) == action.toSquare:getZ()
end

local function resolveFence(context)
    local blockedFence
    local blockedFenceTall
    -- blockedFromSquare/blockedSquare can also be populated by the
    -- goal-directed passage probe.  That probe is only a candidate, not a
    -- collision report.  Treat the edge as exact only when the movement
    -- lane recorded the failed step itself.
    local hasBlockedStep = context.lane
        and context.lane.blockedStepToX ~= nil
    if hasBlockedStep
        and context.blockedFromSquare and context.blockedSquare
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
    -- The scripted traversal becomes the movement owner at this point. A
    -- native engine route may still have path2 attached when this branch was
    -- reached through a stall/recovery callback; invalidate that route
    -- before the bump starts so WalkTowardState cannot keep consuming it.
    if PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.Invalidate
    then
        PNC.EnginePathPlanner.Invalidate(
            context.record,
            "fence_traversal_handoff",
            context.zombie
        )
    end
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
                transitionSettleMs = fence.tall ~= true and 0 or nil,
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

local function beginVanillaFenceAction(
    context, fence, fromSquare, landingX, landingY, landingZ, fenceKey
)
    local direction
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        return false
    end
    direction = fenceDirection(fromSquare, fence.landingSquare)
    if not direction
        or not enterVanillaFenceState(context.zombie, direction)
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_vanilla_state_unavailable",
            "object=" .. tostring(fenceKey)
        )
        return false
    end
    local now = context.now
    local action = {
        kind = "fence_climb_vanilla",
        key = "fence_vanilla:" .. tostring(fenceKey)
            .. ":" .. tostring(now),
        object = fence.object,
        fenceKey = fenceKey,
        fromSquare = fromSquare,
        toSquare = fence.landingSquare,
        startedAt = now,
        startGraceUntil = now + VANILLA_FENCE_START_GRACE_MS,
        finishAt = now + VANILLA_FENCE_TIMEOUT_MS,
        fromX = context.fromX,
        fromY = context.fromY,
        fromZ = context.fromZ,
        toX = landingX,
        toY = landingY,
        toZ = landingZ,
    }
    context.lane.vanillaFenceAction = action
    context.lane.specialMoveUntil = action.finishAt
    context.lane.ownerMode = "fence_climb"
    context.lane.lastProgressAt = now
    context.lane.lastIssueAt = now
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(
            context.zombie, false, true
        )
    end
    return true
end

function Internal.updateVanillaFenceAction(zombie, record, lane, now)
    local action = lane and lane.vanillaFenceAction or nil
    local actionState
    if not action then return false, nil end
    actionState = actionStateName(zombie)
    if fenceCrossed(zombie, action) then
        lane.vanillaFenceAction = nil
        lane.specialMoveUntil = 0
        lane.ownerMode = "fake_locomotion"
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.lastTraversalFinishReason = "vanilla_fence_crossed"
        return true, "fence_vanilla_crossed"
    end
    if actionState == "climbfence"
        and now < (tonumber(action.finishAt) or now)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        return true, "fence_climb_vanilla"
    end
    if now < (tonumber(action.startGraceUntil) or now) then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        return true, "fence_climb_vanilla_starting"
    end
    if actionState == "climbfence"
        and LiveBodyControl
        and LiveBodyControl.SuppressZombieState
    then
        LiveBodyControl.SuppressZombieState(zombie, lane, now)
    end
    lane.vanillaFenceAction = nil
    lane.specialMoveUntil = now + (Internal.SPECIAL_ACTION_COOLDOWN_MS or 500)
    lane.ownerMode = "fake_locomotion"
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    lane.lastTraversalFinishReason = "vanilla_fence_same_side"
    return true, "fence_vanilla_same_side"
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
    if not exactBlockedEdge then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_not_bumped",
            "object=" .. Internal.describeSquare(fence.square)
        )
        return false, nil, true
    end
    local fromSquare = resolveFromSquare(context, fence)
    local landingX
    local landingY
    local landingZ = fence.landingSquare:getZ()
    local fenceKey = "fence:" .. Internal.describeSquare(fence.square)
    if TraversalQuery and TraversalQuery.GetFenceTransferPoint then
        landingX, landingY = TraversalQuery.GetFenceTransferPoint(
            fromSquare,
            fence.landingSquare,
            context.fromX,
            context.fromY
        )
    else
        landingX = fence.landingSquare:getX() + 0.5
        landingY = fence.landingSquare:getY() + 0.5
    end
    if landingX == nil or landingY == nil then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "fence_geometry_invalid",
            "object=" .. tostring(fenceKey)
        )
        return false, nil, true
    end
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
