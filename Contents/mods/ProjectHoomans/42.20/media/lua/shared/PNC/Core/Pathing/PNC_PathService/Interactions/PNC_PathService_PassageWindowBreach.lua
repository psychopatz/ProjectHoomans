-- Interaction provider: window opening and smash-action handoff.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

local function rememberWindowHold(context)
    if Internal.MotionHints and Internal.MotionHints.RememberHold then
        Internal.MotionHints.RememberHold(
            context.lane,
            context.zombie:getX(),
            context.zombie:getY(),
            context.zombie:getZ(),
            context.now,
            250,
            { kind = "window_open", profile = context.lane.motionProfile }
        )
    end
end

function Internal.tryWindowBreach(context, object, objectSquare, objectKey)
    if object:IsOpen() or object:isSmashed() then return nil, nil, false end
    local actionKey = "window_open:" .. Internal.describeSquare(objectSquare)
    if Internal.shouldSuppressSpecialAction(
        context.lane, actionKey, context.now
    ) then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_special_cooldown",
            "object=" .. tostring(objectKey or "nil")
        )
        return false, nil, true
    end
    if Internal.openWindowForNPC(context.zombie, object) then
        Internal.rememberSpecialAction(context.lane, actionKey, context.now)
        rememberWindowHold(context)
        Internal.logMoveDebug(
            context.record, context.zombie, context.lane,
            "window_open", "window_open",
            "from=" .. context.fromPoint
                .. " object=" .. Internal.describeSquare(objectSquare)
                .. " goal=" .. Internal.describePoint(
                    context.goalX, context.goalY, context.goalZ
                )
        )
        return nil, nil, false
    end

    actionKey = "window_smash:" .. Internal.describeSquare(objectSquare)
    if not Internal.beginTraversalAction
        or not Internal.beginTraversalAction(
            context.zombie,
            context.record,
            context.lane,
            {
                kind = "window_smash",
                anim = "PNC_WindowSmash",
                obstacle = object,
                fromX = context.fromX,
                fromY = context.fromY,
                fromZ = context.fromZ,
                toX = context.fromX,
                toY = context.fromY,
                toZ = context.fromZ,
                travelDurationMs = 650,
                finishHoldMs = 260,
            }
        )
    then
        Internal.logTraversalReject(
            context.record, context.zombie, context.lane,
            "traversal_rejected", "window_smash_runtime_unavailable",
            "object=" .. tostring(objectKey or "nil")
        )
        return false, nil, true
    end
    Internal.rememberSpecialAction(context.lane, actionKey, context.now)
    Internal.logMoveDebug(
        context.record, context.zombie, context.lane,
        "window_smash", "window_open_failed",
        "from=" .. context.fromPoint
            .. " object=" .. Internal.describeSquare(objectSquare)
    )
    return true, "window_smash", true
end
