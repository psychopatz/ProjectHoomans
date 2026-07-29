--[[
    PNC Combat Zombie Reaction
    Adds short collision-safe shove displacement after NPC combat. The engine
    remains the sole owner of hit/stagger/knockdown state; taking ownership here
    can freeze vanilla zombies when IsoZombie:Hit() transitions concurrently.
]]

PNC = PNC or {}
PNC.CombatZombieReaction = PNC.CombatZombieReaction or {}

local ZombieReaction = PNC.CombatZombieReaction
local Core = PNC.Core
local TraversalQuery = PNC.TraversalQuery

local PUSH_INTERVAL_MS = 45
local DEFAULT_DURATION_MS = 220
local DEFAULT_PUSH_DURATION_MS = 150
local DEFAULT_PUSH_DISTANCE = 0.18
local DEFAULT_STEP_DISTANCE = 0.06
local ENGINE_HIT_SETTLE_MS = 650
local MIN_ENGINE_REACTION_MS = 110

local function getSquare(x, y, z)
    if not getCell then
        return nil
    end
    return getCell():getGridSquare(math.floor(x), math.floor(y), z)
end

local function isSquareWalkable(x, y, z, fromX, fromY, fromZ)
    if TraversalQuery and TraversalQuery.CanStep then
        return TraversalQuery.CanStep(fromX, fromY, fromZ, x, y, z)
    end
    local square = getSquare(x, y, z)
    if not square then
        return false
    end
    return square:isFree(false) and (not square:isSolid()) and (not square:isSolidTrans())
end

local function getReactionState(zombie)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    return modData, modData and modData.PNC_CombatReaction or nil
end

local function clearReactionState(zombie, modData)
    if modData then
        modData.PNC_CombatReaction = nil
    end
end

local function isDamageReactionState(zombie)
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

local function releaseReactionState(zombie, state, force)
    local shouldReleaseStagger = force == true
        or state and state.pncForcedStagger == true
        or isDamageReactionState(zombie)
    if not zombie then
        return
    end
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

local function resolvePushDirection(attackerZombie, targetZombie)
    local dx
    local dy
    local len
    local forward
    if attackerZombie and targetZombie then
        dx = targetZombie:getX() - attackerZombie:getX()
        dy = targetZombie:getY() - attackerZombie:getY()
        len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.001 then
            return dx / len, dy / len
        end
    end
    forward = targetZombie and targetZombie.getForwardDirection and targetZombie:getForwardDirection() or nil
    if forward then
        dx = tonumber(forward:getX()) or 0
        dy = tonumber(forward:getY()) or 0
        len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.001 then
            return dx / len, dy / len
        end
    end
    return 1, 0
end

