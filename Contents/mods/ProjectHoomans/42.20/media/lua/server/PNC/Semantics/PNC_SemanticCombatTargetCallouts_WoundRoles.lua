-- Ally reaction role selection, bite conflict fact recording, and bounded responder arbitration.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundProfile"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundArbitration"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_InjuryMemory"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local function recordBiteConflictFacts(injured, scored, profile, now)
    if type(injured) ~= "table" or type(scored) ~= "table" or type(scored.ally) ~= "table" then return end
    local ally = scored.ally
    injured.runtime = type(injured.runtime) == "table" and injured.runtime or {}
    local stance = scored.isThreat and "hostile_suspect"
        or (scored.isBond and "protective_defender" or "quarantine_caution")
    local facts = {
        challengerId = tostring(ally.id),
        injuredId = tostring(injured.id),
        reactorId = tostring(ally.id),
        targetId = tostring(injured.id),
        kind = scored.isPsycho and "psychopath" or (scored.isThreat and "low_relationship" or stance),
        challengerStance = stance,
        isBitten = true,
        knoxExposure = profile and profile.knoxExposure or (profile and profile.salivaTransmissible == false and "impossible" or "possible"),
        knoxStage = profile and profile.knoxStage or "none",
        salivaTransmissible = not (profile and profile.salivaTransmissible == false),
        challengerDispositions = {
            aggression = scored.aggression,
            compassion = scored.compassion,
            loyalty = scored.loyalty,
            bravery = scored.bravery,
            confidence = scored.confidence,
        },
        relationshipApproval = scored.rel and scored.rel.approval or 0,
        relationshipState = scored.rel and scored.rel.state or "neutral",
        at = now or 0,
        timestamp = now or 0,
    }
    injured.runtime.lastBiteThreatReactorId = tostring(ally.id)
    injured.runtime.biteConflictFacts = facts
    injured.runtime.biteExecutionThreat = facts
    if type(S.RecordHighSalienceInjuryMemory) == "function" then
        S.RecordHighSalienceInjuryMemory(injured, {
            kind = "bite_conflict",
            profile = profile,
            actorId = tostring(ally.id),
            challengerStance = stance,
            provenance = "experienced",
            now = now,
        })
        S.RecordHighSalienceInjuryMemory(ally, {
            kind = "bite_conflict",
            profile = profile,
            actorId = tostring(injured.id),
            challengerStance = stance,
            provenance = "witnessed",
            now = now,
        })
    end
end

function S.ResolveAllyWoundReactionRole(ally, injured, profile, waveIndex, now)
    if type(ally) ~= "table" or type(profile) ~= "table" then return "tactical_cover_wounded" end
    local scored = I.ScoreWoundResponderCandidate(ally, injured, profile, tonumber(now) or 0)
    if scored.isThreat then
        recordBiteConflictFacts(injured, scored, profile, now)
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
        recordBiteConflictFacts(record, first, profile, now)
    end
    first.ally.runtime = type(first.ally.runtime) == "table" and first.ally.runtime or {}
    first.ally.runtime.lastWoundReactionAt = now
    selected[1] = { ally = first.ally, role = first.role, score = first.score }
    for i = 2, #candidates do
        local cand = candidates[i]
        if cand.score >= 10 and shouldAddSecondResponder(first, cand, profile) then
            if cand.isThreat then
                recordBiteConflictFacts(record, cand, profile, now)
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
