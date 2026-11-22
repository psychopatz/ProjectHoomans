-- Bounded high-salience injury, bite conflict, and triage memory provenance.
-- Routine minor barks stay transient; only critical trauma, transmissible bites,
-- bite conflict standoffs, and completed triage resolutions record memory entries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local MAX_RECENT_INJURY_MEMORIES = 8

local function pushBoundedMemory(record, entry)
    if type(record) ~= "table" or type(entry) ~= "table" then return nil end
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local list = type(record.runtime.recentHighSalienceInjuryMemory) == "table"
        and record.runtime.recentHighSalienceInjuryMemory or {}
    record.runtime.recentHighSalienceInjuryMemory = list
    while #list >= MAX_RECENT_INJURY_MEMORIES do
        table.remove(list, 1)
    end
    list[#list + 1] = entry

    local convMem = PNC.Conversation and PNC.Conversation.Memory and PNC.Conversation.Memory.Events
    if type(convMem) == "table" and type(convMem.Record) == "function" then
        convMem.Record(record, entry)
    end
    return entry
end

function I.IsHighSalienceInjuryEvent(profile, extra)
    if type(profile) == "table" then
        if profile.isBite == true or tostring(profile.woundType or "") == "bite" then
            return true, "bite_exposure"
        end
        local sev = tostring(profile.physicalSeverityBand or profile.severityBand or "")
        if sev == "critical" or sev == "severe" then
            return true, "severe_trauma"
        end
        local tier = tostring(profile.effectiveWoundTier or "")
        if tier == "bullet" or tier == "deep_wound_glass" or tier == "fracture"
            or tier == "knox_symptom_onset" or tier == "fever_onset"
            or tier == "hypothermia_onset" or tier == "hyperthermia_onset"
        then
            return true, "critical_condition_tier"
        end
    end
    if type(extra) == "table" then
        if extra.kind == "bite_conflict" or extra.kind == "triage_resolution" then
            return true, extra.kind
        end
    end
    return false, nil
end

function S.RecordHighSalienceInjuryMemory(record, spec)
    if type(record) ~= "table" then return nil end
    spec = type(spec) == "table" and spec or {}
    local profile = type(spec.profile) == "table" and spec.profile or nil
    local salient, reason = I.IsHighSalienceInjuryEvent(profile, spec)
    if not salient then return nil end

    local now = (S.Finite and S.Finite(spec.now))
        or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()))
        or 0
    local entry = {
        kind = tostring(spec.kind or reason or "high_salience_injury"),
        salienceReason = tostring(reason or spec.kind or "injury"),
        npcId = tostring(record.id or ""),
        actorId = spec.actorId and tostring(spec.actorId) or nil,
        eventRef = spec.eventRef and tostring(spec.eventRef) or nil,
        woundType = (profile and profile.woundType) or spec.woundType,
        effectiveWoundTier = (profile and profile.effectiveWoundTier) or spec.effectiveWoundTier,
        partId = (profile and profile.partId) or spec.partId,
        bodyRegion = (profile and profile.bodyRegion) or spec.bodyRegion,
        severityBand = (profile and (profile.physicalSeverityBand or profile.severityBand)) or spec.severityBand,
        knoxExposure = (profile and profile.knoxExposure) or spec.knoxExposure,
        salivaTransmissible = (profile and profile.salivaTransmissible)
            ~= nil and profile.salivaTransmissible or spec.salivaTransmissible,
        challengerStance = spec.challengerStance,
        triageOutcome = spec.triageOutcome,
        provenance = tostring(spec.provenance or "experienced"),
        at = now,
    }
    return pushBoundedMemory(record, entry)
end

return S
