-- Ally reaction role selection, bite conflict marking, and bounded responder arbitration.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundProfile"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundArbitration"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

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
    local scored = I.ScoreWoundResponderCandidate(ally, injured, profile, tonumber(now) or 0)
    if scored.isThreat then
        markBiteExecutionThreat(injured, ally, scored.isPsycho and "psychopath" or "low_relationship", now)
    elseif (tonumber(waveIndex) or 1) >= 2 and not scored.isBond and not scored.isMedic then
        return "squad_crossfire_wingman"
    end
    return scored.role
end

local function shouldAddSecondResponder(first, second, profile)
    if not first or not second then return false end
    local tier = tostring(profile.effectiveWoundTier or "")
    local isBiteConflict = (tier == "bite_lethal" or tier == "bite_possible_exposure" or tier == "bite_confirmed_symptomatic")
        and ((first.isThreat and not second.isThreat) or (second.isThreat and not first.isThreat))
    if isBiteConflict then return true end
    local sev = profile.physicalSeverityBand or profile.severityBand
    return (sev == "critical" or sev == "severe")
        and ((first.isBond and second.isMedic) or (second.isBond and first.isMedic))
end

function I.SelectWoundResponders(mates, record, profile, now)
    now = tonumber(now) or 0
    if type(mates) ~= "table" or #mates == 0 then return {} end
    local candidates = {}
    for i = 1, #mates do
        candidates[#candidates + 1] = I.ScoreWoundResponderCandidate(mates[i], record, profile, now)
    end
    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.ally.id or "") < tostring(b.ally.id or "")
    end)
    local selected = {}
    local first = candidates[1]
    if not first or first.score < 0 then return selected end
    if first.isThreat then
        markBiteExecutionThreat(record, first.ally, first.isPsycho and "psychopath" or "low_relationship", now)
    end
    first.ally.runtime = type(first.ally.runtime) == "table" and first.ally.runtime or {}
    first.ally.runtime.lastWoundReactionAt = now
    selected[1] = { ally = first.ally, role = first.role, score = first.score }
    for i = 2, #candidates do
        local cand = candidates[i]
        if cand.score >= 10 and shouldAddSecondResponder(first, cand, profile) then
            if cand.isThreat then
                markBiteExecutionThreat(record, cand.ally, cand.isPsycho and "psychopath" or "low_relationship", now)
            end
            local role = (not cand.isThreat and not cand.isMedic and not cand.isBond) and "squad_crossfire_wingman" or cand.role
            cand.ally.runtime = type(cand.ally.runtime) == "table" and cand.ally.runtime or {}
            cand.ally.runtime.lastWoundReactionAt = now
            selected[2] = { ally = cand.ally, role = role, score = cand.score }
            break
        end
    end
    return selected
end

return S
