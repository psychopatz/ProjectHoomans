-- Ally reaction role selection and bite threat tracking for combat injury callouts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundProfile"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local function hasPsychopathTrait(rec)
    if type(rec) ~= "table" then return false end
    if rec.psychopath == true then return true end
    local tc = PNC.NPCTraitContext
    local traits = (tc and type(tc.Collect) == "function" and tc.Collect(rec)) or rec.traits or rec.npcTraits
    if type(traits) ~= "table" then return false end
    for k, v in pairs(traits) do
        local name = string.lower(tostring(type(v) == "string" and v or k))
        if (v == true or type(v) == "string") and (name == "psychopath" or name == "cruel") then
            return true
        end
    end
    return false
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

local function markBiteExecutionThreat(injured, ally, kind, now)
    injured.runtime = type(injured.runtime) == "table" and injured.runtime or {}
    injured.runtime.lastBiteThreatReactorId = tostring(ally.id)
    injured.runtime.biteExecutionThreat = {
        reactorId = tostring(ally.id),
        targetId = tostring(injured.id),
        kind = kind,
        recommendedAction = "hostile_eliminate_bitten",
        at = now or 0,
    }
end

function S.ResolveAllyWoundReactionRole(ally, injured, profile, waveIndex, now)
    if type(ally) ~= "table" or type(profile) ~= "table" then return "tactical_cover_wounded" end
    local rel = relationshipBetween(ally, injured)
    local relState = tostring(rel.state or rel.category or "")
    local approval = tonumber(rel.approval) or 0
    local trust = tonumber(rel.trust) or 0
    local d = readUnitDisposition(ally)
    local isPsycho = hasPsychopathTrait(ally) or (d.compassion <= 0.25 and d.aggression >= 0.65)
    local isClose = relState == "friend" or relState == "family" or relState == "lover"
        or approval >= 30 or trust >= 30 or d.loyalty >= 0.68
    local isLowRel = relState == "enemy" or relState == "rival" or approval <= -20 or trust <= -20
    local isWingman = (tonumber(waveIndex) or 1) >= 2
    local patched = profile.patchState == "patched_up"

    if profile.effectiveWoundTier == "bite_lethal"
        or profile.effectiveWoundTier == "bite_possible_exposure"
        or profile.effectiveWoundTier == "bite_confirmed_symptomatic"
    then
        if isPsycho then
            markBiteExecutionThreat(injured, ally, "psychopath", now)
            return "psychopath_bite_execution_threat"
        end
        if isLowRel then
            markBiteExecutionThreat(injured, ally, "low_relationship", now)
            return "low_rel_bite_execution_threat"
        end
        if isClose then return "close_bond_bite_lethal" end
        return isWingman and "squad_crossfire_wingman" or "supportive_cover_wounded"
    end
    if profile.effectiveWoundTier == "bite_non_transmissible" then
        if isLowRel or isPsycho then return "low_rel_dismissive" end
        return isWingman and "squad_crossfire_wingman" or "bite_non_transmissible_relief"
    end
    if isClose then
        if patched then return "close_bond_patched" end
        if profile.severityBand == "critical" or profile.severityBand == "severe" then return "close_bond_critical" end
        return "supportive_cover_wounded"
    end
    if isLowRel or isPsycho then return "low_rel_dismissive" end
    if isWingman then return "squad_crossfire_wingman" end
    if d.compassion >= 0.65 then
        return patched and "supportive_cover_patched" or "supportive_cover_wounded"
    end
    return patched and "tactical_cover_patched" or "tactical_cover_wounded"
end

function I.SelectWoundResponders(mates, record, profile, now)
    local selected = {}
    if #mates <= 1 then
        if mates[1] then
            selected[1] = {
                ally = mates[1],
                role = S.ResolveAllyWoundReactionRole(mates[1], record, profile, 1, now),
            }
        end
        return selected
    end
    -- Prioritize including any psychopath/low-rel bite threat reactor alongside a close ally.
    local threatIdx = nil
    if profile.effectiveWoundTier == "bite_lethal"
        or profile.effectiveWoundTier == "bite_possible_exposure"
        or profile.effectiveWoundTier == "bite_confirmed_symptomatic"
    then
        for i = 2, #mates do
            local r = S.ResolveAllyWoundReactionRole(mates[i], record, profile, 1, now)
            if r == "psychopath_bite_execution_threat" or r == "low_rel_bite_execution_threat" then
                threatIdx = i
                selected[#selected + 1] = { ally = mates[i], role = r }
                break
            end
        end
    end
    for i = 1, #mates do
        if i ~= threatIdx and #selected < 2 then
            local waveIdx = #selected + 1
            selected[waveIdx] = {
                ally = mates[i],
                role = S.ResolveAllyWoundReactionRole(mates[i], record, profile, waveIdx, now),
            }
        end
    end
    return selected
end

return S
