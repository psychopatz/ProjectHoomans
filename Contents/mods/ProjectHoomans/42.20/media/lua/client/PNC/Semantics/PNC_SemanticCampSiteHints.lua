-- Client-only preference resolver for semantic camp sites.
--
-- It inspects only the loaded cell and returns primitive hints. The server
-- independently resolves the room/campfire before movement or order mutation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Hints = PNC.Semantics.ClientCampSiteHints or {}
PNC.Semantics.ClientCampSiteHints = Hints
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local WorldHints = PNC.Semantics.ClientWorldTargetHints
    or require "PNC/Semantics/PNC_SemanticWorldTargetHints"
local Diagnostics = PNC.Semantics.SemanticDiagnostics

Hints.VERSION = 1
Hints.MAX_RADIUS = 32
Hints.CACHE_MS = 750
Hints.Cache = Hints.Cache or {}

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and number(value) then return value end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and number(value) then return value end
    end
    return 0
end

local function originFor(context)
    context = type(context) == "table" and context or {}
    return context.selectionOrigin or context.player
        or (type(getSpecificPlayer) == "function"
            and getSpecificPlayer(0) or nil)
end

local function queryFor(target)
    local value = target and (target.roomQuery or target.query
        or target.roomType or target.roomName)
    if type(value) == "table" then
        value = value.text or value.value or value.concept
    end
    return text(value, CampSite.MAX_QUERY)
end

local function scopeFor(target)
    return CampSite.NormalizeScope(target and (
        target.scope or target.siteScope)) or CampSite.SCOPES.HERE
end

local function position(value)
    if Geometry._Internal and Geometry._Internal.Position then
        return Geometry._Internal.Position(value)
    end
    return nil
end

local function cellFor(context)
    if type(context) == "table" and context.cell then
        return context.cell
    end
    if type(getCell) ~= "function" then return nil end
    local ok, cell = pcall(getCell)
    return ok and cell or nil
end

local function cacheKey(scope, query, origin, cell)
    local x, y, z = position(origin)
    return tostring(scope) .. "|" .. tostring(query or "") .. "|"
        .. tostring(math.floor(x or 0)) .. ":"
        .. tostring(math.floor(y or 0)) .. ":" .. tostring(z or 0)
        .. "|" .. tostring(cell)
end

local function audit(scope, query, hint, reason, details)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return
    end
    Diagnostics.Record("semantic.camp_site.client_hint", {
        scope = scope,
        query = query,
        status = hint and "attached" or "not_attached",
        reason = reason,
        siteID = hint and hint.siteID,
        roomID = hint and hint.roomID,
        roomType = hint and hint.roomType,
        campfireID = hint and hint.campfireID,
        x = hint and hint.x,
        y = hint and hint.y,
        score = hint and hint.score,
        roomReason = details and details.roomReason,
        fallbackReason = details and details.fallbackReason,
    }, {
        dedupeKey = "camp_site|" .. tostring(scope or "") .. "|"
            .. tostring(query or "") .. "|"
            .. tostring(hint and "attached" or "not_attached") .. "|"
            .. tostring(reason or ""),
        consoleIntervalMs = 1000,
    })
end

local function roomHint(site, query, timestamp)
    if not site then return nil end
    local distance = number(site.distance) or 0
    local score = math.max(0.62, math.min(1,
        1 - distance / math.max(8, Hints.MAX_RADIUS)))
    return {
        version = Hints.VERSION,
        source = "client_loaded_rooms",
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.ROOM,
        siteScope = CampSite.SCOPES.ROOM,
        siteID = text(site.siteID, 128),
        roomID = text(site.roomID, 128),
        buildingID = text(site.buildingID, 128),
        roomType = text(site.roomType, 48),
        roomName = text(site.roomName, 64),
        label = text(site.label, CampSite.MAX_LABEL),
        labelKey = text(site.labelKey, 96),
        risk = text(site.risk, 32),
        query = text(query, CampSite.MAX_QUERY),
        x = number(site.x),
        y = number(site.y),
        z = number(site.z) or 0,
        minX = site.roomBounds and site.roomBounds.minX,
        minY = site.roomBounds and site.roomBounds.minY,
        maxX = site.roomBounds and site.roomBounds.maxX,
        maxY = site.roomBounds and site.roomBounds.maxY,
        radius = Hints.MAX_RADIUS,
        score = score,
        observedAt = timestamp,
    }
