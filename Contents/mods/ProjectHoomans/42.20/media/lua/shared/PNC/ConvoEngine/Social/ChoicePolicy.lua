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
    CONTRADICT = true,
    REFUSE_INTERVENTION = true,
}
local REPAIR = {
    APOLOGIZE = true,
    CLAIM_JOKE = true,
    DEESCALATE = true,
    COMFORT = true,
    ACKNOWLEDGE = true,
    AGREE = true,
    MEDIATE = true,
}
local CURIOUS = {
    ASK_WHY = true,
    ASK_FOLLOWUP = true,
    QUESTION_SOURCE = true,
}
local EPISTEMIC_CORROBORATE = {
    CORROBORATE = true,
    CONFIRM_FACT = true,
    REVEAL_SOURCE = true,
    ADD_FACT = true,
}
local EPISTEMIC_DOUBT = {
    CONTRADICT = true,
    EXPRESS_UNCERTAINTY = true,
    PROTECT_SOURCE = true,
    QUESTION_SOURCE = true,
}
local MEDIATION_AND_CARE = {
    MEDIATE = true,
    ACCEPT_TREATMENT = true,
    VOLUNTEER = true,
    NEGOTIATE = true,
    REQUEST_ESCORT = true,
    REROUTE = true,
}
local BOUNDARY_AND_WITHDRAWAL = {
    DEFEND = true,
    REFUSE_TREATMENT = true,
    REFUSE_UNSAFE_WORK = true,
    POSTPONE = true,
    WITHDRAW = true,
    REFUSE_INTERVENTION = true,
    END_CONVERSATION = true,
}
local MOTIVE_PREFERENCE = {
    INFORM = { ACKNOWLEDGE = 0.20, ASK_FOLLOWUP = 0.12, CORROBORATE = 0.16, ADD_FACT = 0.16, EXPRESS_UNCERTAINTY = 0.12, CONTRADICT = 0.14 },
    WARN = { ACKNOWLEDGE = 0.12, ASK_FOLLOWUP = 0.08, CHALLENGE = 0.05, REROUTE = 0.20, POSTPONE = 0.16, REFUSE_UNSAFE_WORK = 0.18, CORROBORATE = 0.14 },
    REQUEST = { AGREE = 0.22, DISAGREE = 0.18, ACKNOWLEDGE = 0.08, VOLUNTEER = 0.18, NEGOTIATE = 0.16, REQUEST_ESCORT = 0.18, ACCEPT_TREATMENT = 0.22, REFUSE_TREATMENT = 0.16 },
    CHECK = { COMFORT = 0.28, ASK_FOLLOWUP = 0.20, ACKNOWLEDGE = 0.10, ACCEPT_TREATMENT = 0.24, REFUSE_TREATMENT = 0.14, EXPRESS_UNCERTAINTY = 0.10 },
    ACKNOWLEDGE = { ACKNOWLEDGE = 0.28, AGREE = 0.16, CORROBORATE = 0.16 },
    REACT = { ACKNOWLEDGE = 0.12, CHALLENGE = 0.08, CLAIM_JOKE = 0.08, DEFEND = 0.14, WITHDRAW = 0.14 },
    SOCIALIZE = { ASK_FOLLOWUP = 0.24, ACKNOWLEDGE = 0.14, CLAIM_JOKE = 0.10, REVEAL_SOURCE = 0.14, PROTECT_SOURCE = 0.14 },
    DISPUTE = { DISAGREE = 0.22, CHALLENGE = 0.20, DOUBLE_DOWN = 0.16, CONTRADICT = 0.20, DEFEND = 0.18, MEDIATE = 0.14, REFUSE_INTERVENTION = 0.18 },
    REPAIR = { APOLOGIZE = 0.28, DEESCALATE = 0.26, ACKNOWLEDGE = 0.14, MEDIATE = 0.24 },
    COORDINATE = { AGREE = 0.18, ACKNOWLEDGE = 0.16, ASK_FOLLOWUP = 0.12, VOLUNTEER = 0.16, NEGOTIATE = 0.14, REROUTE = 0.20, POSTPONE = 0.16, REQUEST_ESCORT = 0.18, REFUSE_UNSAFE_WORK = 0.12 },
    MEDIATE = { MEDIATE = 0.30, DEESCALATE = 0.22, APOLOGIZE = 0.18, REFUSE_INTERVENTION = 0.14, WITHDRAW = 0.12 },
    EPISTEMIC = { CORROBORATE = 0.22, CONTRADICT = 0.20, EXPRESS_UNCERTAINTY = 0.20, REVEAL_SOURCE = 0.18, PROTECT_SOURCE = 0.18, ADD_FACT = 0.22 },
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

    local trust = normalizedSigned(relationship.trust)
    local epistemic = type(context.epistemic) == "table" and context.epistemic or {}
    local provenance = tostring(epistemic.provenance or "")
    local condition = type(context.condition) == "table" and context.condition
        or type(actor.condition) == "table" and actor.condition or {}
    local worldK = type(context.worldKnowledge) == "table" and context.worldKnowledge or {}

    local rawFatigue = tonumber(condition.fatigue) or 0
    if math.abs(rawFatigue) > 1 then rawFatigue = rawFatigue / 100 end
    local fatigue = clamp(rawFatigue, 0, 1)
    local rawPain = tonumber(condition.pain) or 0
    if math.abs(rawPain) > 1 then rawPain = rawPain / 100 end
    local pain = clamp(rawPain, 0, 1)

    if EPISTEMIC_CORROBORATE[strategy] then
        local epiDelta = (confidence - 0.5) * 0.18 + (sociability - 0.5) * 0.14 + (loyalty - 0.5) * 0.10
        if provenance == "witnessed" then
            epiDelta = epiDelta + ((strategy == "CORROBORATE" or strategy == "CONFIRM_FACT") and 0.24 or 0.14)
        elseif provenance == "radio" and strategy == "ADD_FACT" then
            epiDelta = epiDelta + 0.16
        elseif provenance == "environmental" then
            epiDelta = epiDelta - 0.14
        end
        if strategy == "REVEAL_SOURCE" then
            epiDelta = epiDelta + trust * 0.24
        end
        if epistemic.corroborated == true and (strategy == "CORROBORATE" or strategy == "CONFIRM_FACT") then
            epiDelta = epiDelta + 0.18
        end
        score = score + epiDelta
        modifiers[#modifiers + 1] = { reason = "epistemic_corroborate", delta = epiDelta }
    elseif EPISTEMIC_DOUBT[strategy] then
        local doubtDelta = 0
        if strategy == "CONTRADICT" then
            doubtDelta = (confidence - 0.5) * 0.16 - relation * 0.10
            if epistemic.contradicted == true then
                doubtDelta = doubtDelta + 0.26
            end
        elseif strategy == "EXPRESS_UNCERTAINTY" then
            if provenance == "environmental" or provenance == "told" or epistemic.status == "uncertain" then
                doubtDelta = doubtDelta + 0.24
            else
                doubtDelta = doubtDelta - 0.08
            end
        elseif strategy == "PROTECT_SOURCE" then
            doubtDelta = -trust * 0.22 + (0.5 - sociability) * 0.12
        end
        if doubtDelta ~= 0 then
            score = score + doubtDelta
            modifiers[#modifiers + 1] = { reason = "epistemic_doubt", delta = doubtDelta }
        end
    elseif MEDIATION_AND_CARE[strategy] then
        local careFit = (compassion - 0.5) * 0.20 + (forgiveness - 0.5) * 0.14 + (loyalty - 0.5) * 0.10
        if strategy == "ACCEPT_TREATMENT" and (condition.injured == true or pain > 0.3) then
            careFit = careFit + 0.24 + trust * 0.12
        elseif strategy == "VOLUNTEER" then
            careFit = careFit + (bravery - 0.5) * 0.12 - fatigue * 0.20
        elseif strategy == "NEGOTIATE" then
            careFit = careFit + fatigue * 0.12
        elseif (strategy == "REROUTE" or strategy == "REQUEST_ESCORT") and worldK.routeHazard == true then
            careFit = careFit + 0.22
        end
        score = score + careFit
        modifiers[#modifiers + 1] = { reason = "mediation_and_care", delta = careFit }
    elseif BOUNDARY_AND_WITHDRAWAL[strategy] then
        local boundaryDelta = (0.5 - forgiveness) * 0.14 - relation * 0.12
        if fatigue > 0.5 or condition.injured == true then
            if strategy == "REFUSE_UNSAFE_WORK" or strategy == "POSTPONE" or strategy == "WITHDRAW" then
                boundaryDelta = boundaryDelta + 0.24
            elseif strategy == "REFUSE_TREATMENT" and trust < -0.1 then
                boundaryDelta = boundaryDelta + 0.22
            end
        end
        if worldK.outdoorHazard == true and strategy == "REFUSE_UNSAFE_WORK" then
            boundaryDelta = boundaryDelta + 0.20
        end
        score = score + boundaryDelta
        modifiers[#modifiers + 1] = { reason = "boundary_and_withdrawal", delta = boundaryDelta }
    end

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
