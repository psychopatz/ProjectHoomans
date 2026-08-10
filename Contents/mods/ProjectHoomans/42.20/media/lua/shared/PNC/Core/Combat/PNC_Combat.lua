--[[
    PNC Combat Entry
    Owns shared combat helpers, PNC-specific animation identifiers, and the
    public combat table used by melee, ranged, and tactics submodules.
]]

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}

PNC.Combat.Internal = PNC.Combat.Internal or {}

local Combat = PNC.Combat
local Internal = Combat.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Equipment = PNC.Equipment
local Perception = PNC.Perception

Internal.MELEE_BUMP_TYPES = {
    -- Keep attack selectors out of vanilla IsoZombie's BumpType namespace.
    -- Dynamic Trading uses the same namespaced-node pattern; generic
    -- Attack1H/Attack2H values can select a vanilla bump node before PNC's
    -- human arm animation on multiplayer replicas.
    onehanded = { "PNC_Attack1H1", "PNC_Attack1H2" },
    twohanded = { "PNC_Attack2H1", "PNC_Attack2H2" },
    spear = { "PNC_AttackS1" },
    knife = { "PNC_AttackKnife" },
}

Internal.UNARMED_BUMP_TYPES = {
    "PNC_AttackBareHands1",
    "PNC_AttackBareHands2",
    "PNC_AttackBareHands3",
    "PNC_AttackBareHands4",
    "PNC_AttackBareHands5",
    "PNC_AttackBareHands6",
    "PNC_FrontKick",
    "PNC_HighKick",
}

Internal.RANGED_BUMP_TYPES = {
    handgun = { "PNC_AttackPistol" },
    rifle = { "PNC_AttackRifle" },
}

Internal.ATTACK_TIMINGS = {
    melee = { hitDelay = 320, duration = 760 },
    ranged = { hitDelay = 180, duration = 620 },
    shove = { hitDelay = 180, duration = 850 },
    ground = { hitDelay = 240, duration = 760 },
}

local function applyImmediateFacing(zombie, liveTarget, faceX, faceY)
    local applied = false
    local dx
    local dy
    local len
    local forward
    if not zombie then return false end
    if faceX ~= nil and faceY ~= nil and zombie.getX and zombie.getY then
        dx = tonumber(faceX) - zombie:getX()
        dy = tonumber(faceY) - zombie:getY()
        len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.0001 then
            dx = dx / len
            dy = dy / len
            if zombie.getForwardDirection then
                forward = zombie:getForwardDirection()
                if forward and forward.set then
                    forward:set(dx, dy)
                end
            end
            if zombie.faceLocation then
                zombie:faceLocation(zombie:getX() + dx, zombie:getY() + dy)
                applied = true
            elseif zombie.faceLocationF then
                zombie:faceLocationF(zombie:getX() + dx, zombie:getY() + dy)
                applied = true
            end
        end
    end
    if liveTarget and zombie.faceThisObject then
        zombie:faceThisObject(liveTarget)
        applied = true
    end
    return applied
end

function Internal.resolveTargetObject(target)
    if not target then return nil end
    if target.kind == "player" then
        return target.player
    end
    if target.kind == "npc" then
        return Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(target.id) or nil
    end
    if target.kind == "zombie" then
        return target.worldObject
            or (
                Perception
                and Perception.FindZombieByID
                and Perception.FindZombieByID(target.zombieId)
            )
            or nil
    end
    return nil
end

function Internal.refreshTargetDistance(record, zombie, target)
    local liveTarget
    local originX
    local originY
    local originZ
    local dx
    local dy
    if not target then return math.huge, nil end
    liveTarget = Internal.resolveTargetObject(target)
    if liveTarget and liveTarget.getX and liveTarget.getY then
        target.x = liveTarget:getX()
        target.y = liveTarget:getY()
        target.z = liveTarget.getZ and liveTarget:getZ()
            or target.z
        target.worldObject = target.kind == "zombie"
            and liveTarget or target.worldObject
    end
    originX = zombie and zombie.getX and zombie:getX()
        or record and tonumber(record.x) or 0
    originY = zombie and zombie.getY and zombie:getY()
        or record and tonumber(record.y) or 0
    originZ = zombie and zombie.getZ and zombie:getZ()
        or record and tonumber(record.z) or 0
    if target.x == nil or target.y == nil
        or math.abs((tonumber(target.z) or originZ) - originZ) > 0.5
    then
        target.distSq = math.huge
        return math.huge, liveTarget
    end
    dx = tonumber(target.x) - originX
    dy = tonumber(target.y) - originY
    target.distSq = (dx * dx) + (dy * dy)
    return math.sqrt(target.distSq), liveTarget
end

