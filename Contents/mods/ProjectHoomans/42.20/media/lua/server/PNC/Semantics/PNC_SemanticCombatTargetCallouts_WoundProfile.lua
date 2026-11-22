-- Combat injury profile classification, region/severity resolution, and Beat variant lookup.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

local WOUND_LABELS = {
    bite = "bite",
    bullet = "gunshot wound",
    deep_wound_glass = "glass gash",
    deep_wound = "deep wound",
    fracture = "fracture",
    burn = "burn",
    laceration = "laceration",
    scratch = "scratch",
}

local WOUND_PRIORITIES = {
    scratch = 2, laceration = 3, burn = 4, fracture = 4,
    deep_wound = 4, deep_wound_glass = 4, bullet = 5, bite = 6,
}

local FIGHTING_VARIANT_TABLE = {
    with_wounds = {
        minor_low_tier = "with_wounds_minor",
        head_neck_severe = "with_wounds_head_neck_critical",
        head_neck = "with_wounds_head_neck",
        torso_severe = "with_wounds_torso_critical",
        torso = "with_wounds_torso",
        pelvis_groin_severe = "with_wounds_pelvis_groin_severe",
        pelvis_groin = "with_wounds_pelvis_groin",
        upper_limb_severe = "with_wounds_upper_limb_severe",
        upper_limb = "with_wounds_upper_limb",
        lower_limb_severe = "with_wounds_lower_limb_severe",
        lower_limb = "with_wounds_lower_limb",
    },
    patched_up = {
        minor_low_tier = "patched_up_minor",
        head_neck_severe = "patched_up_head_neck_severe",
        head_neck = "patched_up_head_neck",
        torso_severe = "patched_up_torso_severe",
        torso = "patched_up_torso",
        pelvis_groin_severe = "patched_up_pelvis_groin_severe",
        pelvis_groin = "patched_up_pelvis_groin",
        upper_limb_severe = "patched_up_upper_limb_severe",
        upper_limb = "patched_up_upper_limb",
        lower_limb_severe = "patched_up_lower_limb_severe",
        lower_limb = "patched_up_lower_limb",
    },
}

local TRANSITION_VARIANTS = {
    severity_escalation = "severity_escalation",
    bandage_dirty = "bandage_dirty",
    treatment_stabilized = "treatment_stabilized",
    knox_symptom_onset = "knox_symptom_onset",
    fever_onset = "fever_onset",
    cold_illness_onset = "cold_illness_onset",
    hypothermia_onset = "hypothermia_onset",
    hyperthermia_onset = "hyperthermia_onset",
    soaked_chill = "soaked_chill",
    post_combat_injury_check = "post_combat_injury_check",
}

local function salivaTransmissible()
    local sb = PNC.Sandbox
    if sb and type(sb.IsZombieSalivaTransmissible) == "function" then
        return sb.IsZombieSalivaTransmissible() == true
    end
    return true
end

function S.ClassifyActorWoundProfile(record, hitSpec)
    if type(record) ~= "table" or record.alive == false then return nil end
    local wounds = PNC.NPCWounds
    local prof = wounds and type(wounds.ClassifyCombatInjuryState) == "function"
        and wounds.ClassifyCombatInjuryState(record, hitSpec and hitSpec.partId, hitSpec and hitSpec.woundType)
        or nil
    if not prof and type(hitSpec) == "table" and hitSpec.woundType then
        local wType = tostring(hitSpec.woundType)
        local partId = tostring(hitSpec.partId or "Torso_Upper")
        local sal = salivaTransmissible()
        local knoxExp = (wType == "bite" and sal) and "possible" or "impossible"
        local effTier = wType
        if wType == "bite" then
            effTier = sal and "bite_possible_exposure" or "bite_non_transmissible"
        end
        local physSev = (wType == "bullet") and "critical" or ((wType == "bite" or wType == "deep_wound") and "severe" or "moderate")
        prof = {
            injured = true,
            patchState = hitSpec.bandaged == true and "patched_up" or "with_wounds",
            treatmentState = hitSpec.bandaged == true and "bandaged" or "open_untreated",
            partId = partId,
            partLabel = string.gsub(partId, "_", " "),
            bodyRegion = (wounds and wounds.ClassifyBodyRegion and wounds.ClassifyBodyRegion(partId)) or "torso",
            woundType = wType,
            effectiveWoundTier = effTier,
            woundTierPriority = WOUND_PRIORITIES[wType] or 2,
            isBite = wType == "bite",
            salivaTransmissible = sal,
            knoxExposure = knoxExp,
            knoxStage = "none",
            physicalSeverityBand = physSev,
            severityBand = physSev,
        }
    end
    if not prof then return nil end
    prof.woundLabel = WOUND_LABELS[prof.woundType] or tostring(prof.woundType or "wound")
    prof.partToken = string.lower(tostring(prof.partLabel or prof.partId or "body"))
    prof.hasOpenWounds = prof.patchState == "with_wounds"
    return prof
end

function S.ResolveFightingInjuredVariant(profile)
    if type(profile) ~= "table" then return "default" end
    local patch = profile.patchState == "patched_up" and "patched_up" or "with_wounds"
    if profile.treatmentState == "dirty_dressing" or profile.hasDirtyBandage == true then
        return "with_wounds_dirty_bandage"
    end
    local tier = tostring(profile.effectiveWoundTier or "")
    if tier == "bite_possible_exposure" or tier == "bite_confirmed_symptomatic" or tier == "bite_non_transmissible" then
        return patch .. "_" .. tier
    end
    local group = FIGHTING_VARIANT_TABLE[patch]
    local sev = profile.physicalSeverityBand or profile.severityBand
    if sev == "minor" and (tonumber(profile.woundTierPriority) or 0) <= 2 then
        return group.minor_low_tier
    end
    local region = tostring(profile.bodyRegion or "torso")
    if sev == "critical" or sev == "severe" then
        return group[region .. "_severe"] or group[region] or "default"
    end
    return group[region] or "default"
end

function S.ResolveTransitionBeatVariant(_, transitionKind)
    return TRANSITION_VARIANTS[tostring(transitionKind or "")] or "default"
end

function S.BuildTransitionProfile(record, transitionSpec)
    local profile = S.ClassifyActorWoundProfile(record, transitionSpec)
    if profile then return profile end
    local wounds = PNC.NPCWounds
    local proj = wounds and type(wounds.GetOrBuildProjection) == "function" and wounds.GetOrBuildProjection(record) or nil
    local kind = tostring(transitionSpec and transitionSpec.kind or "condition")
    return {
        injured = false, patchState = "uninjured", treatmentState = proj and proj.treatmentState or "uninjured",
        partId = (transitionSpec and transitionSpec.partId) or "Torso_Upper", partLabel = "body", partToken = "body",
        bodyRegion = "torso", woundType = kind, woundLabel = kind, effectiveWoundTier = kind,
        woundTierPriority = 3, isBite = false, salivaTransmissible = false,
        knoxExposure = proj and proj.knoxExposure or "impossible", knoxStage = proj and proj.knoxStage or "none",
        physicalSeverityBand = "moderate", severityBand = "moderate", physiology = proj and proj.physiology or {},
    }
end

return S
