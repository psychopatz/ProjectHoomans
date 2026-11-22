-- Director utility scoring for injured-NPC ally reaction candidates.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.Semantics.CombatTargetCalloutsInternal = I

local function isExplicitPsychopath(rec, d)
    if type(rec) ~= "table" then return false end
    if rec.psychopath == true or rec.isPsychopath == true then return true end
    local flags = type(rec.flags) == "table" and rec.flags or nil
    if flags and flags.isPsychopath == true then return true end
    local arch = string.lower(tostring(rec.archetypeID or ""))
    if arch == "psychopath" or arch == "cutthroat" then return true end
    return d.compassion <= 0.18 and d.aggression >= 0.72
end

local function readUnitDisposition(rec)
    local p = (type(rec.social) == "table" and rec.social.personality) or rec.personality or {}
    local dp = PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection or nil
    if dp and type(dp.Resolve) == "function" and dp.ToUnitDisposition then
        local resolved = dp.Resolve(rec)
        if resolved and resolved.effectiveDisposition then
            return dp.ToUnitDisposition(resolved.effectiveDisposition)
        end
    end
    local function norm(v, fb)
        local n = tonumber(v)
        if n == nil then return fb end
        return math.abs(n) > 1 and (n / 100) or n
    end
    return {
        aggression = norm(p.aggression, 0.5),
        compassion = norm(p.compassion, 0.5),
        loyalty = norm(p.loyalty, 0.5),
        confidence = norm(p.confidence, 0.5),
    }
end

local function relationshipBetween(ally, target)
    if type(ally) ~= "table" or type(target) ~= "table" then return {} end
    local key = "npc:" .. tostring(target.id)
    local relsApi = PNC.Relationships
    if relsApi and type(relsApi.Get) == "function" then
        local row = relsApi.Get(ally.id, key) or relsApi.Get(ally.id, tostring(target.id))
        if type(row) == "table" then return row end
    end
    local social = type(ally.social) == "table" and ally.social.relationships or nil
    return type(social) == "table" and (social[key] or social[tostring(target.id)]) or {}
end

local function hasMedicCapability(ally)
    local sk = type(ally.skills) == "table" and ally.skills or nil
    local fa = sk and (tonumber(sk.FirstAid) or tonumber(sk.Doctor) or 0) or 0
    local tr = PNC.Treatment
    local hasSupplies = tr and type(tr.HasNPCBandage) == "function" and tr.HasNPCBandage(ally) == true or false
    return fa >= 2 or hasSupplies, fa
end

local function resolveCandidateRole(profile, isTransmissibleBite, isPsycho, isLowRel, isClose, isMedic, compassion)
    local patched = profile.patchState == "patched_up"
    local tier = tostring(profile.effectiveWoundTier or "")
    local sev = profile.physicalSeverityBand or profile.severityBand
    if isTransmissibleBite then
        if isPsycho then return "psychopath_bite_execution_threat", 45 end
        if isLowRel then return "low_rel_bite_execution_threat", 38 end
        if isClose then return "close_bond_bite_lethal", 30 end
        return (isMedic and "supportive_cover_wounded") or "tactical_cover_wounded", 0
    end
    if tier == "bite_non_transmissible" then
        if isLowRel or isPsycho then return "low_rel_dismissive", 0 end
        return "bite_non_transmissible_relief", 6
    end
    if isClose then
        if patched then return "close_bond_patched", 0 end
        if sev == "critical" or sev == "severe" then return "close_bond_critical", 8 end
        return "supportive_cover_wounded", 0
    end
    if isLowRel or isPsycho then return "low_rel_dismissive", 0 end
    if compassion >= 0.65 or isMedic then
        return patched and "supportive_cover_patched" or "supportive_cover_wounded", 4
    end
    return patched and "tactical_cover_patched" or "tactical_cover_wounded", 0
end

function I.ScoreWoundResponderCandidate(ally, injured, profile, now)
    local rel = relationshipBetween(ally, injured)
    local relState = tostring(rel.state or rel.category or "")
    local approval, trust = tonumber(rel.approval) or 0, tonumber(rel.trust) or 0
    local d = readUnitDisposition(ally)
    local isPsycho = isExplicitPsychopath(ally, d)
    local isClose = relState == "friend" or relState == "family" or relState == "lover"
        or approval >= 30 or trust >= 30 or d.loyalty >= 0.68
    local isLowRel = relState == "enemy" or relState == "rival" or approval <= -20 or trust <= -20
    local isMedic, faLevel = hasMedicCapability(ally)
    local isLeader = ally.isGroupLeader == true or tostring(ally.tacticalRole or "") == "leader"
    local dx = (tonumber(ally.x) or 0) - (tonumber(injured.x) or 0)
    local dy = (tonumber(ally.y) or 0) - (tonumber(injured.y) or 0)
    local dist = math.sqrt(dx * dx + dy * dy)
    local panic = tonumber(ally.conditionStats and ally.conditionStats.panic) or 0
    local rt = type(ally.runtime) == "table" and ally.runtime or {}
    local recentPenalty = (now - (tonumber(rt.lastWoundReactionAt) or -99999)) < 6000 and 25 or 0
    local score = 20 - dist * 1.4 - (panic * 0.15) - recentPenalty
    if isClose then score = score + 28 + math.min(20, approval * 0.2) end
    if isMedic then score = score + 22 + faLevel * 3 end
    if isLeader then score = score + 14 end
    if d.compassion >= 0.65 then score = score + 12 end
    local tier = tostring(profile.effectiveWoundTier or "")
    local isTransmissibleBite = tier == "bite_lethal" or tier == "bite_possible_exposure" or tier == "bite_confirmed_symptomatic"
    local role, bonus = resolveCandidateRole(profile, isTransmissibleBite, isPsycho, isLowRel, isClose, isMedic, d.compassion)
    return {
        ally = ally, role = role, score = score + bonus,
        isThreat = role == "psychopath_bite_execution_threat" or role == "low_rel_bite_execution_threat",
        isBond = isClose, isMedic = isMedic, isPsycho = isPsycho, isLowRel = isLowRel,
    }
end

return I
