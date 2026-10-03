local Player = PNC.AnimationDebugPlayer
local Internal = Player.Internal or {}
local Equipment = Internal.Equipment
local readValue = Internal.readValue

local function itemFullType(item)
    local value = readValue(item, "getFullType")
    return value and tostring(value) or nil
end

local function isRangedWeapon(item)
    local value
    if not item then return false end
    value = readValue(item, "isRanged")
    if value ~= nil then return value == true end
    value = readValue(item, "getSubCategory")
    return tostring(value or "") == "Firearm"
end

local function findRangedInventoryItem(body)
    local inventory = readValue(body, "getInventory")
    local items = inventory and readValue(inventory, "getItems") or nil
    local count = tonumber(items and readValue(items, "size")) or 0
    local item
    for index = 0, count - 1 do
        item = readValue(items, "get", index)
        if isRangedWeapon(item) then return item end
    end
    return nil
end

local function primaryTypeForItem(item)
    local equipment = PNC.Equipment
    local internal = equipment and equipment.Internal or nil
    local primaryType
    if internal and internal.resolvePrimaryType then
        primaryType = readValue(internal, "resolvePrimaryType", item)
        if primaryType == "handgun" or primaryType == "rifle" then
            return primaryType
        end
    end
    if string.find(string.lower(itemFullType(item) or ""), "pistol", 1, true)
        or string.find(string.lower(itemFullType(item) or ""), "revolver", 1, true)
    then
        return "handgun"
    end
    return "rifle"
end

local function saveEquipmentVariable(active, name)
    local body = active.body
    if not body or not body.getVariableString then return end
    active.previousEquipmentVariables[name] = {
        value = readValue(body, "getVariableString", name),
    }
end

local function setEquipmentVariable(body, name, value)
    if body and body.SetVariable then
        body:SetVariable(name, tostring(value or ""))
    end
end

local function restoreEquipment(active)
    local body = active and active.body or nil
    local snapshot = active and active.equipmentSnapshot or nil
    if not body or not snapshot then return end
    if body.setPrimaryHandItem then
        body:setPrimaryHandItem(snapshot.primary)
    end
    if body.setSecondaryHandItem then
        body:setSecondaryHandItem(snapshot.secondary)
    end
    for name, previous in pairs(active.previousEquipmentVariables or {}) do
        if previous.value ~= nil then
            setEquipmentVariable(body, name, previous.value)
        elseif body.clearVariable then
            body:clearVariable(name)
        end
    end
    if body.resetEquippedHandsModels then
        body:resetEquippedHandsModels()
    end
    active.equipmentSnapshot = nil
    active.equipmentOverride = nil
end

local function applyRangedEquipment(active)
    local body = active and active.body or nil
    local item
    local equipment = PNC.Equipment
    local created = false
    local primaryType
    if not body or not body.setPrimaryHandItem then
        return false, "hand_setter_unavailable"
    end
    if active.equipmentSnapshot then return true, "already_forced" end

    item = findRangedInventoryItem(body)
    if not item and equipment and equipment.CreateItem then
        item = equipment.CreateItem("Base.DoubleBarrelShotgun")
        created = item ~= nil
    end
    if not item or not isRangedWeapon(item) then
        return false, "no_ranged_weapon_available"
    end
    active.equipmentSnapshot = {
        primary = readValue(body, "getPrimaryHandItem"),
        secondary = readValue(body, "getSecondaryHandItem"),
    }
    for _, name in ipairs({ "PNCPrimary", "PNCSecondary", "PNCPrimaryType" }) do
        saveEquipmentVariable(active, name)
    end
    primaryType = primaryTypeForItem(item)
    body:setPrimaryHandItem(item)
    if body:getPrimaryHandItem() ~= item then
        restoreEquipment(active)
        return false, "temporary_primary_equip_failed"
    end
    if body.setSecondaryHandItem then
        body:setSecondaryHandItem(nil)
    end
    setEquipmentVariable(body, "PNCPrimary", itemFullType(item))
    setEquipmentVariable(body, "PNCSecondary", "")
    setEquipmentVariable(body, "PNCPrimaryType", primaryType)
    if body.resetEquippedHandsModels then
        body:resetEquippedHandsModels()
    end
    active.equipmentOverride = {
        item = item,
        fullType = itemFullType(item),
        primaryType = primaryType,
        created = created,
    }
    return true, created and "temporary_created" or "temporary_inventory_item"
end

Equipment.restore = restoreEquipment
Equipment.applyRanged = applyRangedEquipment
