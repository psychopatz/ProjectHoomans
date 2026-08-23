PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Equipment.NormalizeLoadoutSpec(loadoutSpec)
    local source = type(loadoutSpec) == "table" and loadoutSpec or {}
    local worn = Internal.NormalizeWornMap(source.worn)
    local primaryFullType = Internal.NormalizeString(source.primaryFullType)
    return {
        primaryFullType = primaryFullType,
        primaryVisual = Internal.NormalizeVisualState(
            source.primaryVisual,
            primaryFullType
        ),
        secondaryFullType = Internal.NormalizeString(source.secondaryFullType),
        worn = worn,
        wornVisuals = Internal.NormalizeWornVisualMap(
            source.wornVisuals,
            worn
        ),
        attached = Internal.NormalizeStringMap(source.attached),
    }
end

function Equipment.EnsureRecordEquipment(record)
    if not record then
        return Equipment.NormalizeLoadoutSpec(nil)
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(record.equipment)
    return record.equipment
end

function Equipment.SetLoadout(record, loadoutSpec)
    if not record then
        return false
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(loadoutSpec)
    return true
end

function Equipment.SetPrimary(record, fullType)
    local equipment
    local previous
    if not record then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    previous = equipment.primaryFullType
    equipment.primaryFullType = Internal.NormalizeString(fullType)
    if tostring(previous or "")
        ~= tostring(equipment.primaryFullType or "")
    then
        equipment.primaryVisual = nil
    end
    return true
end

function Equipment.SetSecondary(record, fullType)
    local equipment
    if not record then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    equipment.secondaryFullType = Internal.NormalizeString(fullType)
    return true
end

local function setSlotValue(record, collectionName, location, fullType, normalizeLocation)
    local equipment
    local previous
    location = normalizeLocation(location)
    if not record or not location then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    previous = equipment[collectionName][location]
    fullType = Internal.NormalizeString(fullType)
    if fullType then
        equipment[collectionName][location] = fullType
    else
        equipment[collectionName][location] = nil
    end
    if collectionName == "worn"
        and tostring(previous or "") ~= tostring(fullType or "")
    then
        equipment.wornVisuals[location] = nil
    end
    return true
end

function Equipment.SetAttached(record, location, fullType)
    return setSlotValue(record, "attached", location, fullType, Internal.NormalizeString)
end

function Equipment.SetWorn(record, bodyLocation, fullType)
    return setSlotValue(record, "worn", bodyLocation, fullType, Internal.NormalizeBodyLocation)
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