function Internal.faceTarget(zombie, target, record, leaseMs, reason)
    local pathService = PNC.PathService
    local liveTarget
    local faceX
    local faceY
    local faceZ
    local immediate
    local leased
    if not zombie or not target then
        return false
    end
    if pathService and pathService.IsTraversalActive and pathService.IsTraversalActive(record, zombie) then
        return false
    end
    liveTarget = Internal.resolveTargetObject(target)
    if target.kind ~= "player"
        and target.kind ~= "npc"
        and target.kind ~= "zombie"
    then
        return false
    end
    faceX = liveTarget and liveTarget.getX
        and liveTarget:getX() or target.x
    faceY = liveTarget and liveTarget.getY
        and liveTarget:getY() or target.y
    faceZ = liveTarget and liveTarget.getZ
        and liveTarget:getZ() or target.z

    -- The object call drives the local ActionContext, the direct vector repairs
    -- IsoZombie bodies whose object target is temporarily unresolved, and the
    -- lease publishes the same heading to multiplayer replicas.
    immediate = applyImmediateFacing(zombie, liveTarget, faceX, faceY)
    if faceX ~= nil and faceY ~= nil
        and pathService and pathService.RequestCombatFacing and record
    then
        leased = pathService.RequestCombatFacing(record, zombie, {
            x = faceX,
            y = faceY,
            z = faceZ,
        }, leaseMs, reason or ("combat_" .. tostring(target.kind)))
    end
    return immediate == true or leased == true
end

function Combat.FaceTarget(record, zombie, target, leaseMs, reason)
    return Internal.faceTarget(zombie, target, record, leaseMs, reason)
end

function Internal.canAttack(record, now, cooldownMs)
    cooldownMs = cooldownMs or 1000
    local lastAttackAt = tonumber(
        record and record.runtime and record.runtime.lastAttackAt
    ) or 0
    -- Core.Now() is session-local. A runtime restored by a hot reload, world
    -- reload, or an MP authority handoff must not preserve a timestamp from a
    -- later clock and suppress combat until the new session catches up.
    if lastAttackAt > now then
        record.runtime.lastAttackAt = 0
        lastAttackAt = 0
    end
    return (now - lastAttackAt) >= cooldownMs
end

function Internal.prepareAttackMovement(record, zombie, reason)
    local pathService = PNC.PathService
    local moveIntent = PNC.BehaviorMoveIntent
    local stealth = PNC.Stealth
    reason = reason or "combat_action"
    -- Bandits completes its Move task before starting Smack. Mirror that
    -- ownership boundary: PathFindBehavior2 must release the body before the
    -- client selects a bumped attack clip, otherwise locomotion wins and only
    -- the authoritative sound/damage is observed.
    if pathService and pathService.Reset then
        pathService.Reset(zombie, record)
    end
    if moveIntent and moveIntent.Hold then
        moveIntent.Hold(record, reason)
    end
    if stealth and stealth.SuspendForCombat then
        stealth.SuspendForCombat(record, reason)
    elseif record and record.runtime then
        record.runtime.stealthActive = false
    end
    return true
end

function Internal.resolveWeaponItem(record, zombie)
    local fullType = record and record.equipment and record.equipment.primaryFullType or nil
    local item
    local _
    if zombie and zombie.getPrimaryHandItem then
        item = zombie:getPrimaryHandItem()
        if item and item.IsWeapon and item:IsWeapon() then
            return item
        end
    end
    if not fullType then
        return nil
    end
    if Equipment.CreateItem then
        item, _ = Equipment.CreateItem(fullType)
    end
    return item
end

function Internal.resolveMeleeAnimFamily(record, equipmentInfo)
    local fullType = string.lower(tostring(record and record.equipment and record.equipment.primaryFullType or ""))
    if fullType ~= "" and (
        string.find(fullType, "knife", 1, true)
        or string.find(fullType, "dagger", 1, true)
        or string.find(fullType, "shiv", 1, true)
        or string.find(fullType, "scalpel", 1, true)
    ) then
        return "knife"
    end
    if equipmentInfo and (equipmentInfo.primaryType == "twohanded" or equipmentInfo.primaryType == "spear") then
        return equipmentInfo.primaryType
    end
    return "onehanded"
end

function Internal.triggerMeleeWeaponAnim(
    zombie,
    record,
    equipmentInfo
)
    local options = Internal.MELEE_BUMP_TYPES[Internal.resolveMeleeAnimFamily(record, equipmentInfo)] or Internal.MELEE_BUMP_TYPES.onehanded
    if not options or #options <= 0 then
        return nil
    end
    -- The authority selects and snapshots the animation. Presentation is
    -- client-owned in SP, listen-server, and dedicated multiplayer alike.
    return options[ZombRand(#options) + 1]
end

function Internal.triggerUnarmedAttackAnim()
    local options = Internal.UNARMED_BUMP_TYPES
    if not options or #options <= 0 then
        return "PNC_AttackBareHands1"
    end
    return options[ZombRand(#options) + 1]
end

function Internal.triggerRangedWeaponAnim(
    zombie,
    record,
    equipmentInfo
)
    local family = equipmentInfo and equipmentInfo.primaryType == "rifle" and "rifle" or "handgun"
    local options = Internal.RANGED_BUMP_TYPES[family] or Internal.RANGED_BUMP_TYPES.handgun
    if not options or #options <= 0 then
        return nil
    end
    return options[ZombRand(#options) + 1]
end

function Internal.playAttackSound(zombie, record, weaponItem)
    local emitter
    local swingSound
    if not zombie or not zombie.getEmitter then
        return
    end
    emitter = zombie:getEmitter()
    weaponItem = weaponItem or Internal.resolveWeaponItem(record, zombie)
    swingSound = weaponItem and weaponItem.getSwingSound
        and weaponItem:getSwingSound() or nil
    if swingSound and swingSound ~= "" and emitter and emitter.playSound then
        emitter:playSound(swingSound)
    end
end
