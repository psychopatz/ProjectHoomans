-- Authoritative fire damage adapter for managed NPCs.
-- Routes non-campfire fire exposure through PNC.Health and PNC.NPCWounds so
-- burning NPCs accumulate burn wounds across body parts, can die from fire,
-- and auto-extinguish off hazard tiles with vanilla IsoPlayer-like odds.

local Health = PNC.Health
local Core = PNC.Core
local Const = PNC.Const

local function isCampfireSquare(square)
    local objects
    local count
    local i
    local obj
    if not square then
        return false
    end
    if square.hasLitCampfire and square:hasLitCampfire() == true then
        return true
    end
    objects = square.getObjects and square:getObjects() or nil
    count = objects and objects.size and objects:size() or 0
    for i = 0, count - 1 do
        obj = objects:get(i)
        if obj and obj.isCampfire and obj:isCampfire() == true then
            return true
        end
    end
    return false
end

local function isBurningSquare(square)
    local props
    if not square then
        return false
    end
    if square.isFire and square:isFire() == true then
        return true
    end
    props = square.getProperties and square:getProperties() or nil
    if props and props.has and IsoFlagType and IsoFlagType.burning then
        return props:has(IsoFlagType.burning) == true
    end
    return false
end

local function extinguishBody(zombie)
    if not zombie then return false end
    if zombie.StopBurning then
        zombie:StopBurning()
        return true
    end
    if zombie.setOnFire then
        zombie:setOnFire(false)
        return true
    end
    return false
end

local function randomUnit()
    if ZombRand then
        return (tonumber(ZombRand(10000)) or 0) / 10000
    end
    return math.random()
end

