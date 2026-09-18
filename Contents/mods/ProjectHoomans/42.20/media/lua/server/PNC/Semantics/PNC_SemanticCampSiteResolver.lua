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
    if hintScope and hintScope ~= scope and scope ~= CampSite.SCOPES.HERE then
        return nil
    end
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
    local movementX
    local movementY
    local movementZ
    if type(site) ~= "table" then return nil end
    movementX = number(site.movementX) or number(site.x)
    movementY = number(site.movementY) or number(site.y)
    movementZ = number(site.movementZ)
        or number(site.z) or 0
    if movementX == nil or movementY == nil then return nil end
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
        x = movementX,
        y = movementY,
        z = movementZ,
        movementX = movementX,
        movementY = movementY,
        movementZ = movementZ,
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
    local movementX
    local movementY
    local movementZ
    if type(site) ~= "table" then return nil end
    movementX = number(site.movementX) or number(site.x)
    movementY = number(site.movementY) or number(site.y)
    movementZ = number(site.movementZ)
        or number(site.z) or 0
    if movementX == nil or movementY == nil then return nil end
    return {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.CAMPFIRE,
        siteScope = CampSite.SCOPES.CAMPFIRE,
        siteID = text(site.targetID or site.resourceKey, 128),
        campfireID = text(site.targetID or site.resourceKey, 128),
        x = movementX,
        y = movementY,
        z = movementZ,
        movementX = movementX,
        movementY = movementY,
        movementZ = movementZ,
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

local function sameOptionalID(expected, actual)
    return expected == nil or tostring(expected) == ""
        or tostring(expected) == tostring(actual or "")
end

local audit

local function roomSiteID(identity)
    local bounds = identity and identity.roomBounds
    local roomKey = identity and identity.roomID
    if roomKey == nil and bounds then
        roomKey = tostring(bounds.minX) .. ":" .. tostring(bounds.minY)
    end
    return "room:" .. tostring(identity and identity.buildingID or "unknown")
        .. ":" .. tostring(roomKey or "unknown")
end

local function validateRoomHint(hint, context)
    local cell = cellFor(context)
    local square
    local identity
    local anchor
    local anchorReason
    local site
    local free
    local hintKind = string.lower(tostring(hint.kind or ""))
    if not Geometry or type(Geometry.GetSquare) ~= "function"
        or type(Geometry.RoomIdentity) ~= "function"
    then
        return nil, "camp_room_validation_unavailable"
    end
    if hintKind ~= "" and hintKind ~= CampSite.KIND
        and hintKind ~= CampSite.SCOPES.ROOM
    then
        return nil, "camp_site_hint_kind_mismatch"
    end
    square = Geometry.GetSquare(cell, hint.x, hint.y, hint.z)
    if not square then return nil, "camp_room_hint_not_loaded" end
    identity = Geometry.RoomIdentity(square)
    if not identity then return nil, "camp_room_hint_not_indoor" end
    if not sameOptionalID(hint.roomID, identity.roomID)
        or not sameOptionalID(hint.buildingID, identity.buildingID)
    then
        return nil, "camp_room_hint_stale"
    end
    free = call(square, "isFree", true)
    if free == false then return nil, "camp_room_hint_not_usable" end
    if not identity.roomBounds then
        return nil, "camp_room_bounds_unavailable"
    end
    -- The client hint identifies the room, but its exact square is not a
    -- trustworthy movement target. A free square may be deep inside the
    -- room, behind a blocked passage, or otherwise unsuitable for the native
    -- path planner. Re-resolve a bounded anchor from the server's room view
    -- while retaining the validated room identity and semantic label.
    if type(Geometry.DescribeRoom) ~= "function" then
        return nil, "camp_room_anchor_unavailable"
    end
    anchor, anchorReason = Geometry.DescribeRoom(
        square,
        nil,
        cell,
        originFor(context),
        {}
    )
    if not anchor then
        return nil, anchorReason or "camp_room_no_free_anchor"
    end
    site = {
        siteID = roomSiteID(identity),
        roomID = identity.roomID,
        buildingID = identity.buildingID,
        roomType = identity.roomType,
        roomName = identity.roomName,
        roomBounds = identity.roomBounds,
        x = number(anchor.movementX) or number(anchor.x),
        y = number(anchor.movementY) or number(anchor.y),
        z = number(anchor.movementZ) or number(anchor.z)
            or number(identity.z) or number(hint.z) or 0,
        movementX = number(anchor.movementX) or number(anchor.x),
        movementY = number(anchor.movementY) or number(anchor.y),
        movementZ = number(anchor.movementZ) or number(anchor.z)
            or number(identity.z) or number(hint.z) or 0,
        label = CampSite.RoomLabel(identity.roomType, identity.roomName),
        labelKey = "semantic.camp.room",
        risk = "sheltered",
        mode = "walk",
        stopDistance = 0.7,
        radius = 3,
        resourceRadius = 12,
    }
    if not sameOptionalID(hint.siteID, site.siteID) then
        return nil, "camp_room_hint_stale"
    end
    return normalizeRoomSite(site)
end

local function validateCampfireHint(target, context)
    local worldContext = {}
    local result
    local reason
    local requested
    if not WorldTargets
        or type(WorldTargets.ValidateCampfireHint) ~= "function"
    then
        return nil, "campfire_validation_unavailable"
    end
    for key, value in pairs(context or {}) do worldContext[key] = value end
    worldContext.origin = originFor(context)
    result, reason = WorldTargets.ValidateCampfireHint(target, worldContext)
    result = normalizeCampfireSite(result)
    if not result then return nil, reason or "campfire_hint_stale" end
    return result
end

-- Player-issued camps carry one client-observed primitive candidate. The
-- server checks that exact loaded square and never performs a fallback scan;
-- server-owned AI can continue using Resolve for its own broad search.
function Resolver.ValidateClientSite(target, context)
    context = type(context) == "table" and context or {}
    target = CampSite.NormalizeTarget(target)
    if type(target) ~= "table"
        or tostring(target.kind or "") ~= CampSite.KIND
    then
        return nil, "camp_site_target_required"
    end
    local hint = target.clientHint
    local requestedScope = scopeFor(target)
    local hintScope
    local scope
    local origin
    local hintX
    local hintY
    local hintZ
    local result
    local reason
    if type(hint) ~= "table" then return nil, "camp_site_hint_required" end
    hintScope = CampSite.NormalizeScope(hint.scope or hint.siteScope)
    scope = requestedScope == CampSite.SCOPES.HERE and hintScope
        or requestedScope
    if (scope ~= CampSite.SCOPES.ROOM
        and scope ~= CampSite.SCOPES.CAMPFIRE)
    then
        return nil, "camp_site_hint_scope_invalid"
    end
    if hintScope and requestedScope ~= CampSite.SCOPES.HERE
        and hintScope ~= requestedScope
    then
        return nil, "camp_site_hint_scope_mismatch"
    end
    origin = originFor(context)
    hintX, hintY, hintZ = position(hint)
    if hintX == nil or hintY == nil then
        return nil, "camp_site_hint_invalid"
    end
    if not origin then return nil, "camp_origin_unavailable" end
    if not safeHintDistance(hint, origin,
        target.radius or Resolver.DEFAULT_RADIUS)
    then
        return nil, "camp_site_hint_out_of_range"
    end
    if scope == CampSite.SCOPES.ROOM then
        result, reason = validateRoomHint(hint, context)
    else
        result, reason = validateCampfireHint(target, context)
    end
    audit(context, scope, queryFor(target), result, reason)
    if not result then return nil, reason or "camp_site_hint_stale" end
    return result
end

audit = function(context, scope, query, result, reason)
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
        movementX = result and result.movementX,
        movementY = result and result.movementY,
        movementZ = result and result.movementZ,
        roomID = result and result.roomID,
        roomType = result and result.roomType,
        campfireID = result and result.campfireID,
    }, { requestID = context and (context.requestID or context.planID) })
end

function Resolver.Resolve(target, context)
    context = type(context) == "table" and context or {}
    target = CampSite.NormalizeTarget(target)
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
        if not result and target.roomID == nil and target.siteID == nil then
            -- Room names are preferred semantic labels. Safety only requires
            -- a loaded indoor room, so an unclassified hallway/room is a
            -- valid fallback when the requested type is absent.
            result, reason = Geometry.FindNearestRoom(cell, origin, nil, {
                radius = math.max(4, math.min(64,
                    number(target.radius) or Resolver.DEFAULT_RADIUS)),
                preferredSiteID = hint and hint.siteID,
                preferredRoomID = hint and hint.roomID,
            })
            result = normalizeRoomSite(result)
            if result then reason = "camp_room_type_fallback" end
        end
        if not result then
            requested = campfireTarget(target, hint, origin)
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
            if result then
                reason = "campfire_fallback"
            else
                reason = query and "camp_room_not_found" or "camp_no_safe_room"
            end
        end
    elseif scope == CampSite.SCOPES.CAMPFIRE then
        requested = campfireTarget(target, hint, origin)
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
