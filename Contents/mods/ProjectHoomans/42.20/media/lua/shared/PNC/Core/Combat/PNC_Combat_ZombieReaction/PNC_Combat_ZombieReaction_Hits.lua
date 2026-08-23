local ZombieReaction = PNC.CombatZombieReaction
local Internal = ZombieReaction.Internal

function ZombieReaction.ApplyWeaponHit(
    attackerZombie,
    targetZombie,
    weaponItem,
    scaledDamage,
    options
)
    local fakeZombie
    local applied = false
    local beforeHealth
    local afterHealth
    if not targetZombie or targetZombie:isDead() then return false end
    Internal.ApplyHitContext(attackerZombie, targetZombie, options)
    if weaponItem and targetZombie.Hit then
        beforeHealth = tonumber(targetZombie:getHealth()) or 0
        fakeZombie = getCell and getCell():getFakeZombieForHit() or nil
        -- Last-resort Java boundary only: the overloaded engine call may reject
        -- a valid-looking Kahlua signature. The health fallback handles it.
        applied = pcall(function()
            targetZombie:Hit(
                weaponItem,
                fakeZombie or attackerZombie,
                tonumber(scaledDamage) or 0,
                false,
                1,
                false
            )
        end)
        afterHealth = tonumber(targetZombie:getHealth()) or beforeHealth
        applied = applied == true and afterHealth < (beforeHealth - 0.0001)
    end
    if not targetZombie:isDead() then
        if targetZombie.setAttackedBy and attackerZombie then
            targetZombie:setAttackedBy(attackerZombie)
        end
        if not applied and options and options.hitReaction
            and targetZombie.setHitReaction
        then
            targetZombie:setHitReaction(tostring(options.hitReaction))
        end
        -- IsoZombie:Hit owns stagger entry. Reasserting StaggerBack here could
        -- leave WalkToward/attack AI suspended after the engine clip ended.
        Internal.BeginEngineHitSettle(
            targetZombie,
            options,
            not applied and options and options.hitReaction ~= nil
        )
    end
    -- Manual movement remains reserved for explicit shoves.
    if options and options.manualPush == true then
        Internal.BeginReaction(attackerZombie, targetZombie, options)
    end
    return applied == true
end

function ZombieReaction.ApplyReplicatedHit(
    attackerZombie,
    targetZombie,
    options
)
    local health
    local modData
    local state
    if not targetZombie or (targetZombie.isDead and targetZombie:isDead()) then
        return false
    end
    options = options or {}
    health = tonumber(options.health)
    -- This is a server-authored result, not client-side damage simulation.
    if health and health > 0 and targetZombie.setHealth then
        targetZombie:setHealth(health)
    end
    Internal.ApplyHitContext(attackerZombie, targetZombie, options)
    if options.hitReaction and targetZombie.setHitReaction then
        targetZombie:setHitReaction(tostring(options.hitReaction))
    end
    if options.stagger ~= false and targetZombie.setStaggerBack then
        targetZombie:setStaggerBack(true)
        if targetZombie.setBumpDone then targetZombie:setBumpDone(false) end
        if targetZombie.setVariable then
            targetZombie:setVariable("BumpDone", false)
            targetZombie:setVariable("BumpAnimFinished", false)
        end
        if targetZombie.setBumpType then targetZombie:setBumpType("stagger") end
    end
    options.settleMs = tonumber(options.settleMs)
        or (tostring(options.kind or "") == "ranged" and 420 or 520)
    Internal.BeginEngineHitSettle(
        targetZombie,
        options,
        options.hitReaction ~= nil
    )
    modData, state = Internal.GetReactionState(targetZombie)
    if modData and state then
        state.pncForcedStagger = options.stagger ~= false
        state.pncHitReaction = options.hitReaction ~= nil
    end
    return true
end

return ZombieReaction
