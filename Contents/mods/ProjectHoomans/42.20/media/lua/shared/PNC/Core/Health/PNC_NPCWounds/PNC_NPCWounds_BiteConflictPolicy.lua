-- Authoritative bite conflict behavioral policy evaluator.
-- Consumes normalized health projections, numeric disposition, relationship, and active player triage orders
-- without embedding behavioral action commands inside dialogue modules.
PNC = PNC or {}
local Wounds = PNC.NPCWounds

local function num(v, d)
    local n = tonumber(v)
    return n ~= nil and n or d
end

local function normSigned(v)
    local n = num(v, 0)
    if math.abs(n) > 1 then n = n / 100 end
    if n < -1 then return -1 end
    if n > 1 then return 1 end
    return n
end

local function normUnit(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    if n > 1 then n = n / 100 end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
end

local function hasPsychopathTrait(rec)
    if type(rec) ~= "table" then return false end
    if rec.psychopath == true or rec.isPsychopath == true then return true end
    local traits = rec.traits or (rec.personality and rec.personality.traits)
    if type(traits) ~= "table" then return false end
    if traits.Psychopath == true or traits.psychopath == true or traits.Ruthless == true then
        return true
    end
    for i = 1, #traits do
        local t = string.lower(tostring(traits[i] or ""))
        if t == "psychopath" or t == "ruthless" then return true end
    end
    return false
end

local function resolveObserverDisposition(observer, context)
    local dispApi = PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if type(dispApi) == "table" and type(dispApi.Resolve) == "function" then
        local resolved = dispApi.Resolve(observer, context)
        if type(resolved) == "table" and type(dispApi.ToUnitDisposition) == "function" then
            return dispApi.ToUnitDisposition(resolved.effectiveDisposition)
        end
    end
    local p = (type(observer) == "table" and (observer.disposition or (observer.social and observer.social.personality) or observer.personality)) or {}
    local psycho = hasPsychopathTrait(observer)
    return {
        aggression = normUnit(p.aggression, psycho and 0.90 or 0.50),
        compassion = normUnit(p.compassion, psycho and 0.05 or 0.50),
        loyalty = normUnit(p.loyalty, psycho and 0.15 or 0.50),
        bravery = normUnit(p.bravery, 0.50),
        confidence = normUnit(p.confidence, 0.50),
        forgiveness = normUnit(p.forgiveness, psycho and 0.10 or 0.50),
    }
end

local function resolveRelationship(observer, target, context)
    local rel = type(context) == "table" and context.relationship or nil
    if type(rel) ~= "table" and type(observer) == "table" and type(target) == "table" and target.id ~= nil then
        local rels = observer.relationships or (observer.social and observer.social.relationships)
        if type(rels) == "table" then
            local tid = tostring(target.id)
            rel = rels["npc:" .. tid] or rels[tid]
        end
    end
    rel = type(rel) == "table" and rel or {}
    return {
        state = tostring(rel.state or "neutral"),
        approval = normSigned(rel.approval),
        respect = normSigned(rel.respect),
        trust = normSigned(rel.trust),
    }
end

function Wounds.EvaluateBiteConflictPolicy(observerRecord, targetRecord, context)
    context = type(context) == "table" and context or {}
    local proj = type(targetRecord) == "table" and Wounds.GetOrBuildProjection(targetRecord) or nil
    local facts = (type(targetRecord) == "table" and targetRecord.runtime and targetRecord.runtime.biteConflictFacts)
        or context.biteConflictFacts or nil
    local triage = (type(targetRecord) == "table" and targetRecord.runtime and targetRecord.runtime.activeInjuryTriageState)
        or context.activeInjuryTriageState or nil

    local isBitten = (proj and proj.hasBite == true)
        or (facts and facts.isBitten ~= false)
        or context.isBitten == true
    local knoxExposure = (proj and proj.knoxExposure)
        or (facts and facts.knoxExposure)
        or context.knoxExposure
        or "impossible"
    local knoxStage = (proj and proj.knoxStage)
        or (facts and facts.knoxStage)
        or context.knoxStage
        or "none"
    local saliva = (proj and proj.salivaTransmissible)
    if saliva == nil and facts then saliva = facts.salivaTransmissible end
    if saliva == nil then saliva = knoxExposure ~= "impossible" end

    if not isBitten or knoxExposure == "impossible" or saliva == false then
        return {
            stance = "none",
            knoxExposure = "impossible",
            knoxStage = knoxStage,
            requiresConfirmation = false,
            suppressedByPlayerOrder = false,
            reason = "no_transmissible_bite_risk",
        }
    end

    local disp = resolveObserverDisposition(observerRecord, context)
    local rel = resolveRelationship(observerRecord, targetRecord, context)
    local psycho = hasPsychopathTrait(observerRecord)
    local closeBond = rel.state == "friend" or rel.state == "family" or rel.state == "lover"
        or rel.state == "close_friend" or rel.approval >= 0.45 or disp.loyalty >= 0.75

    local stance = "monitor"
    local reason = "default_caution"
    if closeBond and disp.compassion >= 0.45 and not psycho then
        stance = "protect"
        reason = "close_bond_protection"
    elseif psycho or (disp.aggression >= 0.80 and disp.compassion <= 0.15 and rel.approval <= 0.10) then
        stance = knoxExposure == "confirmed" and "execute_candidate" or "threaten"
        reason = psycho and "psychopath_lethal_Elimination_impulse" or "ruthless_aggression_impulse"
    elseif rel.approval <= -0.15 or rel.state == "hostile" or rel.state == "enemy" or rel.state == "rival" then
        if disp.aggression >= 0.60 and disp.compassion <= 0.30 then
            stance = knoxExposure == "confirmed" and "execute_candidate" or "threaten"
            reason = "hostile_relationship_threat"
        else
            stance = "abandon"
            reason = "low_relationship_abandonment"
        end
    elseif knoxExposure == "confirmed" or disp.compassion < 0.45 then
        stance = "quarantine"
        reason = "infection_containment_quarantine"
    end

    local suppressed = false
    if type(triage) == "table" then
        if triage.playerProtectedBitten == true then
            if stance == "execute_candidate" or stance == "threaten" or stance == "abandon" then
                stance = triage.playerOrderedQuarantine == true and "quarantine" or "monitor"
                suppressed = true
                reason = "suppressed_by_player_protection_order"
            end
        elseif triage.playerOrderedQuarantine == true then
            if stance == "execute_candidate" or stance == "threaten" then
                stance = "quarantine"
                suppressed = true
                reason = "downgraded_to_quarantine_by_player_order"
            end
        end
    end

    return {
        stance = stance,
        knoxExposure = knoxExposure,
        knoxStage = knoxStage,
        requiresConfirmation = knoxExposure ~= "confirmed",
        suppressedByPlayerOrder = suppressed,
        reason = reason,
        disposition = disp,
        relationship = rel,
    }
end

return Wounds
