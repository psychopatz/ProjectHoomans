PNC = PNC or {}
local Dims = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ProjectionDimensions"
local Wounds = PNC.NPCWounds

function Wounds.InvalidateProjection(record, reason)
    if type(record) ~= "table" then return end
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.healthProjectionDirty = true
    record.runtime.healthProjectionDirtyReason = tostring(reason or "mutated")
    record.runtime.healthProjectionRev = (tonumber(record.runtime.healthProjectionRev) or 0) + 1
end

local function lowestPart(parts)
    if type(parts) ~= "table" then return nil end
    local lowest, best = 1, nil
    for partId, partHealth in pairs(parts) do
        local r = (tonumber(partHealth and partHealth.current) or 100) / math.max(1, tonumber(partHealth and partHealth.max) or 100)
        if r < lowest then lowest = r; best = partId end
    end
    return best
end

local function buildPhysiologySummary(body)
    local p = type(body.physiology) == "table" and body.physiology or {}
    local inf = type(body.infection) == "table" and body.infection or nil
    local fever = math.max(tonumber(p.feverLevel) or 0, tonumber(inf and inf.fever) or 0)
    return {
        thermalBand = tostring(p.thermalBand or "normal"),
        wetnessBand = tostring(p.wetnessBand or "dry"),
        coldBand = tostring(p.coldBand or "none"),
        feverBand = p.feverBand or (fever >= 75 and "high_fever" or (fever >= 45 and "feverish" or (fever >= 15 and "low_grade" or "none"))),
        sicknessBand = tostring(p.sicknessBand or "none"),
        coreTempC = tonumber(p.coreTempC) or tonumber(inf and inf.temperatureC) or 37.0,
        wetness = tonumber(p.wetness) or 0,
        coldStrength = tonumber(p.coldStrength) or 0,
        feverLevel = fever,
        sicknessLevel = tonumber(p.sicknessLevel) or 0,
    }
end

local function computeProjection(record, preferredPartId, preferredWoundType)
    local body = type(Wounds.Recalculate) == "function" and Wounds.Recalculate(record) or (record.health and record.health.body) or {}
    local health = type(record.health) == "table" and record.health or {}
    local openCount, bandagedCount = tonumber(body.openWoundCount) or 0, tonumber(body.bandagedWoundCount) or 0
    local patchedCount, bleedingRate = tonumber(body.patchedWoundCount) or bandagedCount, tonumber(body.bleedingRate) or 0
    local bleeding = bleedingRate > 0 or openCount > 0 or health.bleeding == true
    local curHp, maxHp = tonumber(health.current), math.max(1, tonumber(health.max) or 100)
    local overallRatio = curHp and math.max(0, math.min(1, curHp / maxHp)) or 1
    local statsTable = Wounds.Internal and Wounds.Internal.WoundStats or {}
    local bestPartId, bestWound, worstRank, maxOrdInf, hasOrdInf, f = Dims.ScanWounds(body, preferredPartId, statsTable)
    bestPartId = bestPartId or lowestPart(body.parts) or "Torso_Upper"
    local resolvedType = (bestWound and (Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(bestWound.type) or bestWound.type))
        or (preferredWoundType and Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(preferredWoundType))
        or (preferredWoundType and tostring(preferredWoundType)) or "scratch"
    if resolvedType == "bite" then
        f.bite = true
        if Dims.CanWoundTransmitKnox("bite") then f.transmissible = true end
    end
    local rStats = statsTable[resolvedType]
    if worstRank == 0 and rStats then worstRank = tonumber(rStats.physicalSeverityRank) or 1 end
    local partRatio = Dims.PartHealthRatio(body, bestPartId)
    local region = Wounds.ClassifyBodyRegion and Wounds.ClassifyBodyRegion(bestPartId) or "torso"
    local hState = tostring(health.state or "")
    local injured = bleeding or openCount > 0 or patchedCount > 0 or hState == "injured" or hState == "wounded"
        or hState == "critical" or (curHp ~= nil and curHp < maxHp * 0.92)
    local physSev = injured and Dims.ResolvePhysicalSeverityBand(worstRank, partRatio, overallRatio, bleedingRate, region) or "none"
    local impairment = Wounds.GetFunctionalImpairment and Wounds.GetFunctionalImpairment(record) or { kind = "none" }
    local knoxExp, knoxStg, knoxNL = Dims.NormalizeKnoxState(body, f.transmissible)
    local saliva = Dims.ResolveSalivaTransmissible()
    local effectiveTier = resolvedType
    if f.bite or resolvedType == "bite" then effectiveTier = saliva and "bite_lethal" or "bite_non_transmissible" end
    local partDef = Wounds.Parts and Wounds.Parts[bestPartId] or nil
    return {
        injured = injured,
        patchState = not injured and "uninjured" or ((openCount > 0 or bleeding or f.dirty) and "with_wounds" or "patched_up"),
        treatmentState = Dims.ResolveTreatmentState(body.wounds),
        partId = bestPartId, partLabel = partDef and partDef.label or bestPartId, bodyRegion = region,
        woundType = resolvedType, dominantWoundType = injured and resolvedType or "none",
        effectiveWoundTier = effectiveTier, woundTierPriority = rStats and tonumber(rStats.priority) or 1,
        physicalSeverityBand = physSev, severityBand = injured and physSev or "minor",
        bleedingBand = Dims.ResolveBleedingBand(bleedingRate),
        functionalImpairment = impairment.kind or "none", functionalDetails = impairment,
        isBite = f.bite, hasBite = f.bite, hasBullet = f.bullet, hasGlass = f.glass, hasFracture = f.fracture,
        hasBurn = f.burn, hasDeepWound = f.deep_wound, hasLaceration = f.laceration, hasScratch = f.scratch,
        hasDirtyBandage = f.dirty, salivaTransmissible = saliva,
        ordinaryInfectionBand = Dims.ResolveOrdinaryInfectionBand(maxOrdInf, hasOrdInf),
        ordinaryInfectionLevel = maxOrdInf, knoxExposure = knoxExp, knoxStage = knoxStg, knoxNonLethal = knoxNL,
        physiology = buildPhysiologySummary(body), openWoundCount = openCount, bandagedWoundCount = bandagedCount,
        patchedWoundCount = patchedCount, bleedingRate = bleedingRate, partHealthRatio = partRatio,
        overallHealth = curHp or maxHp, overallHealthRatio = overallRatio,
    }
end

function Wounds.GetOrBuildProjection(record, opts)
    if type(record) ~= "table" or record.alive == false then return nil end
    opts = type(opts) == "table" and opts or {}
    local rt = type(record.runtime) == "table" and record.runtime or {}
    record.runtime = rt
    if opts.force ~= true and not opts.preferredPartId and not opts.preferredWoundType
        and rt.healthProjection and rt.healthProjectionDirty ~= true
    then
        return rt.healthProjection
    end
    local proj = computeProjection(record, opts.preferredPartId, opts.preferredWoundType)
    if not opts.preferredPartId and not opts.preferredWoundType then
        rt.healthProjection = proj
        rt.healthProjectionDirty = false
    end
    return proj
end

return Wounds