end

local function campfireHint(target, context, origin, timestamp, cell)
    if type(WorldHints) ~= "table"
        or type(WorldHints.Resolve) ~= "function"
    then
        return nil, "world_hint_unavailable"
    end
    local hint, reason = WorldHints.Resolve({
        kind = "campfire",
        category = "CAMPFIRE",
        concept = "CAMPFIRE",
        text = "campfire",
        radius = target and target.radius or 16,
    }, context, { origin = origin, cell = cell })
    if not hint then return nil, reason end
    return {
        version = Hints.VERSION,
        source = "client_loaded_campfire",
        kind = "campfire",
        scope = CampSite.SCOPES.CAMPFIRE,
        siteScope = CampSite.SCOPES.CAMPFIRE,
        campfireID = hint.targetID or hint.resourceKey,
        label = "campfire",
        query = "campfire",
        x = hint.x,
        y = hint.y,
        z = hint.z,
        radius = hint.radius,
        score = hint.score,
        observedAt = timestamp,
    }
end

function Hints.ClearCache()
    Hints.Cache = {}
end

function Hints.Resolve(target, context)
    context = type(context) == "table" and context or {}
    target = CampSite.NormalizeTarget(target)
    if type(target) ~= "table" or target.kind ~= CampSite.KIND then
        return nil, "camp_site_target_required"
    end
    local scope = scopeFor(target)
    local query = queryFor(target)
    local origin = originFor(context)
    local cell = cellFor(context)
    local timestamp = nowMs()
    local key = cacheKey(scope, query, origin, cell)
    local cached = Hints.Cache[key]
    local site
    local hint
    local reason
    local roomReason
    local fallbackReason
    local hasExplicitRoom = target.roomID ~= nil
        or target.siteID ~= nil

    if cached and timestamp - cached.at <= Hints.CACHE_MS then
        return cached.hint, cached.reason
    end
    if not origin then reason = "world_origin_unavailable"
    elseif scope == CampSite.SCOPES.CAMPFIRE then
        hint, reason = campfireHint(target, context, origin, timestamp, cell)
    else
        site, roomReason = Geometry.FindNearestRoom(cell, origin, {
            text = query,
            roomType = target.roomType,
        }, {
            radius = Hints.MAX_RADIUS,
            preferredSiteID = target.siteID,
            preferredRoomID = target.roomID,
        })
        hint = roomHint(site, query, timestamp)
        if not hint and not hasExplicitRoom then
            -- A requested room label is a preference, not a safety
            -- requirement. If this building has no bedroom/living-room/etc,
            -- use the nearest loaded indoor room and let the hint carry its
            -- actual label (including the generic "room" fallback).
            site, fallbackReason = Geometry.FindNearestRoom(cell, origin,
                nil, {
                    radius = Hints.MAX_RADIUS,
                    preferredSiteID = target.siteID,
                    preferredRoomID = target.roomID,
                })
            hint = roomHint(site, query, timestamp)
            if hint then
                reason = "room_type_fallback"
            end
        end
        if not hint and scope == CampSite.SCOPES.HERE then
            hint, fallbackReason = campfireHint(target, context, origin,
                timestamp, cell)
            reason = hint and nil or fallbackReason or roomReason
        elseif not hint then
            -- An explicit room request still degrades to a nearby campfire
            -- when no indoor room is loaded; the server validates the exact
            -- primitive hint before accepting the command.
            hint, fallbackReason = campfireHint(target, context, origin,
                timestamp, cell)
            reason = hint and "campfire_fallback"
                or fallbackReason or roomReason or "room_not_found"
        end
    end
    Hints.Cache[key] = { at = timestamp, hint = hint, reason = reason }
    audit(scope, query, hint, reason, {
        roomReason = roomReason,
        fallbackReason = fallbackReason,
    })
    return hint, reason
end

return Hints
