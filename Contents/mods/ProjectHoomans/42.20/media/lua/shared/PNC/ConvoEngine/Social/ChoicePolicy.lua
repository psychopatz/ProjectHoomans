-- Bounded NPC selection over an already-valid semantic affordance frontier.
-- This module chooses meaning only. It does not realize text or mutate gameplay.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Choice = PNC.ConvoEngine.SocialChoicePolicy or {}
PNC.ConvoEngine.SocialChoicePolicy = Choice

local DispositionProjection = PNC.ConvoEngine.DispositionProjection
    or require "PNC/ConvoEngine/DispositionProjection"

Choice.VERSION = 1
Choice.MAX_CANDIDATES = 8
Choice.DEFAULT_SILENCE_THRESHOLD = 0.50
Choice.MIN_RELEVANCE = 0.20

local AGGRESSIVE = {
    DOUBLE_DOWN = true,
    CHALLENGE = true,
    CALL_BLUFF = true,
    DISAGREE = true,
    DISMISS = true,
}
local REPAIR = {
    APOLOGIZE = true,
    CLAIM_JOKE = true,
    DEESCALATE = true,
    COMFORT = true,
    ACKNOWLEDGE = true,
    AGREE = true,
}
local CURIOUS = {
    ASK_WHY = true,
    ASK_FOLLOWUP = true,
}
local MOTIVE_PREFERENCE = {
    INFORM = { ACKNOWLEDGE = 0.20, ASK_FOLLOWUP = 0.12 },
    WARN = { ACKNOWLEDGE = 0.12, ASK_FOLLOWUP = 0.08, CHALLENGE = 0.05 },
    REQUEST = { AGREE = 0.22, DISAGREE = 0.18, ACKNOWLEDGE = 0.08 },
    CHECK = { COMFORT = 0.28, ASK_FOLLOWUP = 0.20, ACKNOWLEDGE = 0.10 },
    ACKNOWLEDGE = { ACKNOWLEDGE = 0.28, AGREE = 0.16 },
    REACT = { ACKNOWLEDGE = 0.12, CHALLENGE = 0.08, CLAIM_JOKE = 0.08 },
    SOCIALIZE = { ASK_FOLLOWUP = 0.24, ACKNOWLEDGE = 0.14, CLAIM_JOKE = 0.10 },
    DISPUTE = { DISAGREE = 0.22, CHALLENGE = 0.20, DOUBLE_DOWN = 0.16 },
    REPAIR = { APOLOGIZE = 0.28, DEESCALATE = 0.26, ACKNOWLEDGE = 0.14 },
    COORDINATE = { AGREE = 0.18, ACKNOWLEDGE = 0.16, ASK_FOLLOWUP = 0.12 },
}

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function normalizedSigned(value)
    value = tonumber(value) or 0
    if math.abs(value) > 1 then value = value / 100 end
    return clamp(value, -1, 1)
end

local function upper(value)
    return string.upper(tostring(value or ""))
end

local function projection(context)
    context = type(context) == "table" and context or {}
    local p = type(context.responderProjection) == "table"
        and context.responderProjection or {}
    local actor = type(p.actor) == "table" and p.actor
        or type(context.actor) == "table" and context.actor or {}
    local relationship = type(p.relationship) == "table" and p.relationship
        or type(context.relationship) == "table" and context.relationship or {}
    return actor, relationship
end

local function resolveEffectiveUnit(actor, context)
    local resolveOpts = {
        temporaryDemeanor = type(context) == "table"
            and context.temporaryDemeanor or nil,
        personality = type(context) == "table"
            and context.personality or nil,
    }
    if type(actor.effectiveDisposition) == "table" then
        resolveOpts.baseDisposition = actor.effectiveDisposition
        resolveOpts.condition = type(context) == "table"
            and context.condition or {}
    elseif actor.providerID == "projecthoomans.managed_npc"
        and type(actor.disposition) == "table"
    then
        -- Adapter already applied actor.condition to actor.disposition.
        resolveOpts.baseDisposition = actor.disposition
        resolveOpts.condition = type(context) == "table"
            and context.condition or {}
    elseif type(context) == "table" and type(context.condition) == "table" then
        resolveOpts.condition = context.condition
    end
    local resolved = DispositionProjection.Resolve(actor, resolveOpts)
    return DispositionProjection.ToUnitDisposition(resolved.effectiveDisposition)
end

local function candidateAllowed(candidate, context)
    if type(candidate) ~= "table" then return false, "candidate_invalid" end
    local strategy = upper(candidate.strategy)
    if strategy == "" then return false, "strategy_missing" end
    local eligibility = type(candidate.eligibility) == "table"
        and candidate.eligibility or {}
    if eligibility.allowed == false or eligibility.status == "rejected" then
        return false, eligibility.reason or "candidate_rejected"
    end
    local forbidden = type(context.forbiddenStrategies) == "table"
        and context.forbiddenStrategies or {}
    if forbidden[strategy] == true then
        return false, "strategy_forbidden"
    end
    local allowed = type(context.allowedStrategies) == "table"
        and context.allowedStrategies or nil
    if allowed and allowed[strategy] ~= true then
        return false, "strategy_not_allowed"
    end
    local actor = projection(context)
    local capabilities = type(actor.capabilities) == "table"
        and actor.capabilities or {}
    if capabilities.speech == false then
        return false, "speech_unavailable"
    end
    return true, "eligible"
end

