-- Pain-reaction variant policy and escalation-aware wound cooldown preemption.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

local SEVERITY_RANKS = {
    none = 0, minor = 1, moderate = 2, severe = 3, critical = 4,
}

local function normUnit(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    if n > 1 then n = n / 100 end
    if n < 0 then return 0 elseif n > 1 then return 1 end
    return n
end

local function resolvePainStyle(record)
    local dispApi = PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    local d = nil
    if type(dispApi) == "table" and type(dispApi.Resolve) == "function" then
        local res = dispApi.Resolve(record)
        if type(res) == "table" and type(dispApi.ToUnitDisposition) == "function" then
            d = dispApi.ToUnitDisposition(res.effectiveDisposition)
        end
    end
    local p = (record.disposition or (record.social and record.social.personality) or record.personality) or {}
    local aggression = d and d.aggression or normUnit(p.aggression, 0.50)
    local bravery = d and d.bravery or normUnit(p.bravery, 0.50)
    local confidence = d and d.confidence or normUnit(p.confidence, 0.50)
    local panic = normUnit(record.conditionStats and record.conditionStats.panic or record.panic, 0)
    if panic >= 0.65 or bravery <= 0.25 then return "panicked" end
    if aggression >= 0.72 then return "aggressive" end
    if bravery >= 0.72 and confidence >= 0.65 then return "stoic" end
    return "neutral"
end

function S.ResolvePainReactionVariant(record, profile)
    if type(profile) ~= "table" then return "default" end
    local sel = type(profile.selectedWound) == "table" and profile.selectedWound or profile
    local wType = tostring(sel.woundType or profile.woundType or "scratch")
    local sev = tostring(sel.physicalSeverity or profile.physicalSeverityBand or "minor")
    local style = resolvePainStyle(record)
    local countBand = tostring(profile.woundCountBand or "single")

    if wType == "bite" or profile.isBite == true then
        if sel.knoxExposure == "impossible" or profile.salivaTransmissible == false then
            return "bite_non_transmissible"
        end
        return style == "panicked" and "bite_panicked" or "bite"
    end
    if wType == "bullet" then
        return style == "stoic" and "bullet_stoic" or "bullet"
    end
    if wType == "fracture" then
        return "fracture"
    end
    if wType == "deep_wound_glass" then
        return "deep_wound_glass"
    end
    if wType == "deep_wound" then
        return "deep_wound"
    end
    if wType == "burn" then
        return "burn"
    end
    if countBand == "multiple" or countBand == "extensive" then
        if sev == "severe" or sev == "critical" then return "multiple_hits_severe" end
    end
    if wType == "laceration" then
        if sev == "severe" or sev == "critical" then return "laceration_severe" end
        if style == "aggressive" then return "laceration_aggressive" end
        if style == "stoic" then return "laceration_stoic" end
        return "laceration_moderate"
    end
    if wType == "scratch" then
        if style == "stoic" then return "scratch_stoic" end
        if style == "aggressive" then return "scratch_aggressive" end
        return "scratch_minor"
    end
    return "default"
end

function S.ShouldPreemptWoundCooldown(record, profile, now, cooldownMs)
    local rt = type(record) == "table" and record.runtime or nil
    if type(rt) ~= "table" then return true, "first_wound" end
    local lastAt = tonumber(rt.lastPainBeatAt or rt.lastWoundBeatAt) or -99999
    local elapsed = (tonumber(now) or 0) - lastAt
    local window = tonumber(cooldownMs) or 2500
    if elapsed >= window then return true, "cooldown_expired" end

    local sel = type(profile.selectedWound) == "table" and profile.selectedWound or profile
    local curPri = tonumber(profile.woundTierPriority) or 1
    local prevPri = tonumber(rt.lastPainBeatPriority or rt.lastWoundBeatPriority) or 0
    local curSev = SEVERITY_RANKS[tostring(sel.physicalSeverity or profile.physicalSeverityBand or "minor")] or 1
    local prevSev = tonumber(rt.lastPainBeatSeverityRank) or 0
    local curRegion = tostring(sel.bodyRegion or profile.bodyRegion or "torso")
    local prevRegion = tostring(rt.lastPainBeatRegion or "")
    local wType = tostring(sel.woundType or profile.woundType or "scratch")

    if wType == "bite" or profile.isBite == true then return true, "bite_preempt" end
    if wType == "bullet" and prevPri < 5 then return true, "gunshot_preempt" end
    if curPri > prevPri then return true, "tier_escalation" end
    if curSev > prevSev and curSev >= 2 then return true, "severity_escalation" end
    if curSev >= 3 and curRegion ~= prevRegion then return true, "severe_new_region" end
    return false, "suppressed_by_cooldown"
end


-- Longer received-wound Beat preemption: bite, gunshot, tier, severity, severe new region.
function S.ShouldPreemptWoundBeat(record, profile, now, windowMs)
    local rt = type(record) == "table" and type(record.runtime) == "table" and record.runtime or {}
    local elapsed = (tonumber(now) or 0) - (tonumber(rt.lastWoundBeatAt) or -99999)
    if elapsed >= (tonumber(windowMs) or 4500) then return true, false end
    local prevPri = tonumber(rt.lastWoundBeatPriority) or 0
    local curSev = SEVERITY_RANKS[tostring(profile.physicalSeverityBand or profile.severityBand or "minor")] or 1
    local pre = prevPri > 0 and (profile.isBite == true
        or (profile.woundType == "bullet" and prevPri < 5)
        or (tonumber(profile.woundTierPriority) or 0) > prevPri
        or (curSev > (tonumber(rt.lastWoundBeatSeverityRank) or 0) and curSev >= 2)
        or (curSev >= 3 and tostring(profile.bodyRegion or "torso") ~= tostring(rt.lastWoundBeatRegion or "")))
    return pre == true, pre == true
end

function S.SeverityRank(band)
    return SEVERITY_RANKS[tostring(band or "minor")] or 1
end

return S
