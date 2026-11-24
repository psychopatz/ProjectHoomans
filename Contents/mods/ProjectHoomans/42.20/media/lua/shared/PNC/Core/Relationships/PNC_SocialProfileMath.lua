-- Pure compatibility and social-event interpretation helpers.

PNC = PNC or {}
PNC.SocialProfileMath = PNC.SocialProfileMath or {}

local Math = PNC.SocialProfileMath
local Constants = PNC.SocialProfileConstants
local Types = PNC.SocialProfileTypes

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = tonumber(fallback) or 0
    end
    return value
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, finite(value, 0)))
end

local function round(value)
    value = finite(value, 0)
    if value < 0 then
        return math.ceil(value * 100 - 0.5) / 100
    end
    return math.floor(value * 100 + 0.5) / 100
end

local function scalePositive(value, multiplier)
    value = finite(value, 0)
    if value <= 0 then
        return value
    end
    return value * multiplier
end

local function scaleNegative(value, multiplier)
    value = finite(value, 0)
    if value >= 0 then
        return value
    end
    return value * multiplier
end

local function normalizedGender(value)
    if value == true or value == "female" then
        return "female"
    end
    if value == false or value == "male" then
        return "male"
    end
    return nil
end

local function combatDamageScale(eventType, eventSpec)
    local context
    local damage
    local unit
    if eventType ~= "witnessed_player_hurt"
        and eventType ~= "player_damaged_npc"
        and eventType ~= "faction_member_attacked"
    then
        return 1
    end
    context = type(eventSpec) == "table" and eventSpec.context or nil
    damage = tonumber(context and (context.damage or context.healthLoss))
    if not damage or damage <= 0 then
        return 1
    end
    unit = eventType == "witnessed_player_hurt" and 8 or 10
    return clamp(damage / unit, 0.25, 4)
end

function Math.KinseyScore(profile)
    local normalized = Types.NormalizePlayerSocialProfile(profile)
    if tonumber(normalized.kinsey) ~= nil then
        return clamp(math.floor(normalized.kinsey + 0.5), 0, 6)
    end
    if normalized.orientation == Constants.ORIENTATION_GAY then return 6 end
    if normalized.orientation == Constants.ORIENTATION_BISEXUAL then return 3 end
    return 0
end

function Math.AttractionWeight(profile, ownerGender, targetGender)
    ownerGender = normalizedGender(ownerGender)
    targetGender = normalizedGender(targetGender)
    if not ownerGender or not targetGender then
        return 0
    end
    local kinsey = Math.KinseyScore(profile)
    if ownerGender == targetGender then
        return round(kinsey / 6)
    end
    return round((6 - kinsey) / 6)
end

function Math.MutualAttractionWeight(profileA, genderA, profileB, genderB)
    local weightA = Math.AttractionWeight(profileA, genderA, genderB)
    local weightB = Math.AttractionWeight(profileB, genderB, genderA)
    if weightA <= 0 or weightB <= 0 then
        return 0
    end
    return round(math.sqrt(weightA * weightB))
end

function Math.IsGenderCompatible(profile, ownerGender, targetGender)
    return Math.AttractionWeight(profile, ownerGender, targetGender) > 0
end

function Math.AreMutuallyOrientationCompatible(
    profileA,
    genderA,
    profileB,
    genderB
)
    return Math.MutualAttractionWeight(profileA, genderA, profileB, genderB) > 0
end

function Math.PersonalityChemistry(profileA, profileB)
    local a = type(profileA) == "table" and profileA or {}
    local b = type(profileB) == "table" and profileB or {}
    local compassionDiff = math.abs(finite(a.compassion, 0.5) - finite(b.compassion, 0.5))
    local sociabilityAvg = (finite(a.sociability, 0.5) + finite(b.sociability, 0.5)) * 0.5
    local aggressionAvg = (finite(a.aggression, 0.5) + finite(b.aggression, 0.5)) * 0.5
    local loyaltyAvg = (finite(a.loyalty, 0.5) + finite(b.loyalty, 0.5)) * 0.5
    local score = (0.5 - compassionDiff) * 0.7
        + (sociabilityAvg - 0.5) * 0.6
        + (loyaltyAvg - 0.5) * 0.4
        - (aggressionAvg - 0.5) * 0.7
    if a.socialStyle == "friendly" or b.socialStyle == "friendly" then
        score = score + 0.12
    end
    if a.socialStyle == "withdrawn" and b.socialStyle == "withdrawn" then
        score = score - 0.10
    end
    return round(clamp(score, -1, 1))
end

