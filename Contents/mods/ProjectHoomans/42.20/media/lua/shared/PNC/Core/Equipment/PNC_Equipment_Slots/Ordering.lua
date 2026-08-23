PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Equipment.GetOrderedWornEntries(equipment)
    local entries = {}
    local priority = Internal.GetBodyLocationPriority()
    local bodyLocation
    local fullType
    equipment = Equipment.NormalizeLoadoutSpec(equipment)
    for bodyLocation, fullType in pairs(equipment.worn) do
        entries[#entries + 1] = {
            bodyLocation = bodyLocation,
            fullType = fullType,
            priority = priority[bodyLocation] or 999,
        }
    end
    table.sort(entries, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return tostring(left.bodyLocation) < tostring(right.bodyLocation)
    end)
    return entries
end

function Equipment.GetOrderedAttachedEntries(equipment)
    local entries = {}
    local location
    local fullType
    equipment = Equipment.NormalizeLoadoutSpec(equipment)
    for location, fullType in pairs(equipment.attached) do
        entries[#entries + 1] = {
            location = location,
            fullType = fullType,
            slotType = Equipment.ResolveAttachedSlotType(location),
        }
    end
    table.sort(entries, function(left, right)
        return tostring(left.location) < tostring(right.location)
    end)
    return entries
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

