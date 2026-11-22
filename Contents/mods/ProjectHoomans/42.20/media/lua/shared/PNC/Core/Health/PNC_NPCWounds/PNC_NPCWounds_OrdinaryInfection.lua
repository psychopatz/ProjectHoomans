PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

function Internal.EmitWoundStateChange(record, partId, changeKind, wound)
    if Internal.Events and Internal.EventTypes and Internal.EventTypes.NPC_WOUND_STATE_CHANGED then
        Internal.Events.emit(Internal.EventTypes.NPC_WOUND_STATE_CHANGED, record, partId, changeKind, wound)
    end
end

function Internal.UpdateOrdinaryWoundInfection(record, partId, wound, currentHour)
    if wound.lastInfectionHour == nil then
        wound.lastInfectionHour = currentHour
        return false
    end
    local lastHour = tonumber(wound.lastInfectionHour) or currentHour
    local dt = math.max(0, currentHour - lastHour)
    if dt <= 0 then return false end
    wound.lastInfectionHour = currentHour
    local lvl = tonumber(wound.woundInfectionLevel) or 0
    local alc = tonumber(wound.alcoholLevel) or 0
    local delta = 0
    if wound.bandageDirty == true or wound.haveGlass == true or wound.haveBullet == true then
        delta = delta + 0.35 * dt
    elseif wound.bandaged ~= true and wound.cauterized ~= true and (tonumber(wound.bleedingRate) or 0) > 0 then
        delta = delta + 0.15 * dt
    elseif wound.bandaged == true or wound.stitched == true then
        delta = delta - 0.25 * dt
    end
    if alc > 0 then
        delta = delta - 0.80 * dt
        wound.alcoholLevel = math.max(0, alc - 0.50 * dt)
    end
    local nextLvl = Core.Clamp(lvl + delta, 0, 10)
    local wasInf = wound.infectedWound == true
    local nowInf = nextLvl >= 0.5
    local changed = math.abs(nextLvl - lvl) >= 0.01 or wasInf ~= nowInf
    wound.woundInfectionLevel = nextLvl
    wound.infectedWound = nowInf
    if wasInf ~= nowInf then
        if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "ordinary_infection") end
        Internal.EmitWoundStateChange(record, partId, nowInf and "ordinary_infection_onset" or "ordinary_infection_cleared", wound)
    end
    return changed
end

return Wounds
