PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Internal.GetBodyLocationPriority()
    local i
    if Internal.BodyLocationPriority then
        return Internal.BodyLocationPriority
    end
    Internal.BodyLocationPriority = {}
    for i = 1, #Internal.BodyLocationsOrdered do
        Internal.BodyLocationPriority[Internal.BodyLocationsOrdered[i]] = i
    end
    return Internal.BodyLocationPriority
end

function Internal.GetAttachmentLocationToType()
    local map
    local _
    local def
    local attachmentType
    local location
    if Internal.AttachmentLocationToType then
        return Internal.AttachmentLocationToType
    end
    map = {}
    if ISHotbarAttachDefinition then
        for _, def in pairs(ISHotbarAttachDefinition) do
            if type(def) == "table" and def.attachments then
                for attachmentType, location in pairs(def.attachments) do
                    if attachmentType and location and not map[location] then
                        map[location] = def.type
                    end
                end
            end
        end
    end
    Internal.AttachmentLocationToType = map
    return Internal.AttachmentLocationToType
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

