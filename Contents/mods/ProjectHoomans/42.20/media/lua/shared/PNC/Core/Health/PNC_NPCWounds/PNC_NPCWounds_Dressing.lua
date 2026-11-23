-- Build 42 dressing parameters for authoritative NPC wounds.
local Dressing = {}
local fallback = {
    ["PNC.AbstractMedical"] = { 2 },
    ["Base.BandageDirty"] = { 0.5 },
    ["Base.RippedSheetsDirty"] = { 0.5 },
    ["Base.DenimStripsDirty"] = { 0.5 },
    ["Base.LeatherStripsDirty"] = { 0.5 },
    ["Base.RippedSheets"] = { 2, "Base.RippedSheetsDirty" },
    ["Base.AlcoholRippedSheets"] = { 2, "Base.RippedSheetsDirty", true },
    ["Base.Bandage"] = { 4, "Base.BandageDirty" },
    ["Base.AlcoholBandage"] = { 4, "Base.BandageDirty", true },
    ["Base.DenimStrips"] = { 2, "Base.DenimStripsDirty" },
    ["Base.LeatherStrips"] = { 2, "Base.LeatherStripsDirty" },
    ["Base.Bandaid"] = { 1.5 },
}
local SPLINT_SUPPORT = {
    ["Base.Plank"] = true, ["Base.TreeBranch2"] = true, ["Base.WoodenStick2"] = true,
    ["Base.TreeBranch"] = true, ["Base.WoodenStick"] = true,
}

function Dressing.IsSplintSupport(fullType)
    return SPLINT_SUPPORT[fullType] == true
end

local cache = {}

function Dressing.Profile(fullType, nativeItem)
    if type(fullType) ~= "string" or fullType == "" then return nil end
    if not nativeItem and cache[fullType] then return cache[fullType] end
    local known = fallback[fullType]
    local item = nativeItem or (instanceItem and (not known or fullType ~= "PNC.AbstractMedical") and instanceItem(fullType))
    local script = item and item.getScriptItem and item:getScriptItem()
    local power = item and item.getBandagePower and tonumber(item:getBandagePower())
    if not known and (not power or power <= 0) then return nil end
    local replacement = item and item.getReplaceOnUseFullType and item:getReplaceOnUseFullType()
        or (script and script.getReplaceOnUse and script:getReplaceOnUse())
    local sterile = known and known[3] == true or false
    if item and item.isAlcoholic then sterile = item:isAlcoholic() == true end
    local dirty = string.find(fullType, "Dirty", 1, true) ~= nil
    local reusable = item and item.hasTag and ItemTag and ItemTag.REUSABLE_BANDAGE
        and item:hasTag(ItemTag.REUSABLE_BANDAGE) == true
    local profile = {
        power = power or known[1],
        spentType = dirty and fullType or (reusable and fullType or replacement) or (known and known[2]),
        sterile = sterile,
        dirty = dirty,
    }
    if not nativeItem then cache[fullType] = profile end
    return profile
end

function Dressing.Life(profile, firstAid)
    if profile.dirty then return 0 end
    local skill = (firstAid or 0) + 1
    local bonus = ZombRandFloat and ZombRandFloat(skill * 0.5, skill) or skill * 0.75
    return profile.power + bonus
end

function Dressing.NativeMultiplierPerWorldHour()
    local time = getGameTime and getGameTime()
    local minutes = time and time.getMinutesPerDay and tonumber(time:getMinutesPerDay())
    return minutes and minutes > 0 and minutes * 120 or nil
end

function Dressing.WorldHours(life, wound, fallbackHours)
    if life <= 0 then return 0 end
    local multiplier = Dressing.NativeMultiplierPerWorldHour()
    if not multiplier then return life * fallbackHours / 2.75 end
    local kind = wound.type
    local deep = wound.deepWounded == true or (kind and string.find(kind, "deep_wound", 1, true) ~= nil)
    local loss = 0
    if kind == "scratch" then loss = loss + 0.00008 end
    if kind == "laceration" then loss = loss + 0.00001 end
    if kind == "bite" or kind == "burn" or deep then loss = loss + 0.0001 end
    if wound.stitched then loss = loss + 0.0001 end
    if wound.infectedWound then loss = loss + 0.0002 end
    if (tonumber(wound.bleedingRate) or 0) > 0 then loss = loss + (deep and 0.005 or 0.0003) end
    if loss == 0 then return nil end
    return life / (loss * multiplier)
end

function Dressing.ReturnType(wound)
    if not wound or wound.bandaged ~= true or not wound.bandageType or wound.virtualDressing == true
        or wound.bandageType == "PNC.AbstractMedical" then return nil end
    if wound.bandageDirty ~= true then return wound.bandageType end
    if wound.spentBandageType then return wound.spentBandageType end
    local profile = Dressing.Profile(wound.bandageType)
    return profile and profile.spentType
end

return Dressing
