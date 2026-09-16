-- Authoritative resolver for semantic camping sites.
--
-- Client room/campfire observations are preferences only. The server performs
-- the final lookup against its own loaded world immediately before creating an
-- action plan, so discovery never becomes an unvalidated order.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Resolver = PNC.Semantics.CampSiteResolver or {}
PNC.Semantics.CampSiteResolver = Resolver
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local WorldTargets = PNC.Semantics.WorldTargetResolver
    or require "PNC/Semantics/PNC_SemanticWorldTargetResolver"
local Diagnostics = PNC.Semantics.SemanticDiagnostics

Resolver.VERSION = 1
Resolver.DEFAULT_RADIUS = 32
Resolver.CAMPFIRE_RADIUS = 16

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ")) or 0
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function originFor(context)
    context = type(context) == "table" and context or {}
    local origin = context.selectionOrigin or context.player
        or context.origin or context.body
    if origin then return origin end
    local record = context.record
    if not record then return nil end
    local x, y, z = position(record)
    if x == nil or y == nil then return nil end
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
    }
end

local function cellFor(context)
    if type(context) == "table" and context.cell then
        return context.cell
    end
    if type(getCell) == "function" then
        local ok, cell = pcall(getCell)
        if ok then return cell end
    end
    return nil
end

local function scopeFor(target)
    local scope = CampSite.NormalizeScope(target and (
        target.scope or target.siteScope))
    if scope then return scope end
    if target and (target.roomQuery or target.roomType or target.roomID) then
        return CampSite.SCOPES.ROOM
    end
    if target and (target.campfireID or target.fireID) then
        return CampSite.SCOPES.CAMPFIRE
    end
    return CampSite.SCOPES.HERE
end

local function queryFor(target)
    if type(target) ~= "table" then return nil end
    local query = target.roomQuery or target.query
        or target.roomType or target.roomName
    if type(query) == "table" then
        query = query.text or query.value or query.concept
    end
    query = text(query, CampSite.MAX_QUERY)
    if query == "house" or query == "building"
        or query == "indoors" or query == "inside"
    then
        return nil
    end
    return query
end

local function hintFor(target, scope)
    local hint = target and target.clientHint
    if type(hint) ~= "table" then return nil end
    local hintScope = CampSite.NormalizeScope(
        hint.siteScope or hint.scope)
    if hintScope and hintScope ~= scope then return nil end
    return hint
end

local function safeHintDistance(hint, origin, radius)
    local hx, hy, hz = position(hint)
    local ox, oy, oz = position(origin)
    local maximum
    if hx == nil or hy == nil or ox == nil or oy == nil then return false end
    maximum = math.max(4, math.min(40, number(radius) or 16) + 4)
    return (hx - ox) * (hx - ox) + (hy - oy) * (hy - oy)
        <= maximum * maximum
        and math.abs(hz - oz) <= 1
end

local function campfireTarget(target, hint, origin)
    local output = {
        kind = "campfire",
        targetID = text(target and (target.campfireID or target.fireID
            or target.targetID or target.objectID or target.worldID)),
        radius = math.max(4, math.min(32,
            number(target and target.radius) or Resolver.CAMPFIRE_RADIUS)),
        stopDistance = math.max(0.25,
            number(target and target.stopDistance) or 1.25),
        mode = text(target and target.mode) or "walk",
    }
    if hint and hint.kind == "campfire"
        and safeHintDistance(hint, origin, output.radius)
    then
        output.clientHint = hint
    end
    return output
end

local function normalizeRoomSite(site)
    if type(site) ~= "table" then return nil end
    if number(site.x) == nil or number(site.y) == nil then return nil end
    return {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.ROOM,
        siteScope = CampSite.SCOPES.ROOM,
        siteID = text(site.siteID, 128),
        roomID = text(site.roomID, 128),
        buildingID = text(site.buildingID, 128),
        roomType = text(site.roomType, 48),
        roomName = text(site.roomName, 64),
        roomBounds = CampSite.NormalizeBounds(site.roomBounds),
        x = number(site.x),
        y = number(site.y),
        z = number(site.z) or 0,
        label = text(site.label, CampSite.MAX_LABEL) or "room",
        labelKey = text(site.labelKey, 96) or "semantic.camp.room",
        risk = text(site.risk, 32) or "sheltered",
        mode = text(site.mode, 16) or "walk",
        stopDistance = math.max(0.25, number(site.stopDistance) or 0.7),
        radius = math.max(0.5, math.min(16, number(site.radius) or 3)),
        resourceRadius = math.max(1, math.min(24,
            number(site.resourceRadius) or 12)),
    }
