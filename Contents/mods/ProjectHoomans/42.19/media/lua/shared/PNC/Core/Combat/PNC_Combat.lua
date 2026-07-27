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
local Animation = PNC.Animation
local Equipment = PNC.Equipment
local Perception = PNC.Perception

Internal.MELEE_BUMP_TYPES = {
    onehanded = { "PNC_Attack1H1" },
    twohanded = { "PNC_Attack2H1" },
    spear = { "PNC_AttackS1" },
    knife = { "PNC_AttackKnife" },
}

Internal.RANGED_BUMP_TYPES = {
    handgun = { "PNC_AttackPistol" },
    rifle = { "PNC_AttackRifle" },
}

Internal.ATTACK_TIMINGS = {
    melee = { hitDelay = 320, duration = 760 },
    ranged = { hitDelay = 180, duration = 620 },
    shove = { hitDelay = 130, duration = 480 },
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
                    pcall(forward.set, forward, dx, dy)
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
    if target.kind == "player" and target.player then
        liveTarget = target.player
        faceX = target.player:getX()
        faceY = target.player:getY()
        faceZ = target.player:getZ()
    elseif target.kind == "npc" then
        liveTarget = Registry.GetLiveZombie(target.id)
        if liveTarget then
            faceX = liveTarget:getX()
            faceY = liveTarget:getY()
            faceZ = liveTarget:getZ()
        else
            faceX = target.x
            faceY = target.y
            faceZ = target.z
        end
    elseif target.kind == "zombie" then
        liveTarget = target.worldObject
            or (Perception and Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil)
        if liveTarget then
            faceX = liveTarget:getX()
            faceY = liveTarget:getY()
            faceZ = liveTarget:getZ()
        else
            faceX = target.x
            faceY = target.y
            faceZ = target.z
        end
    else
        return false
    end

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
    return (now - (tonumber(record.runtime.lastAttackAt) or 0)) >= cooldownMs
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

function Internal.triggerMeleeWeaponAnim(zombie, record, equipmentInfo)
    local options = Internal.MELEE_BUMP_TYPES[Internal.resolveMeleeAnimFamily(record, equipmentInfo)] or Internal.MELEE_BUMP_TYPES.onehanded
    local anim
    if not zombie or not Animation or not Animation.PlayBump or not options or #options <= 0 then
        return nil
    end
    anim = options[ZombRand(#options) + 1]
    Animation.PlayBump(zombie, record, anim)
    return anim
end

function Internal.triggerRangedWeaponAnim(zombie, record, equipmentInfo)
    local family = equipmentInfo and equipmentInfo.primaryType == "rifle" and "rifle" or "handgun"
    local options = Internal.RANGED_BUMP_TYPES[family] or Internal.RANGED_BUMP_TYPES.handgun
    local anim
    if not zombie or not Animation or not Animation.PlayBump or not options or #options <= 0 then
        return nil
    end
    anim = options[ZombRand(#options) + 1]
    Animation.PlayBump(zombie, record, anim)
    return anim
end

function Internal.playAttackSound(zombie, record)
    local item
    local emitter
    local swingSound
    if not zombie or not zombie.getEmitter then
        return
    end
    item = Internal.resolveWeaponItem(record)
    emitter = zombie:getEmitter()
    swingSound = item and item.getSwingSound and item:getSwingSound() or nil
    if swingSound and swingSound ~= "" and emitter and emitter.playSound then
        emitter:playSound(swingSound)
    end
end
