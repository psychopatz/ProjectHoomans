-- Selected-wound truth extraction for dialogue and realization firewalls.
PNC = PNC or {}
local Wounds = PNC.NPCWounds

local SelectedTruth = {}

local LOCOMOTION_IMPAIRMENTS = {
    limb_mobility = true,
    pelvic_mobility = true,
    multi_system = true,
}
SelectedTruth.LOCOMOTION_IMPAIRMENTS = LOCOMOTION_IMPAIRMENTS

local function selectedTreatmentState(w)
    if type(w) ~= "table" then return "uninjured", "uninjured" end
    if w.bandageDirty == true then return "dirty_dressing", "with_wounds" end
    if w.haveBullet == true or w.haveGlass == true then return "lodged_foreign_body", "with_wounds" end
    local wType = Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(w.type) or tostring(w.type or "scratch")
    local bandaged, stitched, splinted, cauterized = w.bandaged == true, w.stitched == true, w.splinted == true, w.cauterized == true
    local stable = bandaged or (wType == "fracture" and splinted)
        or (stitched and (tonumber(w.bleedingRate) or 0) <= 0) or cauterized
    if not stable then return "open_untreated", "with_wounds" end
    local kinds = (bandaged and 1 or 0) + (stitched and 1 or 0) + (splinted and 1 or 0) + (cauterized and 1 or 0)
    if kinds > 1 then return "mixed_stabilized", "patched_up" end
    if cauterized then return "cauterized", "patched_up" end
    if splinted then return "splinted", "patched_up" end
    if stitched then return "stitched", "patched_up" end
    return "bandaged", "patched_up"
end

local function selectedFunctionalImpairment(partId, region, partRatio, wound, actorImpairment)
    if type(wound) ~= "table" and partRatio > 0.65 then return "none" end
    local wType = wound and (Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(wound.type) or tostring(wound.type or "scratch")) or "none"
    local mob = type(actorImpairment) == "table" and actorImpairment.mobilityState or nil
    if region == "pelvis_groin" then
        local severePelvic = (wType == "fracture" and wound.splinted ~= true)
            or wType == "bullet" or wType == "deep_wound" or wType == "deep_wound_glass"
            or (tonumber(wound and wound.bleedingRate) or 0) >= 0.055
            or partRatio <= 0.40 or (mob and mob.pelvicTrauma == true)
        return severePelvic and "pelvic_mobility" or "none"
    end
    if region == "lower_limb" then
        local legLimp = (wType == "fracture" and wound.splinted ~= true)
            or partRatio <= 0.40
            or (mob and (mob.partId == partId or mob.leftPartId == partId or mob.rightPartId == partId))
        return legLimp and "limb_mobility" or "none"
    end
    if region == "upper_limb" then
        local armImp = (wound and (wound.bandaged ~= true or (tonumber(wound.damage) or 0) >= 6)) or partRatio <= 0.65
        return armImp and "weapon_control" or "none"
    end
    if region == "head_neck" then return (wound ~= nil or partRatio <= 0.65) and "vision_head" or "none" end
    if region == "torso" then return (wound ~= nil or partRatio <= 0.65) and "breathing_core" or "none" end
    return "none"
end

function SelectedTruth.Build(Dims, body, partId, wound, resolvedType, rStats, partRatio, overallRatio, region, actorImpairment, knoxExp, knoxStg, physiology)
    local w = type(wound) == "table" and wound or nil
    local treatState, patchState = selectedTreatmentState(w)
    local bRate = tonumber(w and w.bleedingRate) or 0
    local bandaged, bandageDirty = w and w.bandaged == true or false, w and w.bandageDirty == true or false
    local splinted, stitched, cauterized = w and w.splinted == true or false, w and w.stitched == true or false, w and w.cauterized == true or false
    local haveGlass, haveBullet = w and w.haveGlass == true or false, w and w.haveBullet == true or false
    local bleeding = (bRate > 0 and not bandaged and not cauterized and not stitched) or bandageDirty
    local ordLevel = tonumber(w and w.woundInfectionLevel) or 0
    local ordBand = Dims.ResolveOrdinaryInfectionBand(ordLevel, w and w.infectedWound == true or false)
    local pRank = (rStats and tonumber(rStats.physicalSeverityRank)) or 1
    local physSev = Dims.ResolvePhysicalSeverityBand(pRank, partRatio, overallRatio, bRate, region)
    local selFunc = selectedFunctionalImpairment(partId, region, partRatio, w, actorImpairment)
    local partDef = Wounds.Parts and Wounds.Parts[partId] or nil
    local wKnoxExp = "impossible"
    if w and (w.zombieWound == true or resolvedType == "bite") and Dims.CanWoundTransmitKnox(resolvedType) then
        wKnoxExp = (knoxExp == "confirmed") and "confirmed" or "possible"
    end
    return {
        woundType = resolvedType, bodyPart = partId, partLabel = partDef and partDef.label or partId,
        bodyRegion = region, bandaged = bandaged, bandageDirty = bandageDirty,
        splinted = splinted, stitched = stitched, cauterized = cauterized,
        haveGlass = haveGlass, haveBullet = haveBullet, bleeding = bleeding,
        bleedingRate = bRate, bleedingBand = Dims.ResolveBleedingBand(bRate),
        ordinaryInfection = ordBand ~= "none", ordinaryInfectionBand = ordBand,
        woundInfectionLevel = ordLevel, physicalSeverity = physSev,
        treatmentState = treatState, patchState = patchState,
        functionalImpairment = selFunc, locomotionImpaired = LOCOMOTION_IMPAIRMENTS[selFunc] == true,
        knoxExposure = wKnoxExp, knoxStage = wKnoxExp ~= "impossible" and knoxStg or "none",
        feverActive = type(physiology) == "table" and tostring(physiology.feverBand or "none") ~= "none",
    }
end

function SelectedTruth.BuildPhysiologySummary(body)
    local p = type(body.physiology) == "table" and body.physiology or {}
    local inf = type(body.infection) == "table" and body.infection or nil
    local fever = math.max(tonumber(p.feverLevel) or 0, tonumber(inf and inf.fever) or 0)
    return {
        thermalBand = tostring(p.thermalBand or "normal"), wetnessBand = tostring(p.wetnessBand or "dry"),
        coldBand = tostring(p.coldBand or "none"),
        feverBand = p.feverBand or (fever >= 75 and "high_fever" or (fever >= 45 and "feverish" or (fever >= 15 and "low_grade" or "none"))),
        sicknessBand = tostring(p.sicknessBand or "none"),
        coreTempC = tonumber(p.coreTempC) or tonumber(inf and inf.temperatureC) or 37.0,
        wetness = tonumber(p.wetness) or 0, coldStrength = tonumber(p.coldStrength) or 0,
        feverLevel = fever, sicknessLevel = tonumber(p.sicknessLevel) or 0,
    }
end

function SelectedTruth.LowestPart(parts)
    if type(parts) ~= "table" then return nil end
    local lowest, best = 1, nil
    for partId, ph in pairs(parts) do
        local r = (tonumber(ph and ph.current) or 100) / math.max(1, tonumber(ph and ph.max) or 100)
        if r < lowest then lowest = r; best = partId end
    end
    return best
end

Wounds.Internal = Wounds.Internal or {}
Wounds.Internal.SelectedWoundTruth = SelectedTruth
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TruthValidation"
return SelectedTruth