function Math.ModifySocialEvent(
    observerProfile,
    eventDefinition,
    eventSpec,
    baseEffects
)
    local profile = Types.NormalizeNPCPersonality(
        observerProfile,
        1,
        "General"
    )
    local eventType = tostring(
        type(eventSpec) == "table" and eventSpec.type
            or type(eventDefinition) == "table"
                and eventDefinition.id or ""
    )
    local effects = {
        approvalEffect = finite(
            baseEffects and baseEffects.approvalEffect,
            0
        ),
        respectEffect = finite(
            baseEffects and baseEffects.respectEffect,
            0
        ),
        moraleEffect = finite(
            baseEffects and baseEffects.moraleEffect,
            0
        ),
        familiarityGain = finite(
            baseEffects and baseEffects.familiarityGain,
            0
        ),
    }
    local breakdown = {}
    local factor
    local damageScale = combatDamageScale(eventType, eventSpec)

    if damageScale ~= 1 then
        effects.approvalEffect = effects.approvalEffect * damageScale
        effects.respectEffect = effects.respectEffect * damageScale
        effects.moraleEffect = effects.moraleEffect * damageScale
        breakdown.combatDamage = damageScale
    end

    if eventType == "treated_wound"
        or eventType == "saved_from_incapacitation"
    then
        factor = 0.85 + profile.compassion * 0.30
        effects.approvalEffect = scalePositive(
            effects.approvalEffect,
            factor
        )
        effects.moraleEffect = scalePositive(
            effects.moraleEffect,
            factor
        )
        breakdown.compassion = factor
    elseif eventType == "protected_from_attacker"
        or eventType == "survived_combat_together"
        or eventType == "survived_horde_attack"
    then
        factor = 1.15 - profile.bravery * 0.30
        effects.approvalEffect = scalePositive(
            effects.approvalEffect,
            factor
        )
        effects.moraleEffect = scalePositive(
            effects.moraleEffect,
            factor
        )
        breakdown.braveryProtection = factor
        factor = 0.85 + profile.bravery * 0.30
        effects.respectEffect = scalePositive(
            effects.respectEffect,
            factor
        )
        breakdown.braveryRespect = factor
        local ctx = type(eventSpec) == "table" and type(eventSpec.context) == "table" and eventSpec.context or nil
        local threatCount = ctx and math.floor(tonumber(ctx.threatCount or ctx.killsByHelper) or 1) or 1
        if threatCount > 1 then
            local threatScale = math.min(2.25, 1.0 + math.min(threatCount - 1, 10) * 0.125)
            effects.approvalEffect = scalePositive(effects.approvalEffect, threatScale)
            effects.respectEffect = scalePositive(effects.respectEffect, threatScale)
            effects.moraleEffect = scalePositive(effects.moraleEffect, threatScale)
            effects.familiarityGain = scalePositive(effects.familiarityGain, threatScale)
            breakdown.threatScale = threatScale
        end
    end

    if eventType == "survived_combat_together"
        or eventType == "survived_horde_attack"
    then
        factor = 0.90 + profile.loyalty * 0.20
        effects.approvalEffect = scalePositive(
            effects.approvalEffect,
            factor
        )
        effects.respectEffect = scalePositive(
            effects.respectEffect,
            factor
        )
        effects.moraleEffect = scalePositive(
            effects.moraleEffect,
            factor
        )
        breakdown.loyalty = factor
    elseif eventType == "abandoned_in_combat" then
        factor = 0.80 + profile.loyalty * 0.45
        effects.approvalEffect = scaleNegative(
            effects.approvalEffect,
            factor
        )
        effects.respectEffect = scaleNegative(
            effects.respectEffect,
            factor
        )
        effects.moraleEffect = scaleNegative(
            effects.moraleEffect,
            factor
        )
        breakdown.loyalty = factor
        factor = 1.25 - profile.forgiveness * 0.50
        effects.approvalEffect = scaleNegative(
            effects.approvalEffect,
            factor
        )
        effects.respectEffect = scaleNegative(
            effects.respectEffect,
            factor
        )
        breakdown.forgiveness = factor
    end

    if eventType == "player_emote_insult"
        or eventType == "player_dialogue_hostile_remark"
        or eventType == "player_dialogue_insult"
        or eventType == "player_dialogue_threat"
    then
        factor = 1.25 - profile.forgiveness * 0.50
        effects.approvalEffect = scaleNegative(
            effects.approvalEffect,
            factor
        )
        effects.respectEffect = scaleNegative(
            effects.respectEffect,
            factor
        )
        effects.moraleEffect = scaleNegative(
            effects.moraleEffect,
            factor
        )
        breakdown.forgiveness = factor
    end

    if profile.socialStyle == Constants.SOCIAL_FRIENDLY then
        effects.approvalEffect = scalePositive(
            effects.approvalEffect,
            1.10
        )
        effects.familiarityGain = effects.familiarityGain * 1.10
        breakdown.socialApproval = 1.10
        breakdown.socialFamiliarity = 1.10
    elseif profile.socialStyle == Constants.SOCIAL_WITHDRAWN then
        effects.approvalEffect = scalePositive(
            effects.approvalEffect,
            0.90
        )
        effects.familiarityGain = effects.familiarityGain * 0.80
        breakdown.socialApproval = 0.90
        breakdown.socialFamiliarity = 0.80
    end

    effects.approvalEffect = clamp(
        round(effects.approvalEffect),
        -100,
        100
    )
    effects.respectEffect = clamp(
        round(effects.respectEffect),
        -100,
        100
    )
    effects.moraleEffect = clamp(
        round(effects.moraleEffect),
        -100,
        100
    )
    effects.familiarityGain = clamp(
        round(effects.familiarityGain),
        0,
        100
    )
    return effects, breakdown
end

return Math
