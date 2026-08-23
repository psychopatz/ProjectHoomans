PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

function Wounds.GetClothingProfile(npcBody, part, damageType)
    local remainingRisk = 1
    local partId = part and tostring(part.id or part) or nil
    local layers = {}
    local bestLayer
    local bestContribution = 0
    if not npcBody or not partId then
        return { protection = 0, blockChance = 0, layers = layers }
    end
    damageType = string.lower(tostring(damageType or "bite"))
    local worn = npcBody.getWornItems and npcBody:getWornItems() or nil
    local count = 0
    local i
    local entry
    local item
    local defense
    local ratio
    local effectiveDefense
    local exponent = Internal.SettingNumber(
        "NPCZombieClothingConditionExponent", 1.15, 0.1, 3
    )
    if worn and worn.size and worn.get then
        for i = 0, worn:size() - 1 do
            entry = worn:get(i)
            item = entry and entry.getItem and entry:getItem() or entry
            defense = Internal.ItemCoversPart(item, entry, partId)
                and Internal.ReadDefense(item, damageType) or nil
            if defense then
                ratio = Internal.ConditionRatio(item)
                effectiveDefense = Core.Clamp(defense, 0, 100) / 100
                    * (ratio ^ exponent)
                effectiveDefense = Core.Clamp(effectiveDefense, 0, 1)
                remainingRisk = remainingRisk * (1 - effectiveDefense)
                count = count + 1
                layers[#layers + 1] = {
                    item = item,
                    entry = entry,
                    defense = Core.Clamp(defense, 0, 100),
                    conditionRatio = ratio,
                    contribution = effectiveDefense,
                }
                if effectiveDefense > bestContribution then
                    bestContribution = effectiveDefense
                    bestLayer = layers[#layers]
                end
            end
        end
    end
    local protection = count > 0
        and Core.Clamp((1 - remainingRisk) * 100, 0, 100) or 0
    local blockChance = protection / 100 * Internal.SettingNumber(
        "NPCZombieClothingBlockMultiplier", 1, 0, 2
    )
    return {
        protection = protection,
        blockChance = Core.Clamp(blockChance, 0, 1),
        layers = layers,
        bestLayer = bestLayer,
    }
end

function Wounds.GetProtection(npcBody, part, damageType)
    local profile = Wounds.GetClothingProfile(npcBody, part, damageType)
    return profile and tonumber(profile.protection) or 0
end

function Internal.WoundAfterProtection(woundType, protection)
    local lacerationThreshold = Internal.SettingNumber(
        "NPCZombieClothingDowngradeLaceration", 25, 0, 100
    )
    local scratchThreshold = math.max(
        lacerationThreshold,
        Internal.SettingNumber(
            "NPCZombieClothingDowngradeScratch", 60, 0, 100
        )
    )
    protection = tonumber(protection) or 0
    if protection >= scratchThreshold
        and (woundType == "bite" or woundType == "laceration")
    then
        return "scratch"
    end
    if protection >= lacerationThreshold then
        if woundType == "bite" then return "laceration" end
        if woundType == "laceration" then return "scratch" end
    end
    return woundType
end

local function sacrificeClothing(layer, amount)
    local item = layer and layer.item or nil
    if not item or amount <= 0
        or not item.getCondition or not item.setCondition
    then
        return 0, nil, nil
    end
    local before = tonumber(item:getCondition()) or 0
    local maximum = math.max(0, tonumber(
        item.getConditionMax and item:getConditionMax() or before
    ) or before)
    local after = math.max(0, math.min(maximum, before - amount))
    if after ~= before then item:setCondition(math.floor(after)) end
    return before - after, before, after
end

function Wounds.ResolveZombieClothing(npcBody, part, woundType)
    local profile = Wounds.GetClothingProfile(npcBody, part, woundType)
    local roll = Internal.RandomPercent() / 100
    local blocked = roll < (tonumber(profile.blockChance) or 0)
    local loss = blocked
        and Internal.SettingNumber(
            "NPCZombieClothingSafeDurabilityLoss", 1, 0, 100
        )
        or Internal.SettingNumber(
            "NPCZombieClothingPenetratingDurabilityLoss", 2, 0, 100
        )
    local durabilityLoss
    local conditionBefore
    local conditionAfter
    if profile.bestLayer then
        durabilityLoss, conditionBefore, conditionAfter =
            sacrificeClothing(profile.bestLayer, loss)
    else
        durabilityLoss = 0
    end
    return {
        outcome = blocked and "clothing_blocked"
            or "clothing_penetrated",
        blocked = blocked,
        initialWoundType = woundType,
        finalWoundType = not blocked
            and Internal.WoundAfterProtection(
                woundType, profile.protection
            ) or nil,
        protection = profile.protection,
        blockChance = profile.blockChance,
        roll = roll,
        durabilityLoss = durabilityLoss,
        conditionBefore = conditionBefore,
        conditionAfter = conditionAfter,
        item = profile.bestLayer and profile.bestLayer.item or nil,
    }
end

return Wounds
