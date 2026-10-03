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
local number = Internal.Number
local originFor = Internal.OriginFor
local cellFor = Internal.CellFor
local scopeFor = Internal.ScopeFor
local queryFor = Internal.QueryFor
local hintFor = Internal.HintFor
local campfireTarget = Internal.CampfireTarget
local normalizeRoomSite = Internal.NormalizeRoomSite
local normalizeCampfireSite = Internal.NormalizeCampfireSite
local audit = Internal.Audit

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
