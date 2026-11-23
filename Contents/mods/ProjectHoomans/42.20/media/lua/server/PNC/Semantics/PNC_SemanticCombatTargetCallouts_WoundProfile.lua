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
    bite = "bite", bullet = "gunshot wound", deep_wound_glass = "glass gash",
    deep_wound = "deep wound", fracture = "fracture", burn = "burn",
    laceration = "laceration", scratch = "scratch",
}

local WOUND_PRIORITIES = {
    scratch = 2, laceration = 3, burn = 4, fracture = 4,
    deep_wound = 4, deep_wound_glass = 4, bullet = 5, bite = 6,
}

local function salivaTransmissible()
    local sb = PNC.Sandbox
    return not (sb and type(sb.IsZombieSalivaTransmissible) == "function") or sb.IsZombieSalivaTransmissible() == true
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
        local effTier = wType == "bite" and (sal and "bite_possible_exposure" or "bite_non_transmissible") or wType
        local physSev = (wType == "bullet") and "critical" or ((wType == "bite" or wType == "deep_wound") and "severe" or "moderate")
        local region = (wounds and wounds.ClassifyBodyRegion and wounds.ClassifyBodyRegion(partId)) or "torso"
        prof = {
            injured = true, patchState = hitSpec.bandaged == true and "patched_up" or "with_wounds",
            treatmentState = hitSpec.bandaged == true and "bandaged" or "open_untreated",
            partId = partId, partLabel = string.gsub(partId, "_", " "), bodyRegion = region,
            woundType = wType, effectiveWoundTier = effTier, woundTierPriority = WOUND_PRIORITIES[wType] or 2,
            isBite = wType == "bite", salivaTransmissible = sal, knoxExposure = knoxExp, knoxStage = "none",
            physicalSeverityBand = physSev, severityBand = physSev,
            selectedWound = {
                woundType = wType, bodyPart = partId, bodyRegion = region,
                bandaged = hitSpec.bandaged == true, splinted = hitSpec.splinted == true,
                stitched = hitSpec.stitched == true, physicalSeverity = physSev,
                functionalImpairment = wType == "fracture" and "limb_mobility" or "none",
                locomotionImpaired = wType == "fracture" and (region == "lower_limb" or region == "pelvis_groin"),
                knoxExposure = knoxExp,
            },
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
    local sel = type(profile.selectedWound) == "table" and profile.selectedWound or profile
    if sel.bandageDirty == true or sel.treatmentState == "dirty_dressing" then
        return "with_wounds_dirty_bandage"
    end
    local isStabilized = sel.bandaged == true or sel.stitched == true or sel.splinted == true or sel.cauterized == true
        or profile.patchState == "patched_up"
    local patch = isStabilized and "patched_up" or "with_wounds"
    local tier = tostring(profile.effectiveWoundTier or "")
    if tier == "bite_possible_exposure" or tier == "bite_confirmed_symptomatic" or tier == "bite_non_transmissible" then
        return patch .. "_" .. tier
    end
    local sev = sel.physicalSeverity or profile.physicalSeverityBand or profile.severityBand
    if sev == "minor" and (tonumber(profile.woundTierPriority) or 0) <= 2 then
        return patch .. "_minor"
    end
    local region = tostring(sel.bodyRegion or profile.bodyRegion or "torso")
    local funcImp = tostring(sel.functionalImpairment or profile.functionalImpairment or "none")
    local locoImpaired = sel.locomotionImpaired == true
        or funcImp == "limb_mobility" or funcImp == "pelvic_mobility" or funcImp == "multi_system"
    if (region == "lower_limb" or region == "pelvis_groin") and not locoImpaired then
        return patch .. "_" .. region
    end
    if sev == "critical" or sev == "severe" then
        local sevSuffix = (patch == "with_wounds" and (region == "head_neck" or region == "torso")) and "_critical" or "_severe"
        return patch .. "_" .. region .. sevSuffix
    end
    return patch .. "_" .. region
end

function S.ResolveTransitionBeatVariant(_, transitionKind)
    local k = tostring(transitionKind or "")
    return k ~= "" and k or "default"
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
