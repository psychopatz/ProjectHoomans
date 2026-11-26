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

function Resources.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Resources.Detectors[id] then return false end
    Resources.Detectors[id] = nil
    Resources.Cache = {}
    return true
end

function Resources.GetDetector(id)
    return Resources.Detectors[tostring(id or "")]
end

function Resources.ListDetectors(filter)
    local keys = {}
    local output = {}
    filter = type(filter) == "table" and filter or nil
    for key, _ in pairs(Resources.Detectors) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    for index = 1, #keys do
        local detector = Resources.Detectors[keys[index]]
        if detector then
            local keep = true
            if filter then
                if filter.capability ~= nil
                    and tostring(detector.capability or "")
                        ~= tostring(filter.capability)
                then
                    keep = false
                end
                if keep and filter.resourceKind ~= nil
                    and tostring(detector.resourceKind or "")
                        ~= tostring(filter.resourceKind)
                then
                    keep = false
                end
            end
            if keep then output[#output + 1] = detector end
        end
    end
    return output
end

function Resources.ListByCapability(capability)
    return Resources.ListDetectors({ capability = capability })
end

-- Single-pass square inspection across all matching registered object
-- detectors. Callers (camp, settlement, roaming) share one normalization
-- boundary and automatically pick up newly registered object modules.
function Resources.InspectSquare(square, add, context, detectorIDs)
    if not square or type(add) ~= "function" then return 0 end
    local detectors = {}
    if type(detectorIDs) == "table" and #detectorIDs > 0 then
        for index = 1, #detectorIDs do
            local d = Resources.GetDetector(detectorIDs[index])
            if d then detectors[#detectors + 1] = d end
        end
    else
        detectors = Resources.ListDetectors()
    end
    if #detectors == 0 then return 0 end
    local descriptorKey = Resources.Internal and Resources.Internal.DescriptorKey
    local emittedCount = 0
    local function normalizeAndEmit(detector, object, ordinal)
        local okMatch, matched = pcall(detector.matches, square, object)
        if not okMatch or matched ~= true then return end
        local callCtx = type(context) == "table" and {
            record = context.record,
            character = context.character,
            zone = context.zone,
            objectIndex = ordinal,
        } or { objectIndex = ordinal }
        local okDesc, desc = pcall(detector.describe, square, object, callCtx)
        if not okDesc or type(desc) ~= "table" then return end
        desc.detectorId = desc.detectorId or detector.id
        desc.targetResolver = desc.targetResolver or detector.targetResolver
            or detector.id
        desc.resourceKind = desc.resourceKind or detector.resourceKind
        desc.capability = desc.capability or detector.capability
        desc.role = desc.role or detector.role
        if desc.sleepSurface == nil and detector.sleepSurface ~= nil then
            desc.sleepSurface = detector.sleepSurface
        end
        if desc.sleepPriority == nil and detector.sleepPriority ~= nil then
            desc.sleepPriority = detector.sleepPriority
        end
        if desc.exclusive == nil then
            desc.exclusive = detector.exclusive ~= false
        end
        if desc.available == nil then desc.available = true end
        if desc.originX == nil and square.getX then
            desc.originX = square:getX()
        end
        if desc.originY == nil and square.getY then
            desc.originY = square:getY()
        end
        if desc.originZ == nil and square.getZ then
            desc.originZ = square:getZ()
        end
        if not desc.resourceKey or desc.resourceKey == "" then
            if type(detector.key) == "function" then
                desc.resourceKey = tostring(detector.key(desc) or "")
            elseif type(descriptorKey) == "function" then
                desc.resourceKey = descriptorKey(detector, desc)
            end
        end
        add(desc)
        emittedCount = emittedCount + 1
    end

    local collectedByDetector = {}
    for dIdx = 1, #detectors do
        local detector = detectors[dIdx]
        if type(detector.collect) == "function" then
            local seenObj = {}
            collectedByDetector[dIdx] = seenObj
            pcall(detector.collect, square, function(object)
                if object and not seenObj[object] then
                    seenObj[object] = true
                    normalizeAndEmit(detector, object, 0)
                end
            end)
        end
    end

    local cachedObjects = type(context) == "table"
        and context.cachedSquareObjects or nil
    if type(cachedObjects) == "table" then
        for objIdx = 1, #cachedObjects do
            local object = cachedObjects[objIdx]
            for dIdx = 1, #detectors do
                local seenObj = collectedByDetector[dIdx]
                if not seenObj or not seenObj[object] then
                    normalizeAndEmit(detectors[dIdx], object, objIdx - 1)
                end
            end
        end
    else
        eachObject(square, function(object, ordinal)
            for dIdx = 1, #detectors do
                local seenObj = collectedByDetector[dIdx]
                if not seenObj or not seenObj[object] then
                    normalizeAndEmit(detectors[dIdx], object, ordinal)
                end
            end
        end)
    end
    return emittedCount
end

Resources.Internal = Resources.Internal or {}
Resources.Internal.EachObject = eachObject
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_Scan"
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_CapacitySelection"
require "PNC/Settlement/PNC_FacilityResources_Snapshot"
require "PNC/Settlement/PNC_FacilityResources_Detectors"
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_Seating"
require "PNC/Settlement/FacilityResources/PNC_FacilityResources_Faucet"
require "PNC/Settlement/PNC_FacilityResources_Activity"

return Resources
