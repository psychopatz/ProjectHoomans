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

function Math.IsGenderCompatible(profile, ownerGender, targetGender)
    profile = Types.NormalizePlayerSocialProfile(profile)
    ownerGender = normalizedGender(ownerGender)
    targetGender = normalizedGender(targetGender)
    if not ownerGender or not targetGender then
        return false
    end
    if profile.orientation == Constants.ORIENTATION_BISEXUAL then
        return true
    end
    if profile.orientation == Constants.ORIENTATION_GAY then
        return ownerGender == targetGender
    end
    return ownerGender ~= targetGender
end

function Math.AreMutuallyOrientationCompatible(
    profileA,
    genderA,
    profileB,
    genderB
)
    return Math.IsGenderCompatible(profileA, genderA, genderB)
        and Math.IsGenderCompatible(profileB, genderB, genderA)
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
    end

    if eventType == "survived_combat_together" then
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
