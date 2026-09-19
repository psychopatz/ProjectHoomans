-- Shared room-identity and spatial membership predicates for camp services.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Geometry.RoomIdentity) ~= "function" then
    error("camp-site membership requires room records")
end

local CampSite = Internal.CampSite
local number = Internal.Number

function Geometry.MatchesRoom(square, site)
    if type(site) ~= "table" or site.scope ~= CampSite.SCOPES.ROOM
        and site.siteScope ~= CampSite.SCOPES.ROOM
    then
        return false
    end
    local identity = Geometry.RoomIdentity(square)
    if not identity then return false end
    if site.buildingID and identity.buildingID
        and tostring(site.buildingID) ~= tostring(identity.buildingID)
    then
        return false
    end
    if site.roomID and identity.roomID then
        return tostring(site.roomID) == tostring(identity.roomID)
    end
    if site.roomType and identity.roomType
        and tostring(site.roomType) ~= tostring(identity.roomType)
    then
        return false
    end
    if site.roomBounds then
        return CampSite.BoundsContain(site.roomBounds,
            identity.x, identity.y, identity.z)
    end
    return site.roomType == nil or identity.roomType == site.roomType
end

-- Shared primitive membership check for camp activity and resource targets.
-- Room sites are area/identity based; campfire sites retain their bounded
-- Euclidean radius. Java objects are optional and are only consulted when a
-- live square is available.
function Geometry.ContainsPoint(site, x, y, z, options)
    options = type(options) == "table" and options or {}
    if type(site) ~= "table" then return false end
    x, y, z = number(x), number(y), number(z) or 0
    if x == nil or y == nil then return false end

    local scope = CampSite.NormalizeScope(site.scope or site.siteScope)
    if not scope then
        scope = site.roomBounds and CampSite.SCOPES.ROOM
            or CampSite.SCOPES.CAMPFIRE
    end
    if scope == CampSite.SCOPES.ROOM then
        if not CampSite.BoundsContain(site.roomBounds,
            math.floor(x), math.floor(y), z)
        then
            return false
        end
        if options.checkRoomIdentity ~= false then
            local square = options.square
                or Geometry.GetSquare(options.cell, x, y, z)
            if square and not Geometry.MatchesRoom(square, site) then
                return false
            end
        end
        return true
    end
    if scope == CampSite.SCOPES.CAMPFIRE then
        local anchorX = number(site.x)
        local anchorY = number(site.y)
        local anchorZ = number(site.z) or 0
        local radius = number(options.radius)
            or number(site.radius) or 3
        if anchorX == nil or anchorY == nil
            or math.abs(z - anchorZ) > 0.5
        then
            return false
        end
        local dx, dy = x - anchorX, y - anchorY
        return dx * dx + dy * dy
            <= (radius + 0.5) * (radius + 0.5)
    end
    return false
end


return Geometry
