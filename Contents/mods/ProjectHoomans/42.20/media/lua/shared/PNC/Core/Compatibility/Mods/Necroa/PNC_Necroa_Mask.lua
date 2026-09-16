-- Small, provider-owned mask vocabulary shared by the server exposure adapter
-- and the client-side Necroa speech adapter.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Necroa = PNC.Compatibility.Necroa or {}

local Policy = PNC.Compatibility.Necroa
local Mask = Policy.Mask or {}
Policy.Mask = Mask

local MASK_TYPE_HINTS = {
    "surgicalmask", "gasmask", "respirator", "balaclava",
    "bandana", "dustmask", "facemask", "mask",
}

local function itemType(item)
    if type(item) == "string" then return item end
    if not item then return nil end
    if item.getFullType then
        local ok, value = pcall(item.getFullType, item)
        if ok and value and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    if item.getType then
        local ok, value = pcall(item.getType, item)
        if ok and value and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    return nil
end

local function hasKnownTag(item)
    if not item or type(item.hasTag) ~= "function" or not ItemTag then
        return false
    end
    local names = {
        "GAS_MASK", "RESPIRATOR", "IMPROVISED_GAS_MASK", "SCBA",
        "HAZMAT_SUIT",
    }
    local index
    for index = 1, #names do
        local tag = ItemTag[names[index]]
        if tag then
            local ok, result = pcall(item.hasTag, item, tag)
            if ok and result == true then return true end
        end
    end
    return false
end

function Mask.IsMaskItem(item)
    local fullType = string.lower(itemType(item) or "")
    local index
    if hasKnownTag(item) then return true end
    for index = 1, #MASK_TYPE_HINTS do
        if string.find(fullType, MASK_TYPE_HINTS[index], 1, true) then
            return true
        end
    end
    return false
end

local function wornItem(entry)
    if not entry then return nil end
    if entry.getItem then
        local ok, item = pcall(entry.getItem, entry)
        if ok then return item end
    end
    return entry
end

function Mask.HasMask(body)
    local worn
    local index
    local entry
    if not body then return false end
    if body.getWornItems then
        local ok, value = pcall(body.getWornItems, body)
        if ok then worn = value end
    end
    if worn and worn.size and worn.get then
        for index = 0, worn:size() - 1 do
            entry = wornItem(worn:get(index))
            if Mask.IsMaskItem(entry) then return true end
        end
    end
    return false
end

function Mask.HasRecordMask(record)
    local equipment = record and record.equipment or nil
    local inventory = record and record.inventory or nil
    local slot
    local fullType
    if equipment and type(equipment.worn) == "table" then
        for slot, fullType in pairs(equipment.worn) do
            if Mask.IsMaskItem(fullType) then return true end
        end
    end
    if inventory and type(inventory.worn) == "table"
        and type(inventory.items) == "table"
    then
        for slot, fullType in pairs(inventory.worn) do
            local item = inventory.items[fullType]
            if Mask.IsMaskItem(item and item.type or fullType) then
                return true
            end
        end
    end
    return false
end

Mask.DEFAULT_FULL_TYPE = "Base.Hat_SurgicalMask"
Mask.DEFAULT_BODY_LOCATION = "Mask"

function Mask.EnsureDefault(record)
    local equipment
    if not record or Mask.HasRecordMask(record) then
        return false, "mask_already_present"
    end
    equipment = PNC.Equipment
        and PNC.Equipment.EnsureRecordEquipment
        and PNC.Equipment.EnsureRecordEquipment(record)
    if not equipment or not PNC.Equipment.SetWorn then
        return false, "equipment_unavailable"
    end
    PNC.Equipment.SetWorn(
        record,
        Mask.DEFAULT_BODY_LOCATION,
        Mask.DEFAULT_FULL_TYPE
    )
    if PNC.Inventory and PNC.Inventory.SyncFromEquipment then
        PNC.Inventory.SyncFromEquipment(record, "necroa_default_mask")
    end
    return true, "default_mask_equipped"
end

return Mask
