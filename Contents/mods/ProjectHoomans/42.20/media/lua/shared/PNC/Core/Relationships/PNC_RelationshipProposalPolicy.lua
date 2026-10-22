-- Shared romance proposal policy.
PNC = PNC or {}
PNC.RelationshipProposalPolicy = PNC.RelationshipProposalPolicy or {}
local Policy = PNC.RelationshipProposalPolicy
local Constants = PNC.RelationshipConstants
local Identity = PNC.Identity

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

local function surplus(value, threshold, multiplier, maximum)
    return math.min(maximum,
        math.max(0, finite(value, 0) - threshold) * multiplier)
end

function Policy.ActionID()
    return Constants.RELATIONSHIP_PROPOSAL_ACTION
end

function Policy.CooldownType()
    return Constants.RELATIONSHIP_PROPOSAL_COOLDOWN_TYPE
end

function Policy.CooldownHours(style)
    style = tostring(style or "neutral")
    if style == "reserved" then
        return Constants.RELATIONSHIP_PROPOSAL_COOLDOWN_HOURS * 2
    end
    if style == "flirty" then
        return Constants.RELATIONSHIP_PROPOSAL_COOLDOWN_HOURS * 0.5
    end
    return Constants.RELATIONSHIP_PROPOSAL_COOLDOWN_HOURS
end

function Policy.EvaluateEligibility(relationship, bond, compatible, available, at)
    relationship = type(relationship) == "table" and relationship or {}
    bond = type(bond) == "table" and bond or { class = "none" }
    at = math.max(0, finite(at, 0))
    local cooldownUntil = relationship.cooldowns
        and finite(relationship.cooldowns[Policy.CooldownType()], nil)
        or nil
    local result = {
        action = Policy.ActionID(),
        eligible = false,
        compatible = compatible == true,
        available = available == true,
        cooldownUntil = cooldownUntil,
        cooldownRemaining = cooldownUntil
            and math.max(0, cooldownUntil - at) or 0,
        thresholds = {
            approval = Constants.RELATIONSHIP_PROPOSAL_APPROVAL_ENTER,
            respect = Constants.RELATIONSHIP_PROPOSAL_RESPECT_ENTER,
            familiarity = Constants.RELATIONSHIP_PROPOSAL_FAMILIARITY_ENTER,
        },
    }
    if bond.class == "family" then
        result.reason = "family_excluded"
        return result
    end
    if bond.class ~= "friend" then
        result.reason = bond.class == "lover"
            and "already_lover" or "friend_bond_required"
        return result
    end
    if tostring(relationship.state or "unknown") == "rival"
        or tostring(relationship.state or "unknown") == "enemy"
    then
        result.reason = "standing_blocked"
        return result
    end
    if finite(relationship.approval, 0)
        < Constants.RELATIONSHIP_PROPOSAL_APPROVAL_ENTER
    then
        result.reason = "approval_threshold"
        return result
    end
    if finite(relationship.respect, 0)
        < Constants.RELATIONSHIP_PROPOSAL_RESPECT_ENTER
    then
        result.reason = "respect_threshold"
        return result
    end
    if finite(relationship.familiarity, 0)
        < Constants.RELATIONSHIP_PROPOSAL_FAMILIARITY_ENTER
    then
        result.reason = "familiarity_threshold"
        return result
    end
    if not result.compatible then
        result.reason = "orientation_incompatible"
        return result
    end
    if not result.available then
        result.reason = "actor_unavailable"
        return result
    end
    if cooldownUntil and at < cooldownUntil then
        result.reason = "proposal_cooldown"
        return result
    end
    result.eligible = true
    result.reason = "available"
    return result
end

function Policy.AcceptanceProbability(relationship, npcProfile)
    relationship = type(relationship) == "table" and relationship or {}
    npcProfile = type(npcProfile) == "table" and npcProfile or {}
    local probability = Constants.RELATIONSHIP_PROPOSAL_ACCEPTANCE_BASE
    probability = probability
        + surplus(relationship.approval,
            Constants.RELATIONSHIP_PROPOSAL_APPROVAL_ENTER, 0.003, 0.06)
        + surplus(relationship.respect,
            Constants.RELATIONSHIP_PROPOSAL_RESPECT_ENTER, 0.002, 0.06)
        + surplus(relationship.familiarity,
            Constants.RELATIONSHIP_PROPOSAL_FAMILIARITY_ENTER, 0.0015, 0.03)
    if npcProfile.romanceStyle == "flirty" then
        probability = probability + Constants.RELATIONSHIP_PROPOSAL_FLIRTY_BONUS
    elseif npcProfile.romanceStyle == "reserved" then
        probability = probability - Constants.RELATIONSHIP_PROPOSAL_RESERVED_PENALTY
    end
    if npcProfile.socialStyle == "friendly" then
        probability = probability + 0.05
    elseif npcProfile.socialStyle == "withdrawn" then
        probability = probability - 0.05
    end
    return clamp(probability,
        Constants.RELATIONSHIP_PROPOSAL_ACCEPTANCE_MIN,
        Constants.RELATIONSHIP_PROPOSAL_ACCEPTANCE_MAX)
end

function Policy.Roll(seed, salt)
    if Identity and type(Identity.Float) == "function" then
        return clamp(Identity.Float(seed, salt), 0, 1)
    end
    local value = 5381
    local source = tostring(seed or "") .. ":" .. tostring(salt or "")
    for index = 1, #source do
        value = (value * 33 + string.byte(source, index)) % 2147483646
    end
    return value / 2147483646
end

function Policy.EvaluateAcceptance(seed, salt, relationship, npcProfile)
    local probability = Policy.AcceptanceProbability(relationship, npcProfile)
    local roll = Policy.Roll(seed, salt)
    return {
        accepted = roll <= probability,
        probability = probability,
        roll = roll,
        romanceStyle = npcProfile and npcProfile.romanceStyle or "neutral",
    }
end

return Policy