local function scoreCandidate(candidate, context)
    local actor, relationship = projection(context)
    local strategy = upper(candidate.strategy)
    local score = 0.45
    local modifiers = {}

    local d = resolveEffectiveUnit(actor, context)
    local aggression = d.aggression
    local confidence = d.confidence
    local bravery = d.bravery
    local compassion = d.compassion
    local forgiveness = d.forgiveness
    local sociability = d.sociability
    local loyalty = d.loyalty

    if AGGRESSIVE[strategy] then
        local delta = (aggression - 0.5) * 0.32
            + (confidence - 0.5) * 0.18
        score = score + delta
        modifiers[#modifiers + 1] = {
            reason = "aggressive_disposition",
            delta = delta,
        }
    elseif REPAIR[strategy] then
        local delta = (compassion - 0.5) * 0.28
            + (forgiveness - 0.5) * 0.18
        score = score + delta
        modifiers[#modifiers + 1] = {
            reason = "repair_disposition",
            delta = delta,
        }
    elseif CURIOUS[strategy] then
        local delta = (sociability - 0.5) * 0.24
            + (compassion - 0.5) * 0.08
        score = score + delta
        modifiers[#modifiers + 1] = {
            reason = "curiosity_disposition",
            delta = delta,
        }
    end

    local approval = normalizedSigned(relationship.approval)
    local respect = normalizedSigned(relationship.respect)
    local relation = (approval + respect) * 0.5
    local stance = upper(candidate.stance)
    if stance == "POSITIVE" then
        local delta = relation * 0.16
        score = score + delta
        modifiers[#modifiers + 1] = {
            reason = "positive_relationship_fit",
            delta = delta,
        }
    elseif stance == "NEGATIVE" then
        local delta = -relation * 0.14
        score = score + delta
        modifiers[#modifiers + 1] = {
            reason = "negative_relationship_fit",
            delta = delta,
        }
    end

    local motive = upper(context.motive)
    local motiveTable = MOTIVE_PREFERENCE[motive] or {}
    local motiveDelta = tonumber(motiveTable[strategy]) or 0
    if motiveDelta ~= 0 then
        score = score + motiveDelta
        modifiers[#modifiers + 1] = {
            reason = "motive_fit:" .. motive,
            delta = motiveDelta,
        }
    end

    if strategy == "CALL_BLUFF" or strategy == "CHALLENGE" then
        local courageDelta = ((bravery + confidence) * 0.5 - 0.5) * 0.18
        if courageDelta ~= 0 then
            score = score + courageDelta
            modifiers[#modifiers + 1] = {
                reason = "courage_disposition",
                delta = courageDelta,
            }
        end
    elseif strategy == "COMFORT" or strategy == "DEESCALATE" then
        local careDelta = (compassion - 0.5) * 0.14
            + (loyalty - 0.5) * 0.08
        if careDelta ~= 0 then
            score = score + careDelta
            modifiers[#modifiers + 1] = {
                reason = "care_disposition",
                delta = careDelta,
            }
        end
    end

    local relevance = clamp(context.relevance or 1, 0, 1)
    local relevanceDelta = (relevance - 0.5) * 0.20
    score = score + relevanceDelta
    modifiers[#modifiers + 1] = {
        reason = "opportunity_relevance",
        delta = relevanceDelta,
    }

    return score, modifiers
end

function Choice.Select(candidates, context)
    context = type(context) == "table" and context or {}
    candidates = type(candidates) == "table" and candidates or {}
    local relevance = clamp(context.relevance or 1, 0, 1)
    if context.forceSilence == true or relevance < Choice.MIN_RELEVANCE then
        return {
            schemaVersion = Choice.VERSION,
            selected = nil,
            selectedScore = nil,
            reason = context.forceSilence == true
                and "silence_forced" or "relevance_below_minimum",
            rows = {},
        }
    end

    local rows = {}
    for index = 1, math.min(#candidates, Choice.MAX_CANDIDATES) do
        local candidate = candidates[index]
        local allowed, reason = candidateAllowed(candidate, context)
        local row = {
            candidateID = type(candidate) == "table"
                and candidate.id or nil,
            strategy = type(candidate) == "table"
                and upper(candidate.strategy) or nil,
            eligible = allowed == true,
            reason = reason,
            order = index,
        }
        if allowed then
            row.score, row.modifiers = scoreCandidate(candidate, context)
            row.candidate = candidate
        end
        rows[#rows + 1] = row
    end

    local eligible = {}
    for _, row in ipairs(rows) do
        if row.eligible then eligible[#eligible + 1] = row end
    end
    table.sort(eligible, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        local ls = tostring(left.strategy or left.candidateID or "")
        local rs = tostring(right.strategy or right.candidateID or "")
        if ls ~= rs then return ls < rs end
        return left.order < right.order
    end)

    local threshold = tonumber(context.silenceThreshold)
        or Choice.DEFAULT_SILENCE_THRESHOLD
    local winner = eligible[1]
    if not winner or winner.score < threshold then
        return {
            schemaVersion = Choice.VERSION,
            selected = nil,
            selectedScore = winner and winner.score or nil,
            reason = winner and "silence_threshold" or "no_eligible_affordance",
            rows = rows,
        }
    end

    return {
        schemaVersion = Choice.VERSION,
        selected = winner.candidate,
        selectedScore = winner.score,
        reason = "highest_contextual_affordance",
        rows = rows,
    }
end

return Choice
