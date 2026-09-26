local Resolution = PNC.CombatResolution

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function playerBodyPart(bodyDamage, partId)
    local partType = BodyPartType and BodyPartType[tostring(partId or "")] or nil
    if not bodyDamage or type(bodyDamage.getBodyPart) ~= "function" or not partType then
        return nil
    end
    return bodyDamage:getBodyPart(partType)
end

local function addPlayerWound(bodyPart, hit)
    local pain
    local current
    if not bodyPart or not Resolution.ArePlayerWoundsEnabled() then return end
    pain = tonumber(bodyPart.getAdditionalPain and bodyPart:getAdditionalPain() or 0) or 0
    if bodyPart.setAdditionalPain then
        bodyPart:setAdditionalPain(math.min(100, pain + math.max(3, hit.amount * 0.35)))
    end
    if hit.woundType == "bullet" then
        if bodyPart.setBleedingTime then
            current = tonumber(bodyPart.getBleedingTime and bodyPart:getBleedingTime() or 0) or 0
            bodyPart:setBleedingTime(math.max(current, 45))
        end
        if bodyPart.setDeepWounded then
            bodyPart:setDeepWounded(true)
        end
    elseif hit.woundType == "laceration" then
        if bodyPart.setCutTime then
            current = tonumber(bodyPart.getCutTime and bodyPart:getCutTime() or 0) or 0
            bodyPart:setCutTime(math.max(current, 8))
        elseif bodyPart.setScratchTime then
            current = tonumber(bodyPart.getScratchTime and bodyPart:getScratchTime() or 0) or 0
            bodyPart:setScratchTime(math.max(current, 8))
        end
        if bodyPart.setBleedingTime then
            current = tonumber(bodyPart.getBleedingTime and bodyPart:getBleedingTime() or 0) or 0
            bodyPart:setBleedingTime(math.max(current, 25))
        end
    elseif bodyPart.setScratchTime then
        current = tonumber(bodyPart.getScratchTime and bodyPart:getScratchTime() or 0) or 0
        bodyPart:setScratchTime(math.max(current, 6))
    end
end

function Resolution.ApplyPlayerDamage(player, amount, attackType, weaponItem, hitEvent)
    local bodyDamage
    local bodyPart
    local current
    local healthLoss
    local hit
    local applied = false
    if not player or (tonumber(amount) or 0) <= 0 then
        return false
    end
    hit = hitEvent or Resolution.BuildHitEvent(nil, { kind = "player" }, {
        damage = amount,
        attackType = attackType,
        weaponItem = weaponItem,
    })
    healthLoss = clamp((tonumber(amount) or 0) * (attackType == "ranged" and 0.42 or 0.34), 0.65, attackType == "ranged" and 22 or 16)
    bodyDamage = player.getBodyDamage and player:getBodyDamage() or nil
    bodyPart = playerBodyPart(bodyDamage, hit.partId)
    if bodyPart and bodyPart.AddDamage then
        bodyPart:AddDamage(healthLoss)
        applied = true
    end
    if not applied and bodyPart and bodyPart.getHealth and bodyPart.setHealth then
        current = tonumber(bodyPart:getHealth()) or 100
        bodyPart:setHealth(math.max(0, current - healthLoss))
        applied = true
    end
    if not applied and bodyDamage and bodyDamage.getOverallBodyHealth and bodyDamage.setOverallBodyHealth then
        current = tonumber(bodyDamage:getOverallBodyHealth()) or 100
        bodyDamage:setOverallBodyHealth(math.max(0, current - healthLoss))
        applied = true
    end
    if not applied and player.getHealth and player.setHealth then
        current = tonumber(player:getHealth()) or 1
        player:setHealth(math.max(0, current - (healthLoss / 100)))
        applied = true
    end
    if not applied then return false end
    addPlayerWound(bodyPart, hit)
    if bodyDamage and bodyDamage.Update then
        bodyDamage:Update()
    end
    if type(sendPlayerStatsChange) == "function" then
        sendPlayerStatsChange(player)
    end
    hit.healthLoss = healthLoss
    return applied, hit
end

return Resolution
