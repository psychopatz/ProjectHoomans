local ZombieReaction = PNC.CombatZombieReaction
local Internal = ZombieReaction.Internal

local function resolvePushDirection(attackerZombie, targetZombie)
    local dx
    local dy
    local len
    local forward
    if attackerZombie and targetZombie then
        dx = targetZombie:getX() - attackerZombie:getX()
        dy = targetZombie:getY() - attackerZombie:getY()
        len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.001 then return dx / len, dy / len end
    end
    forward = targetZombie and targetZombie.getForwardDirection
        and targetZombie:getForwardDirection() or nil
    if forward then
        dx = tonumber(forward:getX()) or 0
        dy = tonumber(forward:getY()) or 0
        len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.001 then return dx / len, dy / len end
    end
    return 1, 0
end

local function beginReaction(attackerZombie, targetZombie, options)
    local modData
    local state
    local dirX
    local dirY
    local now
    local durationMs
    local pushDurationMs
    local pushDistance
    local stepDistance

    if not targetZombie or targetZombie:isDead() then return false end
    modData, state = Internal.GetReactionState(targetZombie)
    if not modData then return false end

    now = PNC.Core.Now()
    durationMs = math.max(80,
        tonumber(options and options.durationMs)
            or Internal.DEFAULT_DURATION_MS)
    pushDurationMs = math.max(0,
        tonumber(options and options.pushDurationMs)
            or Internal.DEFAULT_PUSH_DURATION_MS)
    pushDistance = math.max(0,
        tonumber(options and options.pushDistance)
            or Internal.DEFAULT_PUSH_DISTANCE)
    stepDistance = math.max(0.02,
        tonumber(options and options.stepDistance)
            or Internal.DEFAULT_STEP_DISTANCE)
    dirX, dirY = resolvePushDirection(attackerZombie, targetZombie)

    Internal.ApplyHitContext(attackerZombie, targetZombie, options)
    -- Explicit shoves request vanilla stagger entry, but retain a bounded PNC
    -- lease so a missing animation event cannot leave the zombie frozen.
    if (options == nil or options.stagger ~= false)
        and targetZombie.setStaggerBack
    then
        targetZombie:setStaggerBack(true)
        if targetZombie.setBumpType then targetZombie:setBumpType("stagger") end
    end
    if options and options.heavy == true and options.knockdown == true
        and targetZombie.setKnockedDown
    then
        targetZombie:setKnockedDown(true)
    end
    state = state or {}
    state.kind = options and tostring(options.kind or "melee") or "melee"
    state.startedAt = tonumber(state.startedAt) or now
    state.engineOwned = false
    state.pncForcedStagger = options == nil or options.stagger ~= false
    state.pncHitReaction = options and options.hitReaction ~= nil
        or state.pncHitReaction == true
    state.expiresAt = math.max(tonumber(state.expiresAt) or 0,
        now + durationMs)
    state.pushExpiresAt = math.max(tonumber(state.pushExpiresAt) or 0,
        now + pushDurationMs)
    state.remainingPush = math.max(tonumber(state.remainingPush) or 0,
        pushDistance)
    state.stepDistance = math.max(tonumber(state.stepDistance) or 0,
        stepDistance)
    state.lastPushAt = tonumber(state.lastPushAt) or 0
    state.dirX = dirX
    state.dirY = dirY
    modData.PNC_CombatReaction = state

    if PNC.ZombieAggro and PNC.ZombieAggro.OnZombieProvoked
        and attackerZombie
    then
        PNC.ZombieAggro.OnZombieProvoked(targetZombie, attackerZombie)
    end
    return true
end

Internal.BeginReaction = beginReaction

function ZombieReaction.Start(attackerZombie, targetZombie, options)
    return beginReaction(attackerZombie, targetZombie, options or {})
end

return ZombieReaction