end

local function normalizeCampfireSite(site)
    if type(site) ~= "table" then return nil end
    if number(site.x) == nil or number(site.y) == nil then return nil end
    return {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.CAMPFIRE,
        siteScope = CampSite.SCOPES.CAMPFIRE,
        siteID = text(site.targetID or site.resourceKey, 128),
        campfireID = text(site.targetID or site.resourceKey, 128),
        x = number(site.x),
        y = number(site.y),
        z = number(site.z) or 0,
        label = "campfire",
        labelKey = "semantic.camp.campfire",
        risk = "exposed",
        mode = text(site.mode, 16) or "walk",
        stopDistance = math.max(0.25, number(site.stopDistance) or 1.25),
        radius = math.max(0.5, math.min(16, number(site.radius) or 3)),
        resourceRadius = math.max(1, math.min(24,
            number(site.resourceRadius) or 12)),
        clientHintAccepted = site.clientHintAccepted == true,
        clientHintRejected = site.clientHintRejected == true,
    }
end

local function audit(context, scope, query, result, reason)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return
    end
    local origin = originFor(context)
    local ox, oy, oz = position(origin)
    Diagnostics.Record("semantic.camp_site.resolve", {
        requestID = context and (context.requestID or context.planID),
        npcID = context and context.npcID,
        scope = scope,
        query = query,
        status = result and "resolved" or "failed",
        reason = reason,
        originX = ox,
        originY = oy,
        originZ = oz,
        siteID = result and result.siteID,
        siteLabel = result and result.label,
        siteX = result and result.x,
        siteY = result and result.y,
        siteZ = result and result.z,
        roomID = result and result.roomID,
        roomType = result and result.roomType,
        campfireID = result and result.campfireID,
    }, { requestID = context and (context.requestID or context.planID) })
end

function Resolver.Resolve(target, context)
    context = type(context) == "table" and context or {}
    if type(target) ~= "table"
        or tostring(target.kind or "") ~= CampSite.KIND
    then
        return nil, "camp_site_target_required"
    end
    local scope = scopeFor(target)
    local query = queryFor(target)
    local origin = originFor(context)
    local cell = cellFor(context)
    local hint = hintFor(target, scope)
    local result
    local reason

    if not origin then
        reason = "camp_origin_unavailable"
    elseif scope == CampSite.SCOPES.ROOM then
        result, reason = Geometry.FindNearestRoom(cell, origin, {
            text = query,
            roomType = target.roomType,
            roomID = target.roomID,
        }, {
            radius = math.max(4, math.min(64,
                number(target.radius) or Resolver.DEFAULT_RADIUS)),
            preferredSiteID = hint and hint.siteID,
            preferredRoomID = hint and hint.roomID,
        })
        result = normalizeRoomSite(result)
        if not result then
            reason = query and "camp_room_not_found" or "camp_no_safe_room"
        end
    elseif scope == CampSite.SCOPES.CAMPFIRE then
        local requested = campfireTarget(target, hint, origin)
        result, reason = WorldTargets.Resolve(requested, {
            origin = origin,
            record = context.record,
            body = context.body,
            runtime = context.runtime,
            npcID = context.npcID,
            planID = context.planID,
            requestID = context.requestID,
        })
        result = normalizeCampfireSite(result)
        if not result then reason = reason or "campfire_not_found" end
    else
        result, reason = Geometry.FindNearestRoom(cell, origin, nil, {
            radius = math.max(4, math.min(64,
                number(target.radius) or Resolver.DEFAULT_RADIUS)),
            preferredSiteID = hint and hint.siteID,
            preferredRoomID = hint and hint.roomID,
        })
        result = normalizeRoomSite(result)
        if not result then
            local requested = campfireTarget(target, hint, origin)
            result, reason = WorldTargets.Resolve(requested, {
                origin = origin,
                record = context.record,
                body = context.body,
                runtime = context.runtime,
                npcID = context.npcID,
                planID = context.planID,
                requestID = context.requestID,
            })
            result = normalizeCampfireSite(result)
            if not result then reason = "camp_no_room_or_campfire" end
        end
    end

    audit(context, scope, query, result, reason)
    if not result then return nil, reason or "camp_site_unresolved" end
    return result
end

return Resolver
