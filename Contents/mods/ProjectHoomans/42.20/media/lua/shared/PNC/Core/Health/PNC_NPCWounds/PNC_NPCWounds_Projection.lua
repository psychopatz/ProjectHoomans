PNC = PNC or {}
local Dims = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ProjectionDimensions"
local SelectedTruth = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_SelectedWoundTruth"
local Wounds = PNC.NPCWounds

function Wounds.InvalidateProjection(record, reason, summariesCurrent)
    if type(record) ~= "table" then return end
    local rt = type(record.runtime) == "table" and record.runtime or {}
    record.runtime = rt
    rt.healthProjectionDirty = true
    rt.woundSummariesCurrent = summariesCurrent == true
    rt.healthProjectionDirtyReason = tostring(reason or "mutated")
    rt.healthProjectionRev = (tonumber(rt.healthProjectionRev) or 0) + 1
    rt.injuryRevision = rt.healthProjectionRev
end

local function computeProjection(record, prefPart, prefType, recalculate)
    local health = type(record.health) == "table" and record.health or {}
    local body = health.body
    if (recalculate or not body) and type(Wounds.Recalculate) == "function" then
        body = Wounds.Recalculate(record)
        health = record.health or health
    end
    body = body or {}
    local openCount, bandagedCount = tonumber(body.openWoundCount) or 0, tonumber(body.bandagedWoundCount) or 0
    local patchedCount, bleedingRate = tonumber(body.patchedWoundCount) or bandagedCount, tonumber(body.bleedingRate) or 0
    local bleeding = bleedingRate > 0 or openCount > 0 or health.bleeding == true
    local curHp, maxHp = tonumber(health.current), math.max(1, tonumber(health.max) or 100)
    local overallRatio = curHp and math.max(0, math.min(1, curHp / maxHp)) or 1
    local stats = Wounds.Internal and Wounds.Internal.WoundStats or {}
    local bestPart, bestWound, worstRank, _, _, f = Dims.ScanWounds(body, prefPart, stats)
    bestPart = bestPart or SelectedTruth.LowestPart(body.parts) or "Torso_Upper"
    local norm = Wounds.NormalizeWoundType
    local rType = (bestWound and (norm and norm(bestWound.type) or bestWound.type))
        or (prefType and (norm and norm(prefType) or tostring(prefType))) or "scratch"
    if rType == "bite" then f.bite = true; if Dims.CanWoundTransmitKnox("bite") then f.transmissible = true end end
    local rStats = stats[rType]
    if worstRank == 0 and rStats then worstRank = tonumber(rStats.physicalSeverityRank) or 1 end
    local partRatio = Dims.PartHealthRatio(body, bestPart)
    local region = Wounds.ClassifyBodyRegion and Wounds.ClassifyBodyRegion(bestPart) or "torso"
    local hs = tostring(health.state or "")
    local injured = bleeding or openCount > 0 or patchedCount > 0 or hs == "injured" or hs == "wounded" or hs == "critical" or (curHp ~= nil and curHp < maxHp * 0.92)
    local physSev = injured and Dims.ResolvePhysicalSeverityBand(worstRank, partRatio, overallRatio, bleedingRate, region) or "none"
    local imp = Wounds.GetFunctionalImpairment and Wounds.GetFunctionalImpairment(record) or { kind = "none" }
    local knoxExp, knoxStg, knoxNL = Dims.NormalizeKnoxState(body, f.transmissible)
    local phys = SelectedTruth.BuildPhysiologySummary(body)
    local sw = SelectedTruth.Build(Dims, body, bestPart, bestWound, rType, rStats, partRatio, overallRatio, region, imp, knoxExp, knoxStg, phys)
    local effTier = (f.bite or rType == "bite")
        and (sw.knoxExposure == "impossible" and "bite_non_transmissible" or (sw.knoxExposure == "confirmed" and "bite_confirmed_symptomatic" or "bite_possible_exposure"))
        or rType
    local pDef = Wounds.Parts and Wounds.Parts[bestPart] or nil
    local total = 0; for _ in pairs(body.wounds or {}) do total = total + 1 end
    local wbPatch = not injured and "uninjured" or ((openCount > 0 or bleeding or f.dirty) and "with_wounds" or "patched_up")
    local wbTreat = Dims.ResolveTreatmentState(body.wounds)
    local effSev = sw.physicalSeverity ~= "none" and sw.physicalSeverity or physSev
    local out = {
        injured = injured, injuryRevision = (record.runtime and tonumber(record.runtime.healthProjectionRev)) or 1,
        totalWoundCount = total, woundCountBand = total <= 1 and "single" or (total <= 3 and "multiple" or "extensive"),
        patchState = sw.patchState ~= "uninjured" and sw.patchState or wbPatch,
        treatmentState = sw.treatmentState ~= "uninjured" and sw.treatmentState or wbTreat,
        wholeBodyPatchState = wbPatch, wholeBodyTreatmentState = wbTreat, selectedWound = sw,
        partId = bestPart, partLabel = pDef and pDef.label or bestPart, bodyRegion = region,
        woundType = rType, dominantWoundType = injured and rType or "none",
        effectiveWoundTier = effTier, woundTierPriority = rStats and tonumber(rStats.priority) or 1,
        physicalSeverityBand = effSev, severityBand = injured and effSev or "minor",
        bleedingBand = sw.bleedingBand, functionalImpairment = sw.functionalImpairment,
        wholeBodyFunctionalImpairment = imp.kind or "none", functionalDetails = imp,
        isBite = rType == "bite", hasBite = f.bite, hasBullet = f.bullet, hasGlass = f.glass, hasFracture = f.fracture,
        hasBurn = f.burn, hasDeepWound = f.deep_wound, hasLaceration = f.laceration, hasScratch = f.scratch,
        hasDirtyBandage = f.dirty, salivaTransmissible = Dims.ResolveSalivaTransmissible(),
        ordinaryInfectionBand = sw.ordinaryInfectionBand, ordinaryInfectionLevel = sw.woundInfectionLevel,
        knoxExposure = knoxExp, knoxStage = knoxStg, knoxNonLethal = knoxNL,
        physiology = phys, openWoundCount = openCount, bandagedWoundCount = bandagedCount,
        patchedWoundCount = patchedCount, bleedingRate = bleedingRate, partHealthRatio = partRatio,
        overallHealth = curHp or maxHp, overallHealthRatio = overallRatio,
    }
    for _, k in ipairs({ "bandaged", "bandageDirty", "splinted", "stitched", "cauterized", "haveGlass", "haveBullet", "bleeding", "ordinaryInfection", "woundInfectionLevel", "physicalSeverity", "bodyPart" }) do
        out[k] = sw[k]
    end
    return out
end

function Wounds.GetOrBuildProjection(record, opts)
    if type(record) ~= "table" or record.alive == false then return nil end
    if type(opts) ~= "table" then opts = nil end
    local rt = record.runtime
    if type(rt) ~= "table" then rt = {}; record.runtime = rt end
    local preferredPart = opts and opts.preferredPartId
    local preferredType = opts and opts.preferredWoundType
    local force = opts and opts.force == true
    local useDefault = not preferredPart and not preferredType
    if not force and useDefault and rt.healthProjection and rt.healthProjectionDirty ~= true then
        return rt.healthProjection
    end
    local proj = computeProjection(record, preferredPart, preferredType, force or not rt.woundSummariesCurrent)
    rt.woundSummariesCurrent = true
    if useDefault then rt.healthProjection = proj; rt.healthProjectionDirty = false end
    return proj
end

return Wounds