local function applyHitContext(attackerZombie, targetZombie, options)
    if not targetZombie then
        return
    end
    if targetZombie.setAttackedBy then
        targetZombie:setAttackedBy(attackerZombie or (getCell and getCell():getFakeZombieForHit() or nil))
    end
    if attackerZombie and targetZombie.setPlayerAttackPosition and targetZombie.testDotSide then
        targetZombie:setPlayerAttackPosition(targetZombie:testDotSide(attackerZombie))
    end
    if attackerZombie and targetZombie.setHitFromBehind and attackerZombie.isBehind then
        targetZombie:setHitFromBehind(
            attackerZombie:isBehind(targetZombie) == true
        )
    end
    if targetZombie.setHitForce then
        targetZombie:setHitForce(tonumber(options and options.hitForce) or 0.92)
    end
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

    if not targetZombie or targetZombie:isDead() then
        return false
    end

    modData, state = getReactionState(targetZombie)
    if not modData then
        return false
    end

    now = Core.Now()
    durationMs = math.max(80, tonumber(options and options.durationMs) or DEFAULT_DURATION_MS)
    pushDurationMs = math.max(0, tonumber(options and options.pushDurationMs) or DEFAULT_PUSH_DURATION_MS)
    pushDistance = math.max(0, tonumber(options and options.pushDistance) or DEFAULT_PUSH_DISTANCE)
    stepDistance = math.max(0.02, tonumber(options and options.stepDistance) or DEFAULT_STEP_DISTANCE)
    dirX, dirY = resolvePushDirection(attackerZombie, targetZombie)

    applyHitContext(attackerZombie, targetZombie, options)
    -- Explicit shoves request vanilla stagger entry, but retain a bounded PNC
    -- lease so a missing animation event cannot leave the zombie frozen.
    if (options == nil or options.stagger ~= false) and targetZombie.setStaggerBack then
        targetZombie:setStaggerBack(true)
        if targetZombie.setBumpType then
            targetZombie:setBumpType("stagger")
        end
    end
    if options and options.heavy == true and options.knockdown == true and targetZombie.setKnockedDown then
        targetZombie:setKnockedDown(true)
    end
    state = state or {}
    state.kind = options and tostring(options.kind or "melee") or "melee"
    state.startedAt = tonumber(state.startedAt) or now
    state.engineOwned = false
    state.pncForcedStagger = options == nil or options.stagger ~= false
    state.pncHitReaction = options
        and options.hitReaction ~= nil
        or state.pncHitReaction == true
    state.expiresAt = math.max(tonumber(state.expiresAt) or 0, now + durationMs)
    state.pushExpiresAt = math.max(tonumber(state.pushExpiresAt) or 0, now + pushDurationMs)
    state.remainingPush = math.max(tonumber(state.remainingPush) or 0, pushDistance)
    state.stepDistance = math.max(tonumber(state.stepDistance) or 0, stepDistance)
    state.lastPushAt = tonumber(state.lastPushAt) or 0
    state.dirX = dirX
    state.dirY = dirY
    modData.PNC_CombatReaction = state

    if PNC.ZombieAggro and PNC.ZombieAggro.OnZombieProvoked and attackerZombie then
        PNC.ZombieAggro.OnZombieProvoked(targetZombie, attackerZombie)
    end
    return true
end

local function beginEngineHitSettle(
    targetZombie,
    options,
    ownsHitReaction
)
    local modData
    local state
    local now
    if not targetZombie or targetZombie:isDead() then
        return false
    end
    modData, state = getReactionState(targetZombie)
    if not modData then
        return false
    end
    now = Core.Now()
    state = state or {}
    state.kind = options and tostring(options.kind or "weapon_hit") or "weapon_hit"
    state.engineOwned = true
    state.startedAt = now
    state.pncForcedStagger = false
    state.pncHitReaction = ownsHitReaction == true
    state.expiresAt = math.max(
        tonumber(state.expiresAt) or 0,
        now + math.max(160, tonumber(options and options.settleMs) or ENGINE_HIT_SETTLE_MS)
    )
    state.remainingPush = 0
    modData.PNC_CombatReaction = state
    return true
end

function ZombieReaction.Start(attackerZombie, targetZombie, options)
    return beginReaction(attackerZombie, targetZombie, options or {})
end

function ZombieReaction.ApplyWeaponHit(attackerZombie, targetZombie, weaponItem, scaledDamage, options)
    local fakeZombie
    local applied = false
    local beforeHealth
    local afterHealth
    if not targetZombie or targetZombie:isDead() then
        return false
    end
    applyHitContext(attackerZombie, targetZombie, options)
    if weaponItem and targetZombie.Hit then
        beforeHealth = tonumber(targetZombie:getHealth()) or 0
        fakeZombie = getCell and getCell():getFakeZombieForHit() or nil
        -- Last-resort Java boundary only: IsoZombie:Hit is an overloaded
        -- engine call that can reject a valid-looking Kahlua signature.
        -- The deterministic health fallback below handles that failure.
        applied = pcall(function()
            targetZombie:Hit(weaponItem, fakeZombie or attackerZombie, tonumber(scaledDamage) or 0, false, 1, false)
        end)
        afterHealth = tonumber(targetZombie:getHealth()) or beforeHealth
        applied = applied == true and afterHealth < (beforeHealth - 0.0001)
    end
    if not targetZombie:isDead() then
        if targetZombie.setAttackedBy and attackerZombie then
            targetZombie:setAttackedBy(attackerZombie)
        end
        if not applied
            and options
            and options.hitReaction
            and targetZombie.setHitReaction
        then
            targetZombie:setHitReaction(tostring(options.hitReaction))
        end
        -- IsoZombie:Hit owns stagger entry. Reasserting StaggerBack here could
        -- leave WalkToward/attack AI suspended after the engine clip ended.
        beginEngineHitSettle(
            targetZombie,
            options,
            not applied and options and options.hitReaction ~= nil
        )
    end
    -- IsoZombie:Hit owns the visible reaction. Manual movement is reserved for
    -- explicit shoves so normal hits cannot fight the engine state machine.
    if options and options.manualPush == true then
        beginReaction(attackerZombie, targetZombie, options)
    end
    return applied == true
