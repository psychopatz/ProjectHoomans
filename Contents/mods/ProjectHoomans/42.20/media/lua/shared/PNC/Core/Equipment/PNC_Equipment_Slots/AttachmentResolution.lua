PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Equipment.ResolveAttachedSlotType(location)
    if not location or location == "" then
        return nil
    end
    return Internal.GetAttachmentLocationToType()[tostring(location)]
end

function Equipment.ResolveAttachedLocation(item, preferredSlotType, occupiedLocations)
    local attachmentType
    local preferredLookup = {}
    local entries = {}
    local i
    local _
    local def
    local location
    local preferredTypes

    if not item or not item.getAttachmentType or not ISHotbarAttachDefinition then
        return nil, nil
    end

    attachmentType = item:getAttachmentType()
    if not attachmentType or attachmentType == "" then
        return nil, nil
    end

    preferredTypes = Internal.AttachmentTypeSlotPriority[attachmentType] or {}
    for i = 1, #preferredTypes do
        preferredLookup[preferredTypes[i]] = i
    end
    if preferredSlotType and not preferredLookup[preferredSlotType] then
        preferredLookup[preferredSlotType] = 0
    end

    for _, def in pairs(ISHotbarAttachDefinition) do
        if type(def) == "table" and Internal.ManagedAttachmentTypes[def.type] and def.attachments then
            location = def.attachments[attachmentType]
            if location and location ~= "" and not (occupiedLocations and occupiedLocations[location]) then
                entries[#entries + 1] = {
                    location = location,
                    slotType = def.type,
                    preferred = preferredLookup[def.type] or 999,
                    fallback = Internal.ManagedSlotTypePriority[def.type] or 999,
                }
            end
        end
    end

    table.sort(entries, function(left, right)
        if left.preferred ~= right.preferred then
            return left.preferred < right.preferred
        end
        if left.fallback ~= right.fallback then
            return left.fallback < right.fallback
        end
        return tostring(left.location) < tostring(right.location)
    end)

    if entries[1] then
        return entries[1].location, entries[1].slotType
    end
    return nil, nil
end

function Equipment.SetAttachedByItem(record, fullType, preferredSlotType)
    local item
    local createReason
    local location
    if not record then
        return false, "missing_record"
    end
    item, createReason = Equipment.CreateItem(fullType)
    if not item then
        return false, createReason or "invalid_full_type"
    end
    location = Equipment.ResolveAttachedLocation(item, preferredSlotType)
    if not location then
        return false, "no_attachment_location"
    end
    Equipment.SetAttached(record, location, fullType)
    return true, location
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

