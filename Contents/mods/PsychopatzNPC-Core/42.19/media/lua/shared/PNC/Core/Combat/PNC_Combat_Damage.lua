-- Central server-authoritative combat damage, ammo, condition, and wound rules.

PNC = PNC or {}
PNC.CombatDamage = PNC.CombatDamage or {}

local Damage = PNC.CombatDamage
local Inventory = PNC.Inventory

local function sandbox()
    return SandboxVars and SandboxVars.PsychopatzNPCCore or nil
end

local function enabled(key, fallback)
    local vars = sandbox()
    if vars and vars[key] ~= nil then
        return vars[key] == true
    end
    return fallback == true
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function roll(minimum, maximum)
    if ZombRandFloat then
        return ZombRandFloat(minimum, maximum)
    end
    return (minimum + maximum) * 0.5
end

function Damage.IsWeaponDamageEnabled()
    return enabled("EnableWeaponDamage", true)
end

function Damage.IsAmmoConsumptionEnabled()
    return enabled("NPCAmmoConsumption", false)
end

function Damage.IsWeaponConditionEnabled()
    return enabled("NPCWeaponConditionLoss", false)
end

function Damage.ArePlayerWoundsEnabled()
    return enabled("NPCPlayerWounds", true)
end

function Damage.RollWeaponDamage(weaponItem, fallback)
    local minimum
    local maximum
    if not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    minimum = weaponItem.getMinDamage and tonumber(weaponItem:getMinDamage()) or nil
    maximum = weaponItem.getMaxDamage and tonumber(weaponItem:getMaxDamage()) or nil
    minimum = minimum and minimum > 0 and minimum or maximum or tonumber(fallback) or 0.5
    maximum = maximum and maximum >= minimum and maximum or minimum
    return roll(minimum, maximum)
end

function Damage.GetAttackDamage(record, attackType, weaponItem, fallback, skillLevel)
    local vars
    local base
    local normalized
    local attackMultiplier
    local dealtMultiplier
    if not Damage.IsWeaponDamageEnabled() or not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    base = Damage.RollWeaponDamage(weaponItem, fallback)
    normalized = clamp(skillLevel, 0, 10) / 10
    if attackType == "ranged" then
        attackMultiplier = 15 + (10 * normalized)
    else
        attackMultiplier = 8 + (6 * normalized)
    end
    vars = sandbox()
    dealtMultiplier = math.max(0, tonumber(vars and vars.NPCDamageDealtMultiplier) or 1)
    return base * attackMultiplier * dealtMultiplier
end

local function equippedInventoryItem(record)
    local inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    local itemID = inv and inv.equipped and inv.equipped.primary or nil
    return inv, itemID, itemID and inv.items and inv.items[itemID] or nil
end

function Damage.ConsumeAmmo(record, weaponItem)
    local inv
    local ammoType
    local itemID
    local item
    if not Damage.IsAmmoConsumptionEnabled() then
        return true, "ammo_disabled"
    end
    ammoType = weaponItem and weaponItem.getAmmoType and weaponItem:getAmmoType() or nil
    if not ammoType or ammoType == "" then
        return true, "ammo_not_required"
    end
    inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    if not inv then
        return false, "inventory_unavailable"
    end
    for itemID, item in pairs(inv.items or {}) do
        if item and item.type == ammoType then
            if (tonumber(item.stack) or 1) > 1 then
                Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, stack = item.stack - 1 }}, "combat_ammo")
            else
                Inventory.ApplyDelta(record, {{ op = "remove", itemID = itemID }}, "combat_ammo")
            end
            return true, "ammo_consumed"
        end
    end
    return false, "out_of_ammo"
end

function Damage.ApplyWeaponConditionLoss(record, weaponItem)
    local inv
    local itemID
    local item
    local condition
    local lowerChance
    if not Damage.IsWeaponConditionEnabled() or not weaponItem then
        return false
    end
    inv, itemID, item = equippedInventoryItem(record)
    if not inv or not itemID or not item then
        return false
    end
    lowerChance = weaponItem.getConditionLowerChance and tonumber(weaponItem:getConditionLowerChance()) or 1
    lowerChance = math.max(1, math.floor(lowerChance or 1))
    if ZombRand and ZombRand(lowerChance) ~= 0 then
        return false
    end
    condition = tonumber(item.cond)
        or (weaponItem.getCondition and tonumber(weaponItem:getCondition()))
        or (weaponItem.getConditionMax and tonumber(weaponItem:getConditionMax()))
        or 1
    condition = math.max(0, condition - 1)
    return Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, cond = condition }}, "combat_condition") == true
end

local function chooseBodyPart(bodyDamage)
    local candidates
    local index
    if not bodyDamage or not bodyDamage.getBodyPart or not BodyPartType then
        return nil
    end
    candidates = {
        BodyPartType.Torso_Upper, BodyPartType.Torso_Upper,
        BodyPartType.Torso_Lower, BodyPartType.UpperArm_L,
        BodyPartType.UpperArm_R, BodyPartType.UpperLeg_L,
        BodyPartType.UpperLeg_R, BodyPartType.Head,
    }
    index = ZombRand and (ZombRand(#candidates) + 1) or 1
    return bodyDamage:getBodyPart(candidates[index])
end

function Damage.ApplyPlayerDamage(player, amount, attackType, weaponItem)
    local bodyDamage
    local bodyPart
    local current
    local healthLoss
    local pain
    if not player or (tonumber(amount) or 0) <= 0 then
        return false
    end
    healthLoss = clamp((tonumber(amount) or 0) * (attackType == "ranged" and 0.42 or 0.34), 0.65, attackType == "ranged" and 22 or 16)
    bodyDamage = player.getBodyDamage and player:getBodyDamage() or nil
    if bodyDamage and bodyDamage.getOverallBodyHealth and bodyDamage.setOverallBodyHealth then
        current = tonumber(bodyDamage:getOverallBodyHealth()) or 100
        bodyDamage:setOverallBodyHealth(math.max(0, current - healthLoss))
    elseif player.getHealth and player.setHealth then
        current = tonumber(player:getHealth()) or 1
        player:setHealth(math.max(0, current - (healthLoss / 100)))
    else
        return false
    end
    if Damage.ArePlayerWoundsEnabled() then
        bodyPart = chooseBodyPart(bodyDamage)
        if bodyPart then
            pain = tonumber(bodyPart.getAdditionalPain and bodyPart:getAdditionalPain() or 0) or 0
            if bodyPart.setAdditionalPain then
                bodyPart:setAdditionalPain(math.min(100, pain + math.max(3, amount * 0.35)))
            end
            if attackType == "ranged" and bodyPart.setBleedingTime then
                bodyPart:setBleedingTime(math.max(tonumber(bodyPart.getBleedingTime and bodyPart:getBleedingTime() or 0) or 0, 45))
            elseif bodyPart.setScratchTime then
                bodyPart:setScratchTime(math.max(tonumber(bodyPart.getScratchTime and bodyPart:getScratchTime() or 0) or 0, 6))
            end
        end
    end
    if bodyDamage and bodyDamage.Update then
        bodyDamage:Update()
    end
    if player.sendPlayerStatsPacket then
        pcall(function() player:sendPlayerStatsPacket() end)
    end
    return true
end

