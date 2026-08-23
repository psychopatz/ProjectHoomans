PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.GetBandageQuality(fullType)
    return Internal.BandageQuality[tostring(fullType or "")]
        or Internal.BandageQuality["Base.RippedSheets"]
end

function Wounds.GetTreatableWounds(record)
    local body = Wounds.Ensure(record)
    local output = {}
    local i
    local partId
    local wound
    for i = 1, #Wounds.PartOrder do
        partId = Wounds.PartOrder[i]
        wound = body.wounds[partId]
        if wound
            and (
                wound.bandaged ~= true
                or wound.bandageDirty == true
            )
        then
            output[#output + 1] = {
                partId = partId,
                wound = wound,
            }
        end
    end
    return output
end

function Wounds.FindTreatableWound(record)
    local wounds = Wounds.GetTreatableWounds(record)
    return wounds[1] and wounds[1].partId or nil,
        wounds[1] and wounds[1].wound or nil
end

function Wounds.Bandage(record, partId, now, options)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if type(now) == "table" and options == nil then
        options = now
        now = nil
    end
    options = type(options) == "table" and options or {}
    if not wound then return false, "wound_missing" end
    if wound.bandaged == true
        and wound.bandageDirty ~= true
    then
        return false, "already_bandaged"
    end
    now = tonumber(now) or Core.Now()
    local currentHour = Internal.WorldHour()
    wound.bandaged = true
    wound.bandagedAt = now
    wound.bandageType =
        tostring(options.bandageType or "Base.RippedSheets")
    wound.bandageName =
        tostring(options.bandageName or wound.bandageType)
    wound.bandageDirty = false
    wound.bandageAppliedWorldHour = currentHour
    wound.lastHealWorldHour = currentHour
    wound.dirtyAtWorldHour = currentHour + math.max(
        0.25,
        tonumber(options.dirtyAfterWorldHours)
            or tonumber(Const.BANDAGE_DIRTY_AFTER_WORLD_HOURS)
            or 8
    )
    wound.firstAidLevel = Core.Clamp(
        math.floor(tonumber(options.firstAidLevel) or 0),
        0,
        10
    )
    wound.healRatePerWorldHour = (
        (tonumber(Const.BANDAGE_HEAL_PER_WORLD_HOUR) or 1.5)
        + wound.firstAidLevel
            * (
                tonumber(
                    Const.BANDAGE_FIRST_AID_HEAL_BONUS
                ) or 0.25
            )
    ) * Internal.GetBandageQuality(wound.bandageType)
    wound.bandageInitialDamage = math.max(
        0,
        tonumber(wound.damage)
            or tonumber(wound.severity)
            or 0
    )
    wound.bandageHealedPoints = 0
    wound.healAtWorldHour = 0
    Wounds.Recalculate(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, "bandaged"
end

function Wounds.DebugAlmostDirty(record, partId)
    if not record or record.alive == false then
        return false, "invalid_target"
    end
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound then return false, "wound_missing" end
    if wound.bandaged ~= true then
        return false, "not_bandaged"
    end
    if wound.bandageDirty == true then
        return false, "already_dirty"
    end
    local currentHour = Internal.WorldHour()
    wound.dirtyAtWorldHour = currentHour + math.max(
        0.001,
        tonumber(
            Const.DEBUG_BANDAGE_ALMOST_DIRTY_WORLD_HOURS
        ) or 0.02
    )
    wound.lastHealWorldHour = math.min(
        tonumber(wound.lastHealWorldHour) or currentHour,
        currentHour
    )
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        "debug_bandage_almost_dirty"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, "bandage_almost_dirty"
end

function Wounds.BandageAll(record, now, options)
    local body = Wounds.Ensure(record)
    local changed = false
    now = tonumber(now) or Core.Now()
    local partId
    local wound
    for partId, wound in pairs(body.wounds) do
        if wound.bandaged ~= true
            or wound.bandageDirty == true
        then
            if Wounds.Bandage(
                record,
                partId,
                now,
                options
            ) then
                changed = true
            end
        end
    end
    Wounds.Recalculate(record)
    return changed
end

return Wounds
