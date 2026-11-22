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
    local runtime = type(record.runtime) == "table" and record.runtime or nil
    local equipment = record.equipment
    if runtime
        and runtime._normalizedEquipmentRef == equipment
        and type(equipment) == "table"
        and type(equipment.worn) == "table"
        and type(equipment.wornVisuals) == "table"
        and type(equipment.attached) == "table"
    then
        return equipment
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(equipment)
    if runtime then
        runtime._normalizedEquipmentRef = record.equipment
    end
    return record.equipment
end

local function refreshPortrait(record)
    if PNC.Network and PNC.Network.RefreshPortraitEquipment then
        PNC.Network.RefreshPortraitEquipment(record)
    end
end

function Equipment.SetLoadout(record, loadoutSpec)
    if not record then
        return false
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(loadoutSpec)
    if type(record.runtime) == "table" then
        record.runtime._normalizedEquipmentRef = record.equipment
    end
    refreshPortrait(record)
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
    refreshPortrait(record)
    return true
end

function Equipment.SetSecondary(record, fullType)
    local equipment
    if not record then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    equipment.secondaryFullType = Internal.NormalizeString(fullType)
    refreshPortrait(record)
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
    refreshPortrait(record)
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

