if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Resolver = PNC.Semantics.CampSiteResolver or {}
PNC.Semantics.CampSiteResolver = Resolver
local Internal = Resolver.Internal or {}
Resolver.Internal = Internal
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local WorldTargets = PNC.Semantics.WorldTargetResolver
    or require "PNC/Semantics/PNC_SemanticWorldTargetResolver"
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local cellFor = Internal.CellFor
local originFor = Internal.OriginFor
local call = Internal.Call
local number = Internal.Number
local position = Internal.Position
local scopeFor = Internal.ScopeFor
local queryFor = Internal.QueryFor
local safeHintDistance = Internal.SafeHintDistance
local normalizeRoomSite = Internal.NormalizeRoomSite
local normalizeCampfireSite = Internal.NormalizeCampfireSite
local sameOptionalID = Internal.SameOptionalID

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

Internal.Audit = audit

return Resolver
