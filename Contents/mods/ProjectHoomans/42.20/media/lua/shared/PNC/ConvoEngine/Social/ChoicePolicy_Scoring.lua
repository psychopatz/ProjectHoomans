-- Disposition and epistemic scoring helpers for SocialChoicePolicy.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Choice = PNC.ConvoEngine.SocialChoicePolicy or {}
PNC.ConvoEngine.SocialChoicePolicy = Choice

local DispositionProjection = PNC.ConvoEngine.DispositionProjection
    or require "PNC/ConvoEngine/DispositionProjection"
local Strategies = require "PNC/ConvoEngine/Social/ChoicePolicy_Strategies"

local EPISTEMIC_CORROBORATE = Strategies.EPISTEMIC_CORROBORATE
local EPISTEMIC_DOUBT = Strategies.EPISTEMIC_DOUBT
local MEDIATION_AND_CARE = Strategies.MEDIATION_AND_CARE
local BOUNDARY_AND_WITHDRAWAL = Strategies.BOUNDARY_AND_WITHDRAWAL

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
        resolveOpts.baseDisposition = actor.disposition
        resolveOpts.condition = type(context) == "table"
            and context.condition or {}
    elseif type(context) == "table" and type(context.condition) == "table" then
        resolveOpts.condition = context.condition
    end
    local resolved = DispositionProjection.Resolve(actor, resolveOpts)
    return DispositionProjection.ToUnitDisposition(resolved.effectiveDisposition)
end

local function applyEpistemicAndCareDelta(strategy, score, modifiers, d, relation, trust, actor, context)
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
        local epiDelta = (d.confidence - 0.5) * 0.18 + (d.sociability - 0.5) * 0.14 + (d.loyalty - 0.5) * 0.10
        if provenance == "witnessed" then
            epiDelta = epiDelta + ((strategy == "CORROBORATE" or strategy == "CONFIRM_FACT") and 0.24 or 0.14)
        elseif provenance == "radio" and strategy == "ADD_FACT" then
            epiDelta = epiDelta + 0.16
        elseif provenance == "environmental" then
            epiDelta = epiDelta - 0.14
        end
        if strategy == "REVEAL_SOURCE" then epiDelta = epiDelta + trust * 0.24 end
        if epistemic.corroborated == true and (strategy == "CORROBORATE" or strategy == "CONFIRM_FACT") then
            epiDelta = epiDelta + 0.18
        end
        score = score + epiDelta
        modifiers[#modifiers + 1] = { reason = "epistemic_corroborate", delta = epiDelta }
    elseif EPISTEMIC_DOUBT[strategy] then
        local doubtDelta = 0
        if strategy == "CONTRADICT" then
            doubtDelta = (d.confidence - 0.5) * 0.16 - relation * 0.10
            if epistemic.contradicted == true then doubtDelta = doubtDelta + 0.26 end
        elseif strategy == "EXPRESS_UNCERTAINTY" then
            if provenance == "environmental" or provenance == "told" or epistemic.status == "uncertain" then
                doubtDelta = doubtDelta + 0.24
            else
                doubtDelta = doubtDelta - 0.08
            end
        elseif strategy == "PROTECT_SOURCE" then
            doubtDelta = -trust * 0.22 + (0.5 - d.sociability) * 0.12
        end
        if doubtDelta ~= 0 then
            score = score + doubtDelta
            modifiers[#modifiers + 1] = { reason = "epistemic_doubt", delta = doubtDelta }
        end
    elseif MEDIATION_AND_CARE[strategy] then
        local careFit = (d.compassion - 0.5) * 0.20 + (d.forgiveness - 0.5) * 0.14 + (d.loyalty - 0.5) * 0.10
        if strategy == "ACCEPT_TREATMENT" and (condition.injured == true or pain > 0.3) then
            careFit = careFit + 0.24 + trust * 0.12
        elseif strategy == "VOLUNTEER" then
            careFit = careFit + (d.bravery - 0.5) * 0.12 - fatigue * 0.20
        elseif strategy == "NEGOTIATE" then
            careFit = careFit + fatigue * 0.12
        elseif (strategy == "REROUTE" or strategy == "REQUEST_ESCORT") and worldK.routeHazard == true then
            careFit = careFit + 0.22
        end
        score = score + careFit
        modifiers[#modifiers + 1] = { reason = "mediation_and_care", delta = careFit }
    elseif BOUNDARY_AND_WITHDRAWAL[strategy] then
        local boundaryDelta = (0.5 - d.forgiveness) * 0.14 - relation * 0.12
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
    return score
end

Choice.Internal = {
    AGGRESSIVE = Strategies.AGGRESSIVE,
    REPAIR = Strategies.REPAIR,
    CURIOUS = Strategies.CURIOUS,
    MOTIVE_PREFERENCE = Strategies.MOTIVE_PREFERENCE,
    Clamp = clamp,
    NormalizedSigned = normalizedSigned,
    Upper = upper,
    Projection = projection,
    ResolveEffectiveUnit = resolveEffectiveUnit,
    ApplyEpistemicAndCareDelta = applyEpistemicAndCareDelta,
}

return Choice
