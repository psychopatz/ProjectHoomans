-- Live, authoritative community-place projection for semantic consumers.
-- Names and spatial relations are derived from current community records; no
-- presentation copy is written to excursion state or persistence.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.CommunityPlaceProjection = PNC.CommunityPlaceProjection or {}

local Projection = PNC.CommunityPlaceProjection
local Communities = PNC.Communities
local Spatial = PsychopatzCore and PsychopatzCore.SpatialRelation
    or require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"

Projection.VERSION = 1
Projection.MAX_NAME_LENGTH = 128

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function safeName(value)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, Projection.MAX_NAME_LENGTH)
end

local function pointFrom(value)
    if type(value) ~= "table" then return nil end
    local x = finite(value.x)
    local y = finite(value.y)
    local z = value.z == nil and 0 or finite(value.z)
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end

function Projection.ResolveCommunity(communityID)
    local community
    local home
    local site
    local name
    communityID = tostring(communityID or "")
    if communityID == ""
        or type(Communities.Get) ~= "function"
    then
        return nil, "community_unavailable"
    end
    community = Communities.Get(communityID)
    if type(community) ~= "table" then
        return nil, "community_not_found"
    end
    home = pointFrom(community.home)
    site = type(community.site) == "table" and community.site or nil
    if not home and site then home = pointFrom(site.home) end
    name = safeName(community.name)
    return {
        communityID = communityID,
        name = name,
        siteID = community.siteID or site and site.id or nil,
        point = home,
    }
end

function Projection.Relate(originCommunityID, destinationCommunityID, options)
    local origin
    local destination
    local relation
    local reason
    if originCommunityID == nil or destinationCommunityID == nil then
        return nil, "community_id_required"
    end
    origin, reason = Projection.ResolveCommunity(originCommunityID)
    if not origin then return nil, reason end
    destination, reason = Projection.ResolveCommunity(destinationCommunityID)
    if not destination then return nil, reason end
    if not origin.point or not destination.point then
        return {
            origin = origin,
            destination = destination,
        }, "coordinates_unavailable"
    end
    relation, reason = Spatial.Between(
        origin.point,
        destination.point,
        options
    )
    if not relation then return nil, reason end
    return {
        origin = origin,
        destination = destination,
        relation = relation,
        direction8 = relation.direction8,
        directionLabel = Spatial.GetDirectionLabel(
            relation.direction8,
            string.lower(tostring(relation.direction8 or ""))
        ),
        distanceBand = relation.distanceBand,
    }
end

return Projection
