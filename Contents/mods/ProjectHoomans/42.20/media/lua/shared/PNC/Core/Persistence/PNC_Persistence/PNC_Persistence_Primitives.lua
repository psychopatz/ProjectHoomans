PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}
local Internal = PNC.Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
Internal.normalizeString = Codec.normalizeString
Internal.normalizeNumber = Codec.normalizeNumber
Internal.hasTableEntries = Codec.hasTableEntries
Internal.copyStringMap = Codec.copyStringMap
Internal.copyPoints = Codec.copyPoints

function Internal.sanitizeOrderSpec(orderSpec, record)
    local spec = type(orderSpec) == "table" and Core.DeepCopy(orderSpec) or nil
    if not spec then
        return nil
    end
    if spec.points then
        spec.points = Internal.copyPoints(spec.points, record.anchorX, record.anchorY, record.anchorZ)
    end
    if spec.x ~= nil then
        spec.x = Internal.normalizeNumber(spec.x, record.anchorX)
    end
    if spec.y ~= nil then
        spec.y = Internal.normalizeNumber(spec.y, record.anchorY)
    end
    if spec.z ~= nil then
        spec.z = Internal.normalizeNumber(spec.z, record.anchorZ)
    end
    if spec.radius ~= nil then
        spec.radius = math.max(0.5, Internal.normalizeNumber(spec.radius, Const.ROAM_DEFAULT_RADIUS))
    end
    if spec.targetRadius ~= nil then
        spec.targetRadius = math.max(1, Internal.normalizeNumber(spec.targetRadius, Const.ROAM_TARGET_RADIUS))
    end
    if spec.reachedDistance ~= nil then
        spec.reachedDistance = math.max(0.1, Internal.normalizeNumber(spec.reachedDistance, Const.ROAM_REACHED_DISTANCE))
    end
    if spec.pauseMinMs ~= nil then
        spec.pauseMinMs = math.max(0, Internal.normalizeNumber(spec.pauseMinMs, Const.ROAM_PAUSE_MIN_MS))
    end
    if spec.pauseMaxMs ~= nil then
        local minimum = tonumber(spec.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS
        spec.pauseMaxMs = math.max(minimum, Internal.normalizeNumber(spec.pauseMaxMs, Const.ROAM_PAUSE_MAX_MS))
    end
    spec.roamMode = Internal.normalizeString(spec.roamMode)
    spec.moveMode = Internal.normalizeString(spec.moveMode)
    spec.ownerUsername = Internal.normalizeString(spec.ownerUsername)
    spec.ownerCharacterUUID = Internal.normalizeString(
        spec.ownerCharacterUUID
    )
    -- Online IDs are session-scoped; the character UUID is the durable owner.
    spec.ownerOnlineID = nil
    spec.journeyId = Internal.normalizeString(spec.journeyId)
    return spec
end

-- Camp resources are intentionally persisted as a small whitelist of scalar
-- descriptors. World objects, squares, Java userdata, and provider-specific
-- runtime values must be rediscovered or revalidated after load.
function Internal.sanitizeCampState(raw, record)
    if type(raw) ~= "table" then return nil end
    local rawResources = type(raw.resources) == "table"
        and raw.resources or {}
    local function optionalNumber(value)
        return tonumber(value)
    end
    local rawBounds = type(raw.roomBounds) == "table"
        and raw.roomBounds or nil
    local roomBounds = rawBounds and {
        minX = optionalNumber(rawBounds.minX),
        minY = optionalNumber(rawBounds.minY),
        maxX = optionalNumber(rawBounds.maxX),
        maxY = optionalNumber(rawBounds.maxY),
        z = optionalNumber(rawBounds.z),
    } or nil
    if roomBounds and (roomBounds.minX == nil or roomBounds.minY == nil
        or roomBounds.maxX == nil or roomBounds.maxY == nil)
    then
        roomBounds = nil
    end
    local output = {
        schemaVersion = math.max(1, math.floor(
            Internal.normalizeNumber(raw.schemaVersion, 1))),
        campId = Internal.normalizeString(raw.campId),
        anchorX = Internal.normalizeNumber(raw.anchorX,
            record and record.anchorX or 0),
        anchorY = Internal.normalizeNumber(raw.anchorY,
            record and record.anchorY or 0),
        anchorZ = Internal.normalizeNumber(raw.anchorZ,
            record and record.anchorZ or 0),
        campRadius = math.max(0.5, math.min(24, Internal.normalizeNumber(
            raw.campRadius, Const.CAMP_RADIUS or 3))),
        resourceRadius = math.max(1, math.min(24, Internal.normalizeNumber(
            raw.resourceRadius, Const.CAMP_RESOURCE_RADIUS or 12))),
        scope = Internal.normalizeString(raw.scope or raw.siteScope),
        siteScope = Internal.normalizeString(raw.siteScope or raw.scope),
        siteID = Internal.normalizeString(raw.siteID),
        roomID = Internal.normalizeString(raw.roomID),
        buildingID = Internal.normalizeString(raw.buildingID),
        roomType = Internal.normalizeString(raw.roomType),
        roomName = Internal.normalizeString(raw.roomName),
        roomBounds = roomBounds,
        campfireID = Internal.normalizeString(raw.campfireID),
        scanTruncated = raw.scanTruncated == true,
        capturedAtWorldHour = Internal.normalizeNumber(
            raw.capturedAtWorldHour, 0),
        resources = {},
    }
    local allowed = {
        "kind", "detectorId", "targetResolver", "resourceKind", "role",
        "capability", "resourceKey", "key", "x", "y", "z", "originX",
        "originY", "originZ", "axis", "facing", "surfaceOffset", "sprite",
        "sceneId", "sleepSurface", "exclusive", "available", "readOnly",
        "seatSpots",
    }
    local spotAllowed = {
        "x", "y", "z", "seatAnchorX", "seatAnchorY", "seatAnchorZ",
        "direction", "side", "approachKey", "valid", "approachValid",
        "validationState", "rejectionReason", "routeStatus",
    }
    local maximum = math.max(1, math.floor(
        tonumber(Const.CAMP_RESOURCE_MAX) or 32))
    local spotMaximum = math.max(1, math.floor(
        tonumber(Const.CAMP_RESOURCE_SPOT_MAX) or 8))
    for index = 1, math.min(maximum, #rawResources) do
        local source = rawResources[index]
        if type(source) == "table" then
            local resource = {}
            for keyIndex = 1, #allowed do
                local key = allowed[keyIndex]
                local value = source[key]
                local valueType = type(value)
                if valueType == "number" or valueType == "string"
                    or valueType == "boolean"
                then
                    resource[key] = value
                end
            end
            if type(source.seatSpots) == "table" then
                resource.seatSpots = {}
                for spotIndex = 1, math.min(spotMaximum, #source.seatSpots) do
                    local sourceSpot = source.seatSpots[spotIndex]
                    if type(sourceSpot) == "table" then
                        local spot = {}
                        local copiedValues = 0
                        for spotKeyIndex = 1, #spotAllowed do
                            local spotKey = spotAllowed[spotKeyIndex]
                            local value = sourceSpot[spotKey]
                            local valueType = type(value)
                            if valueType == "number"
                                or valueType == "string"
                                or valueType == "boolean"
                            then
                                spot[spotKey] = value
                                copiedValues = copiedValues + 1
                            end
                        end
                        if copiedValues > 0 then
                            resource.seatSpots[#resource.seatSpots + 1] = spot
                        end
                    end
                end
                if #resource.seatSpots == 0 then
                    resource.seatSpots = nil
                end
            end
            resource.resourceKey = Internal.normalizeString(
                resource.resourceKey or resource.key)
            if resource.resourceKey then
                output.resources[#output.resources + 1] = resource
            end
        end
    end
    return output
end

function Internal.serializePatrolPoints(record)
    local points = record and record.patrolPoints or nil
    local orderKind = record and record.orderSpec
        and tostring(record.orderSpec.kind or "") or ""
    if orderKind ~= tostring(Const.ORDER_PATROL or "patrol")
        and (type(points) ~= "table" or #points <= 1)
    then
        return nil
    end
    return Internal.copyPoints(points, record.anchorX, record.anchorY, record.anchorZ)
end