local function chooseFireBurnPartId(record, preferredPartId)
    local wounds = PNC.NPCWounds
    local order
    local parts
    local existingWounds
    local candidates = {}
    local totalWeight = 0
    local i
    local partId
    local part
    local existing
    local roll
    if not wounds or type(wounds.Parts) ~= "table" then
        return preferredPartId or "Torso_Upper"
    end
    if preferredPartId and wounds.Parts[tostring(preferredPartId)] then
        return tostring(preferredPartId)
    end
    order = wounds.PartOrder or {}
    parts = wounds.Parts
    existingWounds = record and record.health and record.health.body
        and record.health.body.wounds or {}
    for i = 1, #order do
        partId = order[i]
        part = parts[partId]
        existing = existingWounds[partId]
        if part and not (existing and (existing.burned == true or existing.type == "burn")) then
            local w = math.max(1, tonumber(part.weight) or 1)
            candidates[#candidates + 1] = { id = partId, weight = w }
            totalWeight = totalWeight + w
        end
    end
    if #candidates > 0 and totalWeight > 0 then
        roll = randomUnit() * totalWeight
        for i = 1, #candidates do
            roll = roll - candidates[i].weight
            if roll <= 0 then
                return candidates[i].id
            end
        end
        return candidates[#candidates].id
    end
    if type(wounds.ChoosePartId) == "function" then
        return wounds.ChoosePartId()
    end
    return "Torso_Upper"
end

Health.IsCampfireSquare = isCampfireSquare
Health.IsBurningSquare = isBurningSquare
Health.ChooseFireBurnPartId = chooseFireBurnPartId

function Health.ApplyFireDamage(record, zombie, options)
    local opts = type(options) == "table" and options or {}
    local amount = math.max(0, tonumber(opts.amount) or 0)
    local partId
    local damageEvent
    local applied
    local result
    local wounds = PNC.NPCWounds
    if not record or record.alive == false or amount <= 0 then
        return false, { outcome = "invalid_target" }
    end
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, { outcome = "not_authority" }
    end
    partId = chooseFireBurnPartId(record, opts.partId)
    damageEvent = {
        amount = amount,
        partId = partId,
        woundType = "burn",
        type = tostring(opts.type or "fire"),
        attackerKind = tostring(opts.attackerKind or "fire"),
        attackType = tostring(opts.attackType or "fire"),
        x = opts.x or (zombie and zombie.getX and zombie:getX()) or record.x,
        y = opts.y or (zombie and zombie.getY and zombie:getY()) or record.y,
        z = opts.z or (zombie and zombie.getZ and zombie:getZ()) or record.z,
    }
    if opts.applyWound ~= false
        and wounds
        and type(wounds.ApplyCombatDamage) == "function"
    then
        applied, result = wounds.ApplyCombatDamage(record, zombie, damageEvent)
    else
        local reason, detail
        applied, reason, detail = Health.ApplyDamage(record, zombie, damageEvent)
        result = {
            outcome = record.alive == false and "killed"
                or (applied and "applied" or "damage_rejected"),
            reason = reason,
            partId = partId,
            woundType = "burn",
            damage = amount,
            detail = detail,
        }
    end
    if record.alive == false and zombie then
        extinguishBody(zombie)
    end
    return applied, result
end

function Health.UpdateFireDamage(record, zombie, now)
    local square
    local onFire
    local onCampfire
    local onHazardFire
    local fireState
    local elapsed
    local dtSec
    local damage
    local shouldApplyWound
    local isRunning
    local extinguishRate
    local extinguishChance
    if not record or record.alive == false or not zombie then
        return false
    end
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
    if zombie.setFireSpreadProbability then
        zombie:setFireSpreadProbability(0)
    end
    if zombie.setFireKillRate then
        zombie:setFireKillRate(0)
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    square = zombie.getSquare and zombie:getSquare() or nil
    onFire = zombie.isOnFire and zombie:isOnFire() == true or false
    onCampfire = isCampfireSquare(square)
    onHazardFire = isBurningSquare(square) and not onCampfire
    fireState = record.runtime and record.runtime.fireState or nil

    -- Never let a lit campfire ignite a managed NPC.
    if onCampfire and onFire and not (fireState and fireState.burning == true) then
        extinguishBody(zombie)
        return false
    end

    if not onFire then
        if fireState then
            record.runtime.fireState = nil
        end
        return false
    end

    record.runtime = record.runtime or {}
    if not fireState or fireState.burning ~= true then
        fireState = {
            burning = true,
            startedAt = now,
            lastTickAt = now,
            lastBurnWoundAt = now,
        }
        record.runtime.fireState = fireState
        Health.ApplyFireDamage(record, zombie, {
            amount = tonumber(Const and Const.FIRE_IGNITION_DAMAGE) or 6.0,
            applyWound = true,
            type = "fire",
        })
        if record.alive == false then
            record.runtime.fireState = nil
        end
        return true
    end

    elapsed = now - (tonumber(fireState.lastTickAt) or now)
    if elapsed < (tonumber(Const and Const.FIRE_DAMAGE_TICK_MS) or 1000) then
        return false
    end
    fireState.lastTickAt = now
    dtSec = math.min(5, math.max(0.1, elapsed / 1000))
    damage = (tonumber(Const and Const.FIRE_DAMAGE_PER_SECOND) or 6.5) * dtSec
    shouldApplyWound = (now - (tonumber(fireState.lastBurnWoundAt) or 0))
        >= (tonumber(Const and Const.FIRE_BURN_SPREAD_INTERVAL_MS) or 2500)
    Health.ApplyFireDamage(record, zombie, {
        amount = damage,
        applyWound = shouldApplyWound,
        type = "fire",
    })
    if shouldApplyWound then
        fireState.lastBurnWoundAt = now
    end
    if record.alive == false then
        record.runtime.fireState = nil
        return true
    end

    -- Mirror vanilla IsoPlayer auto-extinguish once off a burning hazard tile.
    if not onHazardFire then
        isRunning = zombie.isRunning and zombie:isRunning() == true or false
        extinguishRate = isRunning
            and (tonumber(Const and Const.FIRE_EXTINGUISH_RUNNING_CHANCE_PER_SEC) or 0.20)
            or (tonumber(Const and Const.FIRE_EXTINGUISH_CHANCE_PER_SEC) or 0.08)
        extinguishRate = math.max(0, math.min(0.99, extinguishRate))
        extinguishChance = 1 - ((1 - extinguishRate) ^ dtSec)
        if randomUnit() < extinguishChance then
            extinguishBody(zombie)
            record.runtime.fireState = nil
        end
    end
    return true
end
