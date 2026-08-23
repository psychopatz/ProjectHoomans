local ZombieReaction = PNC.CombatZombieReaction
local Internal = ZombieReaction.Internal

function ZombieReaction.IsEngineHitSettling(targetZombie, now)
    local _
    local state
    _, state = Internal.GetReactionState(targetZombie)
    if not state or state.engineOwned ~= true then return false end
    now = tonumber(now) or PNC.Core.Now()
    if now >= (tonumber(state.expiresAt) or 0) then return false end
    if now < ((tonumber(state.startedAt) or now)
        + Internal.MIN_ENGINE_REACTION_MS)
    then
        return true
    end
    return Internal.IsDamageReactionState(targetZombie)
end

function ZombieReaction.Clear(targetZombie)
    local modData = targetZombie and targetZombie.getModData
        and targetZombie:getModData() or nil
    Internal.ClearReactionState(targetZombie, modData)
end

function ZombieReaction.Pump(targetZombie, now)
    local modData
    local state
    local remainingPush
    local stepDistance
    local nx
    local ny
    local nz

    if not targetZombie or (targetZombie.isDead and targetZombie:isDead()) then
        ZombieReaction.Clear(targetZombie)
        return false
    end

    now = tonumber(now) or PNC.Core.Now()
    modData, state = Internal.GetReactionState(targetZombie)
    if not state then return false end

    if now >= (tonumber(state.expiresAt) or 0) then
        Internal.ReleaseReactionState(targetZombie, state, true)
        Internal.ClearReactionState(targetZombie, modData)
        return false
    end

    -- Once the engine leaves its damage state, return AI ownership immediately.
    if state.engineOwned == true
        and now >= ((tonumber(state.startedAt) or now)
            + Internal.MIN_ENGINE_REACTION_MS)
        and not Internal.IsDamageReactionState(targetZombie)
    then
        Internal.ReleaseReactionState(targetZombie, state, false)
        Internal.ClearReactionState(targetZombie, modData)
        return false
    end

    remainingPush = math.max(0, tonumber(state.remainingPush) or 0)
    if remainingPush > 0
        and now < (tonumber(state.pushExpiresAt) or 0)
        and (now - (tonumber(state.lastPushAt) or 0))
            >= Internal.PUSH_INTERVAL_MS
    then
        stepDistance = math.min(remainingPush,
            math.max(0.02,
                tonumber(state.stepDistance)
                    or Internal.DEFAULT_STEP_DISTANCE))
        nz = targetZombie:getZ()
        nx = targetZombie:getX()
            + ((tonumber(state.dirX) or 0) * stepDistance)
        ny = targetZombie:getY()
            + ((tonumber(state.dirY) or 0) * stepDistance)
        if Internal.IsSquareWalkable(
            nx,
            ny,
            nz,
            targetZombie:getX(),
            targetZombie:getY(),
            targetZombie:getZ()
        ) then
            targetZombie:setX(nx)
            targetZombie:setY(ny)
            state.remainingPush = math.max(0, remainingPush - stepDistance)
        else
            state.remainingPush = 0
        end
        state.lastPushAt = now
    end

    return true
end

return ZombieReaction
