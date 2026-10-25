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
local Projection = require
    "PNC/Semantics/PNC_SemanticCampSiteHints_Projection"

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
        local value = getTimestampMs()
        if number(value) then return value end
    end
    if type(getTimeInMillis) == "function" then
        local value = getTimeInMillis()
        if number(value) then return value end
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
    return getCell()
end

local function withinServerRange(value, origin, radius)
    local x, y, z = position(value)
    local ox, oy, oz = position(origin)
    if not x or not y or not ox or not oy then return false end
    local maximum = math.min(40, math.max(4, tonumber(radius)
        or Hints.MAX_RADIUS) + 4)
    local dx = x - ox
    local dy = y - oy
    return dx * dx + dy * dy <= maximum * maximum
        and math.abs((z or 0) - (oz or 0)) <= 1
end

local function cacheKey(scope, query, origin, cell, target)
    local x, y, z = position(origin)
    return tostring(scope) .. "|" .. tostring(query or "") .. "|"
        .. tostring(math.floor(x or 0)) .. ":"
        .. tostring(math.floor(y or 0)) .. ":" .. tostring(z or 0)
        .. "|" .. tostring(cell) .. "|"
        .. tostring(target and target.siteID or "") .. "|"
        .. tostring(target and target.roomID or "") .. "|"
        .. tostring(target and target.campfireID or "") .. "|"
        .. tostring(target and target.requireExact == true or false)
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

function Hints.ClearCache()
    Hints.Cache = {}
end

-- Return only bounded primitive observations for semantic menu projection.
-- Engine room/building objects never leave this client-side adapter.
function Hints.Enumerate(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    local cell = cellFor(context)
    if not cell then return {}, "cell_unavailable" end

    local origin = originFor(context)
    if not origin or not position(origin) then
        return {}, "world_origin_unavailable"
    end
    local timestamp = nowMs()
    local output = {}
    local seen = {}
    local maxRooms = tonumber(options.maxRooms) or 8
    if maxRooms < 1 then maxRooms = 1 end
    if maxRooms > 16 then maxRooms = 16 end

    local function appendRoom(site)
        if not site or #output >= maxRooms then return end
        if not withinServerRange(site, origin, Hints.MAX_RADIUS) then
            return
        end
        local hint = Projection.Room(
            site,
            site.query or options.query or "room",
            timestamp,
            Hints,
            CampSite
        )
        local key = hint and (hint.siteID or "") .. "|" .. (hint.roomID or "")
        if hint and key ~= "|" and not seen[key] then
            seen[key] = true
            output[#output + 1] = hint
        end
    end

    Geometry.EnumerateRooms(cell, function(room, building)
        if #output >= maxRooms then return end
        local site = Geometry.DescribeRoom(room, building, cell, origin, {
            -- Dynamic Camp navigation discovers every valid loaded room.
            -- The literal fallback "room" is a name filter and rejects
            -- real room names such as HALLWAY when no query was supplied.
            query = options.query,
        })
        appendRoom(site)
    end, {
        maxRooms = maxRooms,
        maxBuildings = options.maxBuildings or 16,
    })

    -- The loaded cell's room/building index is presentation assistance only
    -- and is not guaranteed to include the room containing the player. Reuse
    -- the existing room-first resolver before falling back to campfires so a
    -- valid current hallway/room is still offered in the semantic branch.
    if #output == 0 and origin
        and type(Geometry.FindNearestRoom) == "function"
    then
        local site = Geometry.FindNearestRoom(cell, origin, nil, {
            radius = Hints.MAX_RADIUS,
        })
        appendRoom(site)
    end

    local campfireCandidates = context.campfireCandidates
    if type(campfireCandidates) == "table" then
        for _, candidate in ipairs(campfireCandidates) do
            if #output >= maxRooms then break end
            if type(candidate) == "table" then
                local key = (candidate.siteID or "") .. "|" .. (candidate.campfireID or "")
                if key ~= "|" and not seen[key]
                    and withinServerRange(
                        candidate, origin, candidate.radius or Hints.MAX_RADIUS
                    )
                then
                    seen[key] = true
                    output[#output + 1] = candidate
                end
            end
        end
    end

    return output
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
    local key = cacheKey(scope, query, origin, cell, target)
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
        hint, reason = Projection.Campfire(
            target, context, origin, timestamp, cell, Hints, CampSite,
            WorldHints)
    else
        site, roomReason = Geometry.FindNearestRoom(cell, origin, {
            text = query,
            roomType = target.roomType,
        }, {
            radius = Hints.MAX_RADIUS,
            preferredSiteID = target.siteID,
            preferredRoomID = target.roomID,
        })
        hint = Projection.Room(site, query, timestamp, Hints, CampSite)
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
            hint = Projection.Room(site, query, timestamp, Hints, CampSite)
            if hint then
                reason = "room_type_fallback"
            end
        end
        if target.requireExact == true and not hint then
            reason = reason or "camp_site_hint_stale"
        elseif not hint and scope == CampSite.SCOPES.HERE then
            hint, fallbackReason = Projection.Campfire(
                target, context, origin, timestamp, cell, Hints, CampSite,
                WorldHints)
            reason = hint and nil or fallbackReason or roomReason
        elseif not hint then
            -- An explicit room request still degrades to a nearby campfire
            -- when no indoor room is loaded; the server validates the exact
            -- primitive hint before accepting the command.
            hint, fallbackReason = Projection.Campfire(
                target, context, origin, timestamp, cell, Hints, CampSite,
                WorldHints)
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
