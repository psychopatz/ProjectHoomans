-- Pure retention policy for NPCs recruited into a player faction.
-- Recruitment and departure are intentionally separate decisions: a green
-- recruitment score must never silently become a retention guarantee.

PNC = PNC or {}
PNC.ColonistDeparturePolicy = PNC.ColonistDeparturePolicy or {}

local Policy = PNC.ColonistDeparturePolicy
local Config = PNC.Config and PNC.Config.Relationships or {}

Policy.VERSION = 1
Policy.DEFAULT_APPROVAL_THRESHOLD = -60
Policy.DEFAULT_RESPECT_THRESHOLD = -60
Policy.DEFAULT_RECOVERY_APPROVAL = -45
Policy.DEFAULT_RECOVERY_RESPECT = -45
Policy.DEFAULT_LOYALTY_TOLERANCE = 15
Policy.DEFAULT_BRAVERY_RESPECT_PRESSURE = 8
Policy.DEFAULT_CONFIRMATION_CHECKS = 2

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, finite(value, minimum)))
end

local function unit(value)
    return clamp(value, 0, 1)
end

local function configured(name, fallback)
    local value = Config and Config[name]
    return value == nil and fallback or finite(value, fallback)
end

local function modifier(id, label, value)
    return {
        id = tostring(id),
        label = tostring(label),
        value = finite(value, 0),
    }
end

-- The returned threshold is the authoritative red line. Both axes must be at
-- or below their line before departure can be committed.
function Policy.Evaluate(approval, respect, personality, context)
    personality = type(personality) == "table" and personality or {}
    context = type(context) == "table" and context or {}
    local loyalty = unit(personality.loyalty)
    local bravery = unit(personality.bravery)
    local baseApproval = finite(
        context.approvalThreshold,
        configured("COLONIST_DEPARTURE_APPROVAL_THRESHOLD",
            Policy.DEFAULT_APPROVAL_THRESHOLD)
    )
    local baseRespect = finite(
        context.respectThreshold,
        configured("COLONIST_DEPARTURE_RESPECT_THRESHOLD",
            Policy.DEFAULT_RESPECT_THRESHOLD)
    )
    local recoveryApproval = finite(
        context.recoveryApproval,
        configured("COLONIST_DEPARTURE_RECOVERY_APPROVAL",
            Policy.DEFAULT_RECOVERY_APPROVAL)
    )
    local recoveryRespect = finite(
        context.recoveryRespect,
        configured("COLONIST_DEPARTURE_RECOVERY_RESPECT",
            Policy.DEFAULT_RECOVERY_RESPECT)
    )
    local loyaltyTolerance = math.max(0, finite(
        context.loyaltyTolerance,
        configured("COLONIST_DEPARTURE_LOYALTY_TOLERANCE",
            Policy.DEFAULT_LOYALTY_TOLERANCE)
    ))
    local braveryPressure = math.max(0, finite(
        context.braveryRespectPressure,
        configured("COLONIST_DEPARTURE_BRAVERY_RESPECT_PRESSURE",
            Policy.DEFAULT_BRAVERY_RESPECT_PRESSURE)
    ))
    local approvalThreshold = clamp(
        baseApproval - loyalty * loyaltyTolerance, -100, -1
    )
    local respectThreshold = clamp(
        baseRespect + bravery * braveryPressure, -100, -1
    )
    local recoveryApprovalThreshold = clamp(
        recoveryApproval - loyalty * loyaltyTolerance, -100, -1
    )
    local recoveryRespectThreshold = clamp(
        recoveryRespect + bravery * braveryPressure, -100, -1
    )
    local currentApproval = finite(approval, 0)
    local currentRespect = finite(respect, 0)
    return {
        version = Policy.VERSION,
        approval = currentApproval,
        respect = currentRespect,
        loyalty = loyalty,
        bravery = bravery,
        approvalThreshold = approvalThreshold,
        respectThreshold = respectThreshold,
        recoveryApprovalThreshold = recoveryApprovalThreshold,
        recoveryRespectThreshold = recoveryRespectThreshold,
        bothAxesRequired = true,
        eligible = currentApproval <= approvalThreshold
            and currentRespect <= respectThreshold,
        recoverable = currentApproval > recoveryApprovalThreshold
            or currentRespect > recoveryRespectThreshold,
        confirmationChecks = math.max(1, math.floor(finite(
            context.confirmationChecks,
            configured("COLONIST_DEPARTURE_CONFIRMATION_CHECKS",
                Policy.DEFAULT_CONFIRMATION_CHECKS)
        ))),
        modifiers = {
            modifier(
                "loyalty_tolerance",
                "Loyalty makes them endure lower approval",
                -loyalty * loyaltyTolerance
            ),
            modifier(
                "bravery_self_respect",
                "Bravery makes disrespect less tolerable",
                bravery * braveryPressure
            ),
        },
    }
end

function Policy.CopyPreview(evaluation)
    if type(evaluation) ~= "table" then return nil end
    local modifiers = {}
    for _, item in ipairs(evaluation.modifiers or {}) do
        modifiers[#modifiers + 1] = {
            id = tostring(item.id or ""),
            label = tostring(item.label or ""),
            value = finite(item.value, 0),
        }
    end
    return {
        version = evaluation.version,
        approvalThreshold = finite(evaluation.approvalThreshold, -60),
        respectThreshold = finite(evaluation.respectThreshold, -60),
        recoveryApprovalThreshold = finite(
            evaluation.recoveryApprovalThreshold, -45
        ),
        recoveryRespectThreshold = finite(
            evaluation.recoveryRespectThreshold, -45
        ),
        bothAxesRequired = evaluation.bothAxesRequired == true,
        confirmationChecks = math.max(
            1, math.floor(finite(evaluation.confirmationChecks, 2))
        ),
        modifiers = modifiers,
    }
end

return Policy
