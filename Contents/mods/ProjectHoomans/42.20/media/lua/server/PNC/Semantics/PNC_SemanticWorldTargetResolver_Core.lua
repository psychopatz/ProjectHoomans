-- Resolve semantic world targets into bounded primitive assignments.
--
-- This boundary is deliberately read-only.  It may inspect the loaded world
-- while resolving a step, but it never stores Java objects in an action plan
-- and never performs the resulting gameplay action.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.WorldTargetResolver =
    PNC.Semantics.WorldTargetResolver or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Resolver = PNC.Semantics.WorldTargetResolver
local Locator = PNC.NearbyResourceLocator
local FacilityTargets = PNC.FacilityInteractionTargets
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"

Resolver.Providers = Resolver.Providers or {}
Resolver.Aliases = Resolver.Aliases or {}
Resolver.MAX_RADIUS = Resolver.MAX_RADIUS or 32
Resolver.DEFAULT_STOP_DISTANCE = Resolver.DEFAULT_STOP_DISTANCE or 0.9
Resolver.OBJECT_CACHE_MS = Resolver.OBJECT_CACHE_MS or 1000

local function number(value)
    return tonumber(value)
end

local function text(value)
    local result = tostring(value or "")
    return result ~= "" and result or nil
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function boundedRadius(value, fallback)
    return math.max(0, math.min(Resolver.MAX_RADIUS,
        math.floor(number(value) or fallback or 12)))
end

local function validClientHint(target, kind, origin, radius)
    local raw = target and target.clientHint
    local hintKind
    local x
    local y
    local z
    local originX
    local originY
    local originZ
    local maximum
    local dx
    local dy
    if type(raw) ~= "table" then return nil end
    hintKind = lower(raw.kind)
    hintKind = string.gsub(hintKind, "[%s%-]+", "_")
    if hintKind ~= "" and hintKind ~= lower(kind) then
        return nil, "client_hint_kind_mismatch"
    end
    if hintKind ~= ""
        and Catalog and type(Catalog.Get) == "function"
        and not Catalog.Get(hintKind)
    then
        return nil, "client_hint_kind_unknown"
    end
    if Catalog and type(Catalog.Normalize) == "function"
        and raw.query ~= nil
    then
        local requested = target and (target.text or target.value
            or target.category or target.concept or target.id) or ""
        local requestedKey = Catalog.Normalize(requested)
        local queryKey = Catalog.Normalize(raw.query)
        if requestedKey ~= "" and queryKey ~= ""
            and requestedKey ~= queryKey
        then
            return nil, "client_hint_query_mismatch"
        end
    end
    x = number(raw.x)
    y = number(raw.y)
    z = number(raw.z) or 0
    if x == nil or y == nil
        or math.abs(x) > 1000000 or math.abs(y) > 1000000
    then
        return nil, "client_hint_coordinates_invalid"
    end
    originX = number(call(origin, "getX"))
    originY = number(call(origin, "getY"))
    originZ = number(call(origin, "getZ")) or 0
    if originX == nil or originY == nil then
        return nil, "world_origin_unavailable"
    end
    maximum = math.max(4, math.min(Resolver.MAX_RADIUS,
        (number(radius) or 12) + 4))
    dx = x - number(originX)
    dy = y - number(originY)
    if dx * dx + dy * dy > maximum * maximum
        or math.abs(z - number(originZ)) > 1
    then
        return nil, "client_hint_out_of_range"
    end
    return {
        kind = hintKind,
        x = x,
        y = y,
        z = z,
        score = number(raw.score),
    }
end

local function nearClientHint(entry, hint, maximum)
    if not entry or not hint then return false end
    local x = number(entry.x)
    local y = number(entry.y)
    local z = number(entry.z) or 0
    if x == nil or y == nil then return false end
    local dx = x - hint.x
    local dy = y - hint.y
    maximum = number(maximum) or 2.5
    return dx * dx + dy * dy <= maximum * maximum
        and math.abs(z - hint.z) <= 1
end

local function hintKey(hint)
    if not hint then return "" end
    return tostring(math.floor(hint.x * 10)) .. ":"
        .. tostring(math.floor(hint.y * 10)) .. ":"
        .. tostring(math.floor(hint.z * 10))
end

Resolver.ValidateClientHint = validClientHint
Resolver.NearClientHint = nearClientHint
Resolver.ClientHintKey = hintKey

local function primitiveTarget(raw, fallbackKind)
    if type(raw) ~= "table" then return nil end
    local x = number(raw.x or raw.targetX)
    local y = number(raw.y or raw.targetY)
    local z = number(raw.z or raw.targetZ) or 0
    if x == nil or y == nil then return nil end
    return {
        kind = text(raw.kind) or fallbackKind or "world_point",
        targetID = text(raw.targetID or raw.id or raw.resourceKey
            or raw.key),
        x = x,
        y = y,
        z = z,
        mode = text(raw.mode) or "walk",
        stopDistance = math.max(0.25, number(raw.stopDistance)
            or Resolver.DEFAULT_STOP_DISTANCE),
        dynamic = raw.dynamic == true,
    }
end

local function abstractOrigin(record)
    if not record then return nil end
    if type(record.getX) == "function" then return record end
    local x = number(record.x)
    local y = number(record.y)
    local z = number(record.z) or 0
    if x == nil or y == nil then return nil end
    -- The locator only needs these read methods.  This adapter is created
    -- during a bounded resolve, never retained in the plan or cache.
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
    }
end

local function originFor(context)
    context = type(context) == "table" and context or {}
    return context.origin or context.body or abstractOrigin(context.record)
end

