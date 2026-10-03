if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Shared state and engine-safe helpers for camp zone allocation.
PNC = PNC or {}
PNC.CampZoneService = PNC.CampZoneService or {}

local Service = PNC.CampZoneService
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local Internal = Service.Internal or {}
Service.Internal = Internal

Service.VERSION = 1
Service.MAX_ZONES = 32
Service.MAX_ROOM_CANDIDATES = 128
Service.MAX_ROOM_SQUARES = 1024
Service.MAX_DISCOVERY_RADIUS = 48
Service.MAX_RETAINED_CAMPS = 32
Service.Runtime = Service.Runtime or {}
Service.Runtime.camps = Service.Runtime.camps or {}
Service.Runtime.sequence = tonumber(Service.Runtime.sequence) or 0

local PROVIDER_ORDER = { "bed", "sofa", "faucet", "seat" }
local NEED_ORDER = { "sleep", "hydration", "hunger" }
local NEED_KIND = {
    sleep = "sleep",
    hydration = "water",
    hunger = "food",
}

local function number(value, fallback)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return fallback
end

local function text(value, fallback, maximum)
    if value == nil then return fallback end
    value = tostring(value)
    if maximum then value = string.sub(value, 1, maximum) end
    return value ~= "" and value or fallback
end

local function call(object, method, ...)
    local fn = object and object[method]
    local ok
    local value
    if type(fn) ~= "function" then return nil end
    ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function field(object, name)
    local ok
    local value
    if not object then return nil end
    ok, value = pcall(function() return object[name] end)
    return ok and value or nil
end

local function identifier(value)
    local result
    result = call(value, "getIDString") or call(value, "getID")
        or field(value, "id") or field(value, "ID")
    return text(result, nil, 128)
end

local function listSize(list)
    local size = number(call(list, "size"))
    if size ~= nil then return math.max(0, math.floor(size)) end
    if type(list) == "table" then return #list end
    return 0
end

local function listItem(list, index)
    local value = call(list, "get", index)
    if value ~= nil then return value end
    if type(list) == "table" then return list[index + 1] end
    return nil
end

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ"), 0)
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ, 0)
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function primitiveCopy(value, depth)
    local valueType = type(value)
    local output
    local child
    local copied
    if value == nil then return nil end
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or (depth or 0) >= 5 then return nil end
    output = {}
    for key, childValue in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            child = childValue
            copied = primitiveCopy(child, (depth or 0) + 1)
            if copied ~= nil then output[key] = copied end
        end
    end
    return output
end

local function copyBounds(bounds)
    if not bounds then return nil end
    if CampSite and CampSite.NormalizeBounds then
        return CampSite.NormalizeBounds(bounds)
    end
    return primitiveCopy(bounds)
end

local function copySite(site)
    local output = primitiveCopy(site) or {}
    output.kind = CampSite.KIND
    output.scope = CampSite.NormalizeScope(site and (
        site.scope or site.siteScope)) or CampSite.SCOPES.CAMPFIRE
    output.siteScope = output.scope
    output.siteID = text(site and site.siteID, nil, 128)
    output.roomID = text(site and site.roomID, nil, 128)
    output.buildingID = text(site and site.buildingID, nil, 128)
    output.roomType = text(site and site.roomType, nil, 48)
    output.roomName = text(site and site.roomName, nil, 64)
    output.roomBounds = copyBounds(site and site.roomBounds)
    output.campfireID = text(site and site.campfireID, nil, 128)
    output.x = number(site and site.x)
    output.y = number(site and site.y)
    output.z = number(site and site.z, 0)
    output.label = text(site and site.label, "room", 64)
    output.risk = text(site and site.risk, nil, 32)
    output.radius = number(site and site.radius, 3)
    output.resourceRadius = number(site and site.resourceRadius, 12)
    output.stopDistance = number(site and site.stopDistance, 0.7)
    return output
end

local function cellFor(options)
    if type(options) == "table" and options.cell then return options.cell end
    if type(getCell) == "function" then
        return getCell()
    end
    return nil
end

local function roomFor(square)
    local internal = Geometry and Geometry._Internal
    if internal and type(internal.RoomFor) == "function" then
        return internal.RoomFor(square)
    end
    return call(square, "getRoom") or call(square, "getIsoRoom")
end

local function roomBuilding(room)
    return call(room, "getBuilding") or field(room, "building")
end

local function roomSquares(room)
    local internal = Geometry and Geometry._Internal
    if internal and type(internal.Call) == "function" then
        return internal.Call(room, "getSquares")
            or field(room, "squares") or field(room, "tileList")
    end
    return call(room, "getSquares")
        or field(room, "squares") or field(room, "tileList")
end

local function siteDistanceSq(left, right)
    local dx = number(left and left.x, 0) - number(right and right.x, 0)
    local dy = number(left and left.y, 0) - number(right and right.y, 0)
    return dx * dx + dy * dy
end

local function zoneID(site)
    return text(site and site.siteID,
        "room:" .. tostring(site and site.roomID or "unknown"), 160)
end

local function providerIDs(resources)
    local output = {}
    local seen = {}
    local providers = resources and resources.Providers or {}
    local id
    local provider
    for index = 1, #PROVIDER_ORDER do
        id = PROVIDER_ORDER[index]
        provider = providers[id]
        if provider and type(provider.CaptureSquare) == "function" then
            output[#output + 1] = id
            seen[id] = true
        end
    end
    -- Future perception providers can participate without editing this
    -- allocator. Their capability mapping is intentionally separate below.
    for id, provider in pairs(providers) do
        if not seen[id] and provider
            and type(provider.CaptureSquare) == "function"
        then
            output[#output + 1] = tostring(id)
        end
    end
    table.sort(output)
    return output
end

Internal.CampSite = CampSite
Internal.Geometry = Geometry
Internal.PROVIDER_ORDER = PROVIDER_ORDER
Internal.NEED_ORDER = NEED_ORDER
Internal.NEED_KIND = NEED_KIND
Internal.number = number
Internal.text = text
Internal.call = call
Internal.field = field
Internal.identifier = identifier
Internal.listSize = listSize
Internal.listItem = listItem
Internal.position = position
Internal.primitiveCopy = primitiveCopy
Internal.copyBounds = copyBounds
Internal.copySite = copySite
Internal.cellFor = cellFor
Internal.roomFor = roomFor
Internal.roomBuilding = roomBuilding
Internal.roomSquares = roomSquares
Internal.siteDistanceSq = siteDistanceSq
Internal.zoneID = zoneID
Internal.providerIDs = providerIDs

return Service
