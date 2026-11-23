-- Bounded per-observer daily injury observation signatures and material-change gating.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

local MAX_OBS = 12
local SEV_R = { none = 0, minor = 1, moderate = 2, severe = 3, critical = 4 }
local BLD_R = { none = 0, minor = 1, moderate = 2, heavy = 3, critical = 4 }
local CNT_R = { none = 0, single = 1, multiple = 2, extensive = 3 }
local KNX_R = { impossible = 0, none = 0, possible = 1, incubating = 1, prodrome = 2, confirmed = 3, fever = 3, critical = 4 }

local function dayBucket(now)
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeDaysSinceBegin) == "function" then
            local d = tonumber(gt:getWorldAgeDaysSinceBegin())
            if d then return math.floor(d) end
        end
        if gt and type(gt.getWorldAgeHours) == "function" then
            local h = tonumber(gt:getWorldAgeHours())
            if h then return math.floor(h / 24) end
        end
    end
    return math.floor((tonumber(now) or 0) / 86400000)
end
S.CurrentWorldDayBucket = dayBucket

local TreatmentSpeech = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TreatmentSpeech"

local observations = setmetatable({}, { __mode = "k" })
local FEVER = { feverish = 1, high_fever = 2 }
local SICKNESS = { moderate = 1, severe = 2 }

local function signature(prof, opts)
    local sel = prof.selectedWound or prof
    local phys = prof.physiology or {}
    local exposed = sel.bandaged ~= true
    local hasDiagnosis = opts and (opts.inspected == true or opts.toldByInjured == true)
    return {
        revision = tonumber(prof.injuryRevision) or 0,
        severity = SEV_R[sel.physicalSeverity or prof.physicalSeverityBand] or 0,
        bleeding = BLD_R[prof.bleedingBand or sel.bleedingBand] or 0,
        count = tonumber(prof.totalWoundCount) or CNT_R[prof.woundCountBand] or 0,
        knox = hasDiagnosis and (KNX_R[sel.knoxStage] or KNX_R[sel.knoxExposure]) or 0,
        treatment = sel.treatmentState or prof.treatmentState,
        treatmentMaterial = TreatmentSpeech.Describe(sel, not hasDiagnosis),
        region = sel.bodyRegion or prof.bodyRegion,
        part = sel.bodyPart or prof.partId,
        bite = (exposed or hasDiagnosis or (opts and opts.witnessedHit)) and sel.woundType == "bite",
        infected = (exposed or hasDiagnosis) and sel.ordinaryInfection == true,
        dirty = sel.bandaged == true and sel.bandageDirty == true,
        physiology = math.max(FEVER[phys.feverBand] or 0, SICKNESS[phys.sicknessBand] or 0),
    }
end

function S.RecordWitnessObservation(obs, inj, prof, now, opts)
    local day = dayBucket(now)
    local c = observations[obs]
    if not c or c.day ~= day then
        c = { day = day, byTarget = {}, order = {} }
        observations[obs] = c
    end
    local target = tostring(inj.id)
    local prev = c.byTarget[target]
    local observed = signature(prof, opts)
    if prev and prev.revision > observed.revision then return end
    for i = 1, #c.order do
        if c.order[i] == target then table.remove(c.order, i); break end
    end
    if #c.order >= MAX_OBS then c.byTarget[table.remove(c.order, 1)] = nil end
    c.order[#c.order + 1] = target
    c.byTarget[target] = observed
end

function S.EvaluateWitnessObservationGate(obs, inj, prof, now, opts)
    if not obs or not inj or not prof then return false, "invalid_args" end
    local day = dayBucket(now)
    local c = observations[obs]
    local prev = c and c.day == day and c.byTarget[tostring(inj.id)] or nil
    local cur = signature(prof, opts)
    local reason
    local newWound = prev and (cur.count > prev.count or
        (cur.revision > prev.revision and (cur.region ~= prev.region or cur.part ~= prev.part
            or (opts and opts.witnessedHit == true)))) == true
    if not prev then reason = "first_of_day"
    elseif cur.bite and not prev.bite then reason = "bite_detected"
    elseif cur.knox > prev.knox then reason = "knox_progressed"
    elseif cur.severity > prev.severity then reason = "severity_escalated"
    elseif cur.bleeding > prev.bleeding then reason = "bleeding_escalated"
    elseif cur.count > prev.count then reason = "wound_count_increased"
    elseif newWound then reason = "new_wound_region"
    elseif cur.dirty and not prev.dirty then reason = "dressing_dirty"
    elseif cur.infected and not prev.infected then reason = "infection_visible"
    elseif cur.physiology > prev.physiology then reason = "physiology_worsened"
    elseif cur.treatment ~= prev.treatment or cur.treatmentMaterial ~= prev.treatmentMaterial then reason = "treatment_changed" end
    if not reason then return false, "unchanged_today" end
    return true, reason, {
        firstOfDay = not prev, newSinceLastObservation = newWound,
        changeReason = reason, woundCountBand = prof.woundCountBand,
    }
end

return S