local function traceResolution(target, context, kind, result, reason)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local legacyTrace = trace
        and type(trace.IsEnabled) == "function"
        and trace.IsEnabled() == true
        and type(trace.Record) == "function"
    if not semanticAudit and not legacyTrace
    then
        return result, reason
    end
    context = type(context) == "table" and context or {}
    local record = context.record
    local origin = originFor(context)
    local definition = {
        source = "ProjectHoomans.Semantics",
        event = "semantic.world_target.resolve",
        requestID = context.requestID or context.planID,
        data = {
        npcID = record and (record.id or record.npcID),
        planID = context.planID,
        targetText = text(target and (target.text or target.value
            or target.category or target.concept or target.id)),
        requestedKind = text(target and target.kind),
        resolvedKind = text(kind or result and result.kind),
        status = result and "resolved" or "failed",
        reason = reason,
        radius = number(target and target.radius),
        originX = origin and call(origin, "getX") or nil,
        originY = origin and call(origin, "getY") or nil,
        originZ = origin and call(origin, "getZ") or nil,
        targetID = result and result.targetID,
        targetX = result and result.x,
        targetY = result and result.y,
        targetZ = result and result.z,
        },
    }
    if semanticAudit then
        Diagnostics.Record(
            "semantic.world_target.resolve",
            definition.data,
            { requestID = definition.requestID }
        )
    else
        trace.Record(definition)
    end
    return result, reason
end

local function objectName(object)
    return lower(call(object, "getObjectName")
        or call(object, "getName"))
end

local function globalCampfireForSquare(square)
    local campfire = call(square, "getCampfire")
    local x
    local y
    local z
    if not campfire then return nil end
    x = call(campfire, "getX") or call(square, "getX")
    y = call(campfire, "getY") or call(square, "getY")
    z = call(campfire, "getZ") or call(square, "getZ")
    if x == nil or y == nil then return nil end
    return {
        object = campfire,
        source = "global_campfire",
        key = CampSite.CampfireKey(x, y, z),
    }
end

local function listSize(list)
    local size = call(list, "size")
    if size ~= nil then return math.max(0, math.floor(number(size) or 0)) end
    if type(list) == "table" then return #list end
    return 0
end

local function listItem(list, index)
    local item = call(list, "get", index)
    if item ~= nil then return item end
    if type(list) == "table" then return list[index + 1] end
    return nil
end

local function campfireIDMatches(wanted, key, objectID)
    local wantedText = text(wanted)
    local keyText = text(key)
    local objectText = tostring(objectID or "")
    local coordinateKey = wantedText
        and string.match(wantedText, "^([^#]+)#") or nil
    local wantedCoordinate = CampSite.CampfireCoordinateKey(wantedText)
    local keyCoordinate = CampSite.CampfireCoordinateKey(keyText)
    if not wantedText then return true end
    return wantedText == keyText
        or wantedText == objectText
        or coordinateKey ~= nil and coordinateKey == keyText
        or wantedCoordinate ~= nil and wantedCoordinate == keyCoordinate
end

local function isCampfire(entry, requestedID)
    local object = entry and entry.object
    local key = text(entry and entry.key)
    local objectID = call(object, "getID")
    if not campfireIDMatches(requestedID, key, objectID) then
        return false
    end
    if entry and entry.source == "global_campfire" then return true end
    local campfire = call(object, "isCampfire")
    if campfire == true then return true end
    local container = call(object, "getContainer")
    if lower(call(container, "getType")) == "campfire" then return true end
    local name = objectName(object)
    return string.find(name, "campfire", 1, true) ~= nil
end

local function cellFor(context)
    if type(context) == "table" and context.cell then
        return context.cell
    end
    if type(getCell) == "function" then
        return getCell()
    end
    return nil
end

local function campfireEntryOnSquare(square, requestedID)
    local x = number(call(square, "getX"))
    local y = number(call(square, "getY"))
    local z = number(call(square, "getZ")) or 0
    local global = globalCampfireForSquare(square)
    local objects
    local index
    if x == nil or y == nil then return nil end
    if global and isCampfire(global, requestedID) then
        global.x = x + 0.5
        global.y = y + 0.5
        global.z = z
        return global
    end
    objects = call(square, "getObjects")
    for index = 0, listSize(objects) - 1 do
        local object = listItem(objects, index)
        local objectID = call(object, "getID")
        local key = objectID and "campfire@" .. tostring(x) .. ":"
            .. tostring(y) .. ":" .. tostring(z) .. "#"
            .. tostring(objectID)
            or "campfire@" .. tostring(x) .. ":" .. tostring(y) .. ":"
                .. tostring(z)
        local entry = {
            object = object,
            source = "square_object",
            key = key,
            x = x + 0.5,
            y = y + 0.5,
            z = z,
        }
        if isCampfire(entry, requestedID) then return entry end
    end
    return nil
end

-- Validate one client-observed campfire square without falling back to the
-- broad server locator. Direct player commands must remain cheap even when a
-- multiplayer server has many simultaneous command requests.


Resolver._Deps = {
    number = number,
    text = text,
    lower = lower,
    call = call,
    boundedRadius = boundedRadius,
    validClientHint = validClientHint,
    nearClientHint = nearClientHint,
    hintKey = hintKey,
    primitiveTarget = primitiveTarget,
    originFor = originFor,
    traceResolution = traceResolution,
    globalCampfireForSquare = globalCampfireForSquare,
    listSize = listSize,
    listItem = listItem,
    campfireIDMatches = campfireIDMatches,
    isCampfire = isCampfire,
    cellFor = cellFor,
    campfireEntryOnSquare = campfireEntryOnSquare,
}

return Resolver
