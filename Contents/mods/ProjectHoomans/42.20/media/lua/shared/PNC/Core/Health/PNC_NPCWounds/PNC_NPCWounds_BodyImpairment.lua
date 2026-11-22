PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Core = PNC.Core

function Wounds.GetVitalPartFailure(record, requestedPartId)
    local body = Wounds.Ensure(record)
    if not body then return nil end
    if requestedPartId ~= nil then
        local partId = tostring(requestedPartId)
        if not Wounds.Parts[partId] or (partId ~= "Head" and partId ~= "Torso_Upper" and partId ~= "Torso_Lower") then
            return nil
        end
        local partHealth = body.parts[partId]
        if partHealth and (tonumber(partHealth.current) or 0) <= 0 then
            return { id = partId, current = 0, max = tonumber(partHealth.max) or 100 }
        end
        return nil
    end
    for i = 1, #Wounds.VitalPartOrder do
        local partId = Wounds.VitalPartOrder[i]
        local partHealth = body.parts[partId]
        if partHealth and (tonumber(partHealth.current) or 0) <= 0 then
            return { id = partId, current = 0, max = tonumber(partHealth.max) or 100 }
        end
    end
    return nil
end

local function resolveLegFailure(body, side, threshold)
    local parts = Wounds.LocomotionPartOrder and Wounds.LocomotionPartOrder[side]
    if not parts then return nil end
    local lowestRatio, lowestPart = 1, nil
    for i = 1, #parts do
        local partId = parts[i]
        local partHealth = body.parts[partId]
        local ratio = partHealth and (tonumber(partHealth.current) or 0) / math.max(1, tonumber(partHealth.max) or 100) or 1
        if ratio < lowestRatio then lowestRatio = ratio; lowestPart = partId end
    end
    if lowestRatio <= threshold then
        return { side = side, partId = lowestPart, ratio = Core.Clamp(lowestRatio, 0, 1) }
    end
    return nil
end

local function resolvePelvicFailure(body, threshold)
    local partHealth = body.parts and body.parts.Groin or nil
    local maxHp = math.max(1, tonumber(partHealth and partHealth.max) or 100)
    local curHp = tonumber(partHealth and partHealth.current) or maxHp
    local ratio = Core.Clamp(curHp / maxHp, 0, 1)
    local wound = body.wounds and body.wounds.Groin or nil
    local wType = wound and (Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(wound.type) or wound.type) or nil
    local severeTrauma = wound ~= nil and (
        (wType == "fracture" and wound.splinted ~= true)
        or wType == "bullet" or wType == "deep_wound" or wType == "deep_wound_glass"
        or (tonumber(wound.bleedingRate) or 0) >= 0.055
    )
    if ratio <= threshold or severeTrauma then
        return { partId = "Groin", ratio = ratio, severeTrauma = severeTrauma }
    end
    return nil
end

function Wounds.GetMobilityState(record)
    local health = record and record.health or nil
    local threshold = tonumber(PNC.Const and PNC.Const.LIMP_HEALTH_RATIO) or 0.40
    if not record or record.alive == false or not health or health.state ~= "normal" then return nil end
    local body = Wounds.Ensure(record)
    local left = resolveLegFailure(body, "left", threshold)
    local right = resolveLegFailure(body, "right", threshold)
    local pelvic = resolvePelvicFailure(body, threshold)
    if not left and not right and not pelvic then return nil end
    if left and right then
        return {
            mode = "limp", profileKey = "limp", side = "bilateral",
            ratio = math.min(left.ratio, right.ratio, pelvic and pelvic.ratio or 1),
            leftPartId = left.partId, rightPartId = right.partId,
            pelvicTrauma = pelvic ~= nil, groinPartId = pelvic and "Groin" or nil, threshold = threshold,
        }
    end
    local chosen = left or right or { side = "pelvis", partId = "Groin", ratio = pelvic.ratio }
    return {
        mode = "limp", profileKey = "limp", side = chosen.side,
        ratio = pelvic and math.min(chosen.ratio, pelvic.ratio) or chosen.ratio,
        partId = chosen.partId, pelvicTrauma = pelvic ~= nil,
        groinPartId = pelvic and "Groin" or nil, threshold = threshold,
    }
end

function Wounds.GetFunctionalImpairment(record)
    if not record or record.alive == false then return { kind = "none", regions = {} } end
    local body = Wounds.Ensure(record)
    local mobility = Wounds.GetMobilityState(record)
    local regions = {}
    for partId, wound in pairs(body.wounds or {}) do
        local region = Wounds.ClassifyBodyRegion and Wounds.ClassifyBodyRegion(partId) or "torso"
        local unstabilized = wound.bandaged ~= true or (wound.type == "fracture" and wound.splinted ~= true)
            or wound.haveBullet == true or wound.haveGlass == true
        if unstabilized or (tonumber(wound.damage) or 0) >= 6 then regions[region] = true end
    end
    for i = 1, #Wounds.PartOrder do
        local id = Wounds.PartOrder[i]
        local p = body.parts[id]
        local r = p and ((tonumber(p.current) or 100) / math.max(1, tonumber(p.max) or 100)) or 1
        if r <= 0.65 then regions[Wounds.ClassifyBodyRegion and Wounds.ClassifyBodyRegion(id) or "torso"] = true end
    end
    local count = 0
    for _ in pairs(regions) do count = count + 1 end
    local pelvicImpaired = regions.pelvis_groin == true or (mobility ~= nil and mobility.pelvicTrauma == true)
    local kind = "none"
    if count >= 2 then kind = "multi_system"
    elseif regions.head_neck then kind = "vision_head"
    elseif regions.torso then kind = "breathing_core"
    elseif pelvicImpaired then kind = "pelvic_mobility"
    elseif regions.lower_limb or mobility ~= nil then kind = "limb_mobility"
    elseif regions.upper_limb then kind = "weapon_control" end
    return {
        kind = kind, mobilityState = mobility,
        headImpaired = regions.head_neck == true, torsoImpaired = regions.torso == true,
        pelvicImpaired = pelvicImpaired, upperLimbImpaired = regions.upper_limb == true,
        lowerLimbImpaired = regions.lower_limb == true,
        weaponImpaired = regions.upper_limb == true or regions.head_neck == true,
        regions = regions,
    }
end

return Wounds
