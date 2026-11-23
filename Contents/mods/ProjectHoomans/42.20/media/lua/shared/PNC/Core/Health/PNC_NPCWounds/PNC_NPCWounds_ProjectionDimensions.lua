PNC = PNC or {}
local Wounds = PNC.NPCWounds

local Dims = {}

function Dims.ResolveSalivaTransmissible()
    local sb = PNC.Sandbox
    if sb and type(sb.IsZombieSalivaTransmissible) == "function" then
        return sb.IsZombieSalivaTransmissible() == true
    end
    return true
end

function Dims.CanWoundTransmitKnox(woundType)
    local sb = PNC.Sandbox
    if sb and type(sb.CanZombieWoundTransmitKnox) == "function" then
        return sb.CanZombieWoundTransmitKnox(woundType) == true
    end
    return tostring(woundType or "") == "bite" and Dims.ResolveSalivaTransmissible()
end

function Dims.PartHealthRatio(body, partId)
    local p = partId and body and body.parts and body.parts[partId] or nil
    if type(p) ~= "table" then return 1 end
    local mx = math.max(1, tonumber(p.max) or 100)
    return math.max(0, math.min(1, (tonumber(p.current) or mx) / mx))
end

function Dims.ResolvePhysicalSeverityBand(rank, partRatio, overallRatio, bleedingRate, region)
    local mult = (region == "head_neck" or region == "torso" or region == "pelvis_groin") and 1.15 or 1.0
    local effBleed = bleedingRate * mult
    if rank >= 5 or partRatio <= 0.35 or overallRatio <= 0.40 or effBleed >= 0.085 then return "critical" end
    if rank >= 4 or partRatio <= 0.55 or overallRatio <= 0.65 or effBleed >= 0.058 then return "severe" end
    if rank >= 2 or partRatio <= 0.78 or overallRatio <= 0.82 or bleedingRate >= 0.025 then return "moderate" end
    return "minor"
end

function Dims.ResolveBleedingBand(bleedingRate)
    if bleedingRate >= 0.085 then return "critical" end
    if bleedingRate >= 0.060 then return "heavy" end
    if bleedingRate >= 0.030 then return "moderate" end
    if bleedingRate > 0 then return "minor" end
    return "none"
end

function Dims.ResolveOrdinaryInfectionBand(level, infectedFlag)
    if level >= 6.0 then return "severe" end
    if level >= 2.5 then return "moderate" end
    if level >= 0.5 or infectedFlag then return "mild" end
    return "none"
end

function Dims.ResolveTreatmentState(wounds)
    local count, openCount, dirtyCount, stitched, splinted, cauterized, foreign, bandaged = 0, 0, 0, 0, 0, 0, 0, 0
    for _, w in pairs(wounds or {}) do
        count = count + 1
        if w.haveBullet == true or w.haveGlass == true then foreign = foreign + 1 end
        if w.bandageDirty == true then dirtyCount = dirtyCount + 1 end
        if w.cauterized == true then cauterized = cauterized + 1 end
        if w.stitched == true then stitched = stitched + 1 end
        if w.splinted == true then splinted = splinted + 1 end
        if w.bandaged == true then bandaged = bandaged + 1 end
        local stable = w.bandaged == true or (w.type == "fracture" and w.splinted == true)
            or (w.stitched == true and (tonumber(w.bleedingRate) or 0) <= 0) or w.cauterized == true
        if not stable then openCount = openCount + 1 end
    end
    if count == 0 then return "uninjured" end
    if dirtyCount > 0 then return "dirty_dressing" end
    if foreign > 0 then return "lodged_foreign_body" end
    if openCount > 0 then return "open_untreated" end
    local kinds = (bandaged > 0 and 1 or 0) + (stitched > 0 and 1 or 0) + (splinted > 0 and 1 or 0) + (cauterized > 0 and 1 or 0)
    if kinds > 1 then return "mixed_stabilized" end
    if cauterized > 0 then return "cauterized" end
    if splinted > 0 then return "splinted" end
    if stitched > 0 then return "stitched" end
    return "bandaged"
end

function Dims.NormalizeKnoxState(body, hasTransmissibleWound)
    local inf = type(body.infection) == "table" and body.infection or nil
    local nonLethal = inf and inf.nonLethalFever == true or false
    local rawStage = inf and tostring(inf.stage or "incubating") or "none"
    local active = inf and (inf.active == true or inf.fatal == true or inf.pendingFatal == true)
    local stage = "none"
    if active or rawStage == "recovering" then
        if rawStage == "terminal" or rawStage == "fatal" then stage = "critical"
        elseif rawStage == "queasy" or rawStage == "nauseous" then stage = "prodrome"
        elseif rawStage == "fever" or rawStage == "incubating" or rawStage == "recovering" then stage = rawStage
        else stage = "incubating" end
    end
    local exposure = "impossible"
    if active and stage ~= "incubating" then exposure = "confirmed"
    elseif hasTransmissibleWound or body.knoxExposureState == "possible" or active then exposure = "possible" end
    return exposure, stage, nonLethal
end

function Dims.ScanWounds(body, preferredPartId, statsTable)
    local wounds = type(body.wounds) == "table" and body.wounds or {}
    local bestPartId = preferredPartId and tostring(preferredPartId) or nil
    local bestWound = bestPartId and wounds[bestPartId] or nil
    local bestPri, worstRank, maxOrdInf, hasOrdInf = -1, 0, 0, false
    local f = {
        bite = false, bullet = false, glass = false, fracture = false,
        burn = false, deep_wound = false, laceration = false, scratch = false,
        dirty = false, transmissible = false,
    }
    for partId, wound in pairs(wounds) do
        local wType = Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(wound.type) or tostring(wound.type or "scratch")
        local st = statsTable[wType]
        local pRank = (st and tonumber(st.physicalSeverityRank)) or 1
        if pRank > worstRank then worstRank = pRank end
        f[wType] = true
        if wound.haveBullet == true then f.bullet = true end
        if wound.haveGlass == true then f.glass = true end
        if wound.bandageDirty == true then f.dirty = true end
        local ordLvl = tonumber(wound.woundInfectionLevel) or 0
        if ordLvl > maxOrdInf then maxOrdInf = ordLvl end
        if wound.infectedWound == true then hasOrdInf = true end
        if (wound.zombieWound == true or wType == "bite") and Dims.CanWoundTransmitKnox(wType) then
            f.transmissible = true
        end
        local pri = (st and tonumber(st.priority) or 1) + (wound.bandaged ~= true and 10 or 0)
            + (preferredPartId ~= nil and partId == tostring(preferredPartId) and 100 or 0)
        if pri > bestPri then bestPri = pri; bestPartId = partId; bestWound = wound end
    end
    return bestPartId, bestWound, worstRank, maxOrdInf, hasOrdInf, f
end

Wounds.Internal = Wounds.Internal or {}
Wounds.Internal.ProjectionDims = Dims
return Dims