end

function ZombieReaction.ApplyReplicatedHit(attackerZombie, targetZombie, options)
    local health
    local modData
    local state
    if not targetZombie or (targetZombie.isDead and targetZombie:isDead()) then
        return false
    end
    options = options or {}
    health = tonumber(options.health)
    -- This is a server-authored result, not client-side damage simulation.
    -- Lethal state remains on the engine's normal zombie-death replication lane.
    if health and health > 0 and targetZombie.setHealth then
        targetZombie:setHealth(health)
    end
    applyHitContext(attackerZombie, targetZombie, options)
    if options.hitReaction and targetZombie.setHitReaction then
        targetZombie:setHitReaction(tostring(options.hitReaction))
    end
    if options.stagger ~= false and targetZombie.setStaggerBack then
        targetZombie:setStaggerBack(true)
        if targetZombie.setBumpDone then
            targetZombie:setBumpDone(false)
        end
        if targetZombie.setVariable then
            targetZombie:setVariable("BumpDone", false)
            targetZombie:setVariable("BumpAnimFinished", false)
        end
        if targetZombie.setBumpType then
            targetZombie:setBumpType("stagger")
        end
    end
    options.settleMs = tonumber(options.settleMs)
        or (tostring(options.kind or "") == "ranged" and 420 or 520)
    beginEngineHitSettle(
        targetZombie,
        options,
        options.hitReaction ~= nil
    )
    modData, state = getReactionState(targetZombie)
    if modData and state then
        state.pncForcedStagger = options.stagger ~= false
        state.pncHitReaction = options.hitReaction ~= nil
    end
    return true
end

function ZombieReaction.IsEngineHitSettling(targetZombie, now)
    local _
    local state
    _, state = getReactionState(targetZombie)
    if not state or state.engineOwned ~= true then
        return false
    end
    now = tonumber(now) or Core.Now()
    if now >= (tonumber(state.expiresAt) or 0) then
        return false
    end
    if now < (
        (tonumber(state.startedAt) or now)
        + MIN_ENGINE_REACTION_MS
    ) then
        return true
    end
    return isDamageReactionState(targetZombie)
end

function ZombieReaction.Clear(targetZombie)
    local modData = targetZombie and targetZombie.getModData and targetZombie:getModData() or nil
    clearReactionState(targetZombie, modData)
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

    now = tonumber(now) or Core.Now()
    modData, state = getReactionState(targetZombie)
    if not state then
        return false
    end

    if now >= (tonumber(state.expiresAt) or 0) then
        releaseReactionState(targetZombie, state, true)
        clearReactionState(targetZombie, modData)
        return false
    end

    -- Once the engine has left its damage state, return AI ownership
    -- immediately instead of suppressing pursuit for the whole settle timeout.
    if state.engineOwned == true
        and now >= (
            (tonumber(state.startedAt) or now)
            + MIN_ENGINE_REACTION_MS
        )
        and not isDamageReactionState(targetZombie)
    then
        releaseReactionState(targetZombie, state, false)
        clearReactionState(targetZombie, modData)
        return false
    end

    remainingPush = math.max(0, tonumber(state.remainingPush) or 0)
    if remainingPush > 0
        and now < (tonumber(state.pushExpiresAt) or 0)
        and (now - (tonumber(state.lastPushAt) or 0)) >= PUSH_INTERVAL_MS
    then
        stepDistance = math.min(remainingPush, math.max(0.02, tonumber(state.stepDistance) or DEFAULT_STEP_DISTANCE))
        nz = targetZombie:getZ()
        nx = targetZombie:getX() + ((tonumber(state.dirX) or 0) * stepDistance)
        ny = targetZombie:getY() + ((tonumber(state.dirY) or 0) * stepDistance)
        if isSquareWalkable(nx, ny, nz, targetZombie:getX(), targetZombie:getY(), targetZombie:getZ()) then
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
