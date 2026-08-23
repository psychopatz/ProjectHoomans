PNC = PNC or {}
PNC.CombatZombieReaction = PNC.CombatZombieReaction or {}

local ZombieReaction = PNC.CombatZombieReaction
local Internal = ZombieReaction.Internal or {}
ZombieReaction.Internal = Internal

Internal.PUSH_INTERVAL_MS = 45
Internal.DEFAULT_DURATION_MS = 220
Internal.DEFAULT_PUSH_DURATION_MS = 150
Internal.DEFAULT_PUSH_DISTANCE = 0.18
Internal.DEFAULT_STEP_DISTANCE = 0.06
Internal.ENGINE_HIT_SETTLE_MS = 650
Internal.MIN_ENGINE_REACTION_MS = 110

function Internal.GetSquare(x, y, z)
    if not getCell then return nil end
    return getCell():getGridSquare(math.floor(x), math.floor(y), z)
end

function Internal.IsSquareWalkable(x, y, z, fromX, fromY, fromZ)
    local TraversalQuery = PNC.TraversalQuery
    if TraversalQuery and TraversalQuery.CanStep then
        return TraversalQuery.CanStep(fromX, fromY, fromZ, x, y, z)
    end
    local square = Internal.GetSquare(x, y, z)
    if not square then return false end
    return square:isFree(false)
        and (not square:isSolid())
        and (not square:isSolidTrans())
end

function Internal.GetReactionState(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    return modData, modData and modData.PNC_CombatReaction or nil
end

function Internal.ClearReactionState(zombie, modData)
    if modData then modData.PNC_CombatReaction = nil end
end

function Internal.IsDamageReactionState(zombie)
    local name = zombie
        and zombie.getActionStateName
        and tostring(zombie:getActionStateName() or ""):lower()
        or ""
    return name:find("stagger", 1, true) ~= nil
        or name:find("bump", 1, true) ~= nil
        or name:find("hitreaction", 1, true) ~= nil
        or name:find("knockdown", 1, true) ~= nil
        or name:find("fall", 1, true) ~= nil
        or name:find("onground", 1, true) ~= nil
end

function Internal.ReleaseReactionState(zombie, state, force)
    local shouldReleaseStagger = force == true
        or state and state.pncForcedStagger == true
        or Internal.IsDamageReactionState(zombie)
    if not zombie then return end
    if shouldReleaseStagger and zombie.setStaggerBack then
        zombie:setStaggerBack(false)
    end
    if shouldReleaseStagger and zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if shouldReleaseStagger and zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
    if shouldReleaseStagger and zombie.setBumpType then
        local bumpType = zombie.getBumpType
            and tostring(zombie:getBumpType() or "")
            or "stagger"
        if bumpType == "" or bumpType:lower() == "stagger" then
            zombie:setBumpType("")
        end
    end
    if state and state.pncHitReaction == true and zombie.setHitReaction then
        zombie:setHitReaction("")
    end
    if shouldReleaseStagger and zombie.setStateEventDelayTimer then
        zombie:setStateEventDelayTimer(0)
    end
end

function Internal.ApplyHitContext(attackerZombie, targetZombie, options)
    if not targetZombie then return end
    if targetZombie.setAttackedBy then
        targetZombie:setAttackedBy(attackerZombie
            or (getCell and getCell():getFakeZombieForHit() or nil))
    end
    if attackerZombie and targetZombie.setPlayerAttackPosition
        and targetZombie.testDotSide
    then
        targetZombie:setPlayerAttackPosition(
            targetZombie:testDotSide(attackerZombie)
        )
    end
    if attackerZombie and targetZombie.setHitFromBehind
        and attackerZombie.isBehind
    then
        targetZombie:setHitFromBehind(
            attackerZombie:isBehind(targetZombie) == true
        )
    end
    if targetZombie.setHitForce then
        targetZombie:setHitForce(tonumber(options and options.hitForce) or 0.92)
    end
end

function Internal.BeginEngineHitSettle(targetZombie, options, ownsHitReaction)
    local modData
    local state
    local now
    if not targetZombie or targetZombie:isDead() then return false end
    modData, state = Internal.GetReactionState(targetZombie)
    if not modData then return false end
    now = PNC.Core.Now()
    state = state or {}
    state.kind = options and tostring(options.kind or "weapon_hit")
        or "weapon_hit"
    state.engineOwned = true
    state.startedAt = now
    state.pncForcedStagger = false
    state.pncHitReaction = ownsHitReaction == true
    state.expiresAt = math.max(
        tonumber(state.expiresAt) or 0,
        now + math.max(160,
            tonumber(options and options.settleMs)
                or Internal.ENGINE_HIT_SETTLE_MS)
    )
    state.remainingPush = 0
    modData.PNC_CombatReaction = state
    return true
end

return ZombieReaction
