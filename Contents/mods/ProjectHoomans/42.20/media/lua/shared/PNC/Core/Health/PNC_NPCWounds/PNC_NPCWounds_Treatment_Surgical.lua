PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Core = PNC.Core

local function getWritableWound(record, partId)
    if not record or record.alive == false then return nil, nil, "invalid_target" end
    if Core and type(Core.IsAuthority) == "function" and Core.IsAuthority() ~= true then
        return nil, nil, "not_authority"
    end
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound then return nil, body, "wound_missing" end
    return wound, body, nil
end

local function finishTreatment(record, reason)
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, reason) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
end

function Wounds.Disinfect(record, partId, options)
    local wound, _, err = getWritableWound(record, partId)
    if not wound then return false, err end
    options = type(options) == "table" and options or {}
    local strength = math.max(0.5, math.min(5, tonumber(options.alcoholStrength) or 2.0))
    wound.alcoholLevel = math.min(5, (tonumber(wound.alcoholLevel) or 0) + strength)
    local lvl = tonumber(wound.woundInfectionLevel) or 0
    if lvl > 0 then
        wound.woundInfectionLevel = math.max(0, lvl - strength * 0.5)
        wound.infectedWound = wound.woundInfectionLevel >= 0.5
    end
    finishTreatment(record, "disinfected")
    return true, "disinfected"
end

function Wounds.Cauterize(record, partId, options)
    local wound, _, err = getWritableWound(record, partId)
    if not wound then return false, err end
    if wound.cauterized == true then return false, "already_cauterized" end
    wound.cauterized = true
    wound.burned = true
    wound.bleedingRate = 0
    wound.infectedWound = false
    wound.woundInfectionLevel = 0
    finishTreatment(record, "cauterized")
    return true, "cauterized"
end

function Wounds.RemoveGlass(record, partId)
    local wound, _, err = getWritableWound(record, partId)
    if not wound then return false, err end
    if wound.haveGlass ~= true then return false, "no_glass" end
    wound.haveGlass = false
    if wound.type == "deep_wound_glass" then wound.type = "deep_wound" end
    finishTreatment(record, "removed_glass")
    return true, "removed_glass"
end

function Wounds.RemoveBullet(record, partId)
    local wound, _, err = getWritableWound(record, partId)
    if not wound then return false, err end
    if wound.haveBullet ~= true then return false, "no_bullet" end
    wound.haveBullet = false
    if wound.type == "bullet" then wound.type = "deep_wound" end
    finishTreatment(record, "removed_bullet")
    return true, "removed_bullet"
end

return Wounds
