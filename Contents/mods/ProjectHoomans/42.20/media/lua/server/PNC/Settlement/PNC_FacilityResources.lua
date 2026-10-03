-- Generic world-resource discovery for zone-backed facilities.
--
-- Facilities own regions; detectors describe the world objects found inside
-- those regions. The resulting descriptors are runtime resources, not
-- persisted editable facility components. This keeps furniture discovery
-- reusable for beds, chairs, tables, and future faction-owned facilities.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources

Resources.Detectors = Resources.Detectors or {}
Resources.Cache = Resources.Cache or {}
Resources.SCAN_TTL_MS = Resources.SCAN_TTL_MS or 5000
Resources.MAX_CAPACITY = Resources.MAX_CAPACITY or 999

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function copyPrimitive(value)
    local valueType = type(value)
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" then return nil end
    local output = {}
    for key, child in pairs(value) do
        local copied = copyPrimitive(child)
        if copied ~= nil then output[key] = copied end
    end
    return output
end

local function copyDescriptor(resource)
    local output = {}
    for key, value in pairs(resource or {}) do
        -- Java object references are valid for the live server cache but must
        -- never cross the snapshot/save boundary. Primitive nested metadata,
        -- such as SeatingManager's valid approach spots, is retained.
        if key ~= "object" then
            local copied = copyPrimitive(value)
            if copied ~= nil then output[key] = copied end
        end
    end
    return output
end

-- Runtime callers may keep the descriptor on an activity or reservation.
-- Expose the same boundary used by settlement snapshots so Java world objects
-- never become part of persisted/debuggable runtime state.
Resources.CopyDescriptor = copyDescriptor

function Resources.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.matches) ~= "function"
        or type(definition.describe) ~= "function"
    then
        return false, "INVALID_RESOURCE_DETECTOR"
    end
    definition.id = id
    Resources.Detectors[id] = definition
    Resources.Cache = {}
    return true, definition
end

function Resources.GetDetector(id)
    return Resources.Detectors[tostring(id or "")]
end

Resources.Internal = Resources.Internal or {}
Resources.Internal.EachObject = eachObject
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_Scan"
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_CapacitySelection"
require "PNC/Settlement/PNC_FacilityResources_Snapshot"
require "PNC/Settlement/PNC_FacilityResources_Detectors"
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_Seating"
require "PNC/Settlement/PNC_FacilityResources_Activity"

return Resources
