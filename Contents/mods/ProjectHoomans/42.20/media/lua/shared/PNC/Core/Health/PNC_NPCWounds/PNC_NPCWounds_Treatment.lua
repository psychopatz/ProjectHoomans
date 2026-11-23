PNC = PNC or {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Treatment_Surgical"

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.GetBandageQuality(fullType)
    return Internal.BandageQuality[tostring(fullType or "")]
        or Internal.BandageQuality["Base.RippedSheets"]
end

local function isTreatable(wound)
    return wound and not (wound.type == "fracture" and wound.splinted == true and wound.bandaged == true)
        and ((wound.bandaged ~= true and not (wound.type == "fracture" and wound.splinted == true))
            or wound.bandageDirty == true)
end

function Wounds.GetTreatableWounds(record)
    local body = Wounds.Ensure(record)
    local output = {}
    for i = 1, #Wounds.PartOrder do
        local partId = Wounds.PartOrder[i]
        local wound = body.wounds[partId]
        if isTreatable(wound) then output[#output + 1] = { partId = partId, wound = wound } end
    end
    return output
end

function Wounds.FindTreatableWound(record, preferredPart)
    local body = Wounds.Ensure(record)
    if preferredPart then
        local wound = body.wounds[preferredPart]
        if isTreatable(wound) then return preferredPart, wound end
        return nil
    end
    for i = 1, #Wounds.PartOrder do
        local part = Wounds.PartOrder[i]
        local wound = body.wounds[part]
        if isTreatable(wound) then return part, wound end
    end
end

function Wounds.Bandage(record, partId, now, options)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if type(now) == "table" and options == nil then options = now; now = nil end
    options = type(options) == "table" and options or {}
    if not wound then return false, "wound_missing" end
    if wound.bandaged == true and wound.bandageDirty ~= true then return false, "already_bandaged" end
    now = tonumber(now) or Core.Now()
    local currentHour = Internal.WorldHour()
    wound.bandaged = true
    wound.bandagedAt = now
    wound.bandageType = tostring(options.bandageType or "Base.RippedSheets")
    wound.bandageName = tostring(options.bandageName or wound.bandageType)
    wound.bandageDirty = false
    wound.bandageAppliedWorldHour = currentHour
    wound.lastHealWorldHour = currentHour
    wound.dirtyAtWorldHour = currentHour + math.max(0.25,
        tonumber(options.dirtyAfterWorldHours) or tonumber(Const.BANDAGE_DIRTY_AFTER_WORLD_HOURS) or 8)
    wound.firstAidLevel = Core.Clamp(math.floor(tonumber(options.firstAidLevel) or 0), 0, 10)
    wound.healRatePerWorldHour = ((tonumber(Const.BANDAGE_HEAL_PER_WORLD_HOUR) or 1.5)
        + wound.firstAidLevel * (tonumber(Const.BANDAGE_FIRST_AID_HEAL_BONUS) or 0.25))
        * Internal.GetBandageQuality(wound.bandageType)
    if wound.bandageType == "Base.AlcoholBandage" or wound.bandageType == "Base.AlcoholRippedSheets" then
        wound.alcoholLevel = math.min(5, (tonumber(wound.alcoholLevel) or 0) + 1.5)
    end
    wound.bandageInitialDamage = math.max(0, tonumber(wound.damage) or tonumber(wound.severity) or 0)
    wound.bandageHealedPoints = 0
    wound.healAtWorldHour = 0
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "bandaged", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "bandaged"
end

function Wounds.Stitch(record, partId, now, options)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound then return false, "wound_missing" end
    if wound.stitched == true then return false, "already_stitched" end
    options = type(options) == "table" and options or {}
    wound.stitched = true
    wound.stitchedAt = tonumber(now) or Core.Now()
    wound.bleedingRate = 0
    if options.removeGlass ~= false then
        wound.haveGlass = false
        if wound.type == "deep_wound_glass" then wound.type = "deep_wound" end
    end
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "stitched", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "stitched"
end

function Wounds.Splint(record, partId, now, options)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound then return false, "wound_missing" end
    if wound.splinted == true then return false, "already_splinted" end
    options = type(options) == "table" and options or {}
    wound.splinted = true
    wound.splintedAt = tonumber(now) or Core.Now()
    wound.splintFactor = math.max(1, tonumber(options.splintFactor) or 2)
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "splinted", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "splinted"
end

function Wounds.DebugAlmostDirty(record, partId)
    if not record or record.alive == false then return false, "invalid_target" end
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound then return false, "wound_missing" end
    if wound.bandaged ~= true then return false, "not_bandaged" end
    if wound.bandageDirty == true then return false, "already_dirty" end
    local currentHour = Internal.WorldHour()
    wound.dirtyAtWorldHour = currentHour + math.max(0.001, tonumber(Const.DEBUG_BANDAGE_ALMOST_DIRTY_WORLD_HOURS) or 0.02)
    wound.lastHealWorldHour = math.min(tonumber(wound.lastHealWorldHour) or currentHour, currentHour)
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "debug_bandage_almost_dirty"
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "bandage_almost_dirty"
end

function Wounds.BandageAll(record, now, options)
    local body = Wounds.Ensure(record)
    local changed = false
    now = tonumber(now) or Core.Now()
    for partId, wound in pairs(body.wounds) do
        if (wound.bandaged ~= true or wound.bandageDirty == true)
            and Wounds.Bandage(record, partId, now, options)
        then
            changed = true
        end
    end
    Wounds.Recalculate(record)
    return changed
end

return Wounds
