PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Equipment.CaptureCharacterLoadout(character)
    local loadout = Equipment.NormalizeLoadoutSpec(nil)
    local primary
    local secondary
    local wornItems
    local attachedItems
    local i
    local entry
    local item
    local location

    if not character then
        return nil, "missing_character"
    end

    primary = character.getPrimaryHandItem and character:getPrimaryHandItem() or nil
    if primary and primary.getFullType then
        loadout.primaryFullType = Internal.NormalizeString(primary:getFullType())
    end

    secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if secondary and secondary ~= primary and secondary.getFullType then
        loadout.secondaryFullType = Internal.NormalizeString(secondary:getFullType())
    end

    wornItems = character.getWornItems and character:getWornItems() or nil
    if wornItems and wornItems.size then
        for i = 0, wornItems:size() - 1 do
            entry = wornItems:get(i)
            item = entry and entry.getItem and entry:getItem() or nil
            location = entry and entry.getLocation and entry:getLocation() or nil
            if not location and item and item.getBodyLocation then
                location = item:getBodyLocation()
            end
            if item and item.getFullType and location and location ~= "" then
                loadout.worn[tostring(location)] = tostring(item:getFullType())
            end
        end
    end

    attachedItems = character.getAttachedItems and character:getAttachedItems() or nil
    if attachedItems and attachedItems.size then
        for i = 0, attachedItems:size() - 1 do
            entry = attachedItems:get(i)
            item = entry and entry.getItem and entry:getItem() or nil
            location = entry and entry.getLocation and entry:getLocation() or nil
            if item and item.getFullType and location and location ~= "" then
                loadout.attached[tostring(location)] = tostring(item:getFullType())
            end
        end
    end

    return Equipment.NormalizeLoadoutSpec(loadout), "captured"
end

function Equipment.CopyCharacterLoadout(record, character)
    local loadout
    local reason
    if not record then
        return false, "missing_record"
    end
    loadout, reason = Equipment.CaptureCharacterLoadout(character)
    if not loadout then
        return false, reason or "capture_failed"
    end
    record.equipment = loadout
    return true, reason or "captured"
end