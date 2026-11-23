PNC = PNC or {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Treatment_Surgical"

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const
local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"
Wounds.GetBandageReturnType = Dressing.ReturnType

local function isTreatable(wound)
    if not wound or wound.dressingHealed then return false end
    if wound.bandageDirty == true then return true end
    if wound.type == "fracture" and wound.splinted == true then return false end
    return wound.bandaged ~= true
end

function Wounds.FindRemovableHealedDressing(record)
    local body = Wounds.Ensure(record)
    for i = 1, #Wounds.PartOrder do
        local partId = Wounds.PartOrder[i]
        local wound = body.wounds[partId]
        if wound and wound.dressingHealed == true then
            if wound.bandaged == true then return partId, wound, "bandage" end
            if wound.splinted == true then return partId, wound, "splint" end
        end
    end
    return nil
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
    if not wound or wound.dressingHealed then return false, "wound_missing" end
    if wound.bandaged == true and wound.bandageDirty ~= true then return false, "already_bandaged" end
    now = tonumber(now) or Core.Now()
    local currentHour = Internal.WorldHour()
    local dressingType = tostring(options.bandageType or "Base.RippedSheets")
    local profile = Dressing.Profile(dressingType, options.nativeItem)
    if not profile then return false, "invalid_bandage_type" end
    local oldDressing = Dressing.ReturnType(wound)
    wound.bandaged = true
    wound.bandagedAt = tonumber(now) or Core.Now()
    wound.bandageType = dressingType
    wound.bandageName = options.bandageName
    wound.spentBandageType = profile.spentType
    wound.virtualDressing = options.virtualDressing == true or dressingType == "PNC.AbstractMedical"
    wound.sterileDressing = profile.sterile
    wound.bandageDirty = profile.dirty
    if options.nativeItem and options.nativeItem.isInfected and options.nativeItem:isInfected() then
        wound.infectedWound = true
        wound.woundInfectionLevel = math.max(0.5, tonumber(wound.woundInfectionLevel) or 0)
    end
    wound.bandageAppliedWorldHour = currentHour
    wound.lastHealWorldHour = currentHour
    wound.firstAidLevel = Core.Clamp(math.floor(tonumber(options.firstAidLevel) or 0), 0, 10)
    wound.bandageLife = Dressing.Life(profile, wound.firstAidLevel)
    -- NPC world-hour integration uses the installed item's native life budget.
    local hours = tonumber(options.dirtyAfterWorldHours) or Dressing.WorldHours(wound.bandageLife, wound,
        tonumber(Const.BANDAGE_DIRTY_AFTER_WORLD_HOURS) or 8)
    wound.dirtyAtWorldHour = hours and currentHour + hours or nil
    wound.dressingLifeTracked = true
    wound.healRatePerWorldHour = tonumber(Const.BANDAGE_HEAL_PER_WORLD_HOUR) or 1.5
    wound.bandageInitialDamage = math.max(0, tonumber(wound.damage) or tonumber(wound.severity) or 0)
    wound.bandageHealedPoints = 0
    wound.healAtWorldHour = 0
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "bandaged", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "bandaged", oldDressing
end

function Wounds.RemoveBandage(record, partId)
    if not record or record.alive == false then return false, "invalid_target" end
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound or wound.bandaged ~= true then return false, "not_bandaged" end
    local recovered = Dressing.ReturnType(wound)
    wound.bandaged, wound.bandageDirty = false, false
    wound.bandageType, wound.bandageName, wound.spentBandageType = nil, nil, nil
    wound.virtualDressing, wound.sterileDressing, wound.dressingLifeTracked = nil, nil, nil
    wound.bandageLife, wound.dirtyAtWorldHour = nil, nil
    if wound.dressingHealed and not wound.splinted then body.wounds[tostring(partId)] = nil end
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "bandage_removed", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "bandage_removed", recovered
end

function Wounds.Stitch(record, partId, now, options)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound or wound.dressingHealed then return false, "wound_missing" end
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
    if not wound or wound.dressingHealed or (wound.type ~= "fracture" and wound.fractured ~= true) then
        return false, "fracture_missing"
    end
    if partId == "Head" or partId == "Torso_Upper" or partId == "Torso_Lower" then
        return false, "splint_part_invalid"
    end
    if wound.splinted == true then return false, "already_splinted" end
    options = type(options) == "table" and options or {}
    wound.splinted = true
    wound.splintedAt = tonumber(now) or Core.Now()
    wound.splintFactor = math.max(0.5, tonumber(options.splintFactor)
        or (Core.Clamp(tonumber(options.firstAidLevel) or 0, 0, 10) + 1) / 2)
    wound.lastFractureHealHour = Internal.WorldHour()
    wound.splintItem = options.splintItem
    wound.splintType = options.splintType
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "splinted", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "splinted"
end

function Wounds.RemoveSplint(record, partId)
    if not record or record.alive == false then return false, "invalid_target" end
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound or wound.splinted ~= true then return false, "not_splinted" end
    local support = wound.splintItem
    local fabric = Dressing.IsSplintSupport(support) and "Base.RippedSheets" or nil
    wound.splinted, wound.splintFactor, wound.splintItem, wound.splintType = false, nil, nil, nil
    if wound.dressingHealed and not wound.bandaged then body.wounds[tostring(partId)] = nil end
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "splint_removed", true) end
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "splint_removed", support, fabric
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
