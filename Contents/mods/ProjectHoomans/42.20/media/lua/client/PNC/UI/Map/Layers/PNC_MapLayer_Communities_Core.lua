-- Admin/debug world-map visualization for persistent community sites.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"
require "PNC/UI/PNC_NPCTypePalette"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.CommunityMapLayer = PNC.CommunityMapLayer or {}

local CommunityLayer = PNC.CommunityMapLayer
local Layers = PNC.MapLayers
local ClientState = PNC.Network.ClientState
local Palette = PNC.NPCTypePalette
local TravelLayer = PNC.MapTravelLayer
local EmblemRenderer = PNC.FactionEmblemRenderer

local function text(key, fallback)
    return getText and PNC.Translation.GetKey(key) or fallback or key
end

local function isVisible()
    return PNC.MapDisplay
        and PNC.MapDisplay.AreBasesVisible
        and PNC.MapDisplay.AreBasesVisible()
        and PNC.WorldDiscoveryDebugMap
        and PNC.WorldDiscoveryDebugMap.ShowRawEntities == true
        and (ClientState.communityDebugAuthorized == true
            or PNC.Client and PNC.Client.CanUseDebug
                and PNC.Client.CanUseDebug())
end

local function communitiesBySite(snapshot)
    local output = {}
    local bestAt = {}
    for _, community in ipairs(
        snapshot and snapshot.communities or {}
    ) do
        local siteID = community.siteID
        if siteID then
            local at = math.max(
                tonumber(community.destroyedAt) or 0,
                tonumber(community.archivedAt) or 0,
                tonumber(community.createdAt) or 0
            )
            local current = output[siteID]
            local currentAt = bestAt[siteID] or -1
            if not current or at > currentAt
                or at == currentAt
                    and community.id < current.id
            then
                output[siteID] = community
                bestAt[siteID] = at
            end
        end
    end
    return output
end

local function relationFor(snapshot, community)
    local factionID = community and community.factionID
    return factionID
        and snapshot
        and snapshot.factionRelations
        and snapshot.factionRelations[factionID]
        or nil
end

local function presentationType(snapshot, site, community)
    if site.status == "vacant"
        or not community
        or community.status ~= "active"
    then
        return "dead"
    end
    local relation = relationFor(snapshot, community)
    if relation and relation.factionStatus
        and relation.factionStatus ~= "active"
    then
        return "dead"
    end
    if relation and (
        relation.atWar == true
        or relation.state == "war"
        or relation.state == "hostile"
    ) then
        return "hostile"
    end
    if relation and relation.isPlayerFaction == true then
        return "colonist"
    end
    if relation and (
        relation.allied == true
        or relation.state == "allied"
        or relation.state == "friendly"
    ) then
        return "follower"
    end
    return "neutral"
end

local function colorFor(snapshot, site, community)
    return Palette.Get(
        presentationType(snapshot, site, community)
    )
end

local function darkTextColor(color)
    return {
        r = math.max(0.035, color.r * 0.38),
        g = math.max(0.035, color.g * 0.38),
        b = math.max(0.035, color.b * 0.38),
    }
end

local function drawLine(map, x1, y1, x2, y2, color, alpha)
    if not map.javaObject or not map.javaObject.DrawLine then
        return
    end
    map.javaObject:DrawLine(
        nil,
        map.mapAPI:worldToUIX(x1, y1),
        map.mapAPI:worldToUIY(x1, y1),
        map.mapAPI:worldToUIX(x2, y2),
        map.mapAPI:worldToUIY(x2, y2),
        2,
        color.r,
        color.g,
        color.b,
        alpha
    )
end

local function drawRadius(map, home, color)
    local segments = 32
    local radius = math.max(1, tonumber(home.radius) or 1)
    local previousX = home.x + radius
    local previousY = home.y
    local index
    for index = 1, segments do
        local angle = math.pi * 2 * index / segments
        local x = home.x + math.cos(angle) * radius
        local y = home.y + math.sin(angle) * radius
        drawLine(
            map,
            previousX,
            previousY,
            x,
            y,
            color,
            0.78
        )
        previousX = x
        previousY = y
    end
end

local function drawBounds(map, bounds, color)
    if type(bounds) ~= "table" then return end
    drawLine(map, bounds.minX, bounds.minY,
        bounds.maxX, bounds.minY, color, 0.95)
    drawLine(map, bounds.maxX, bounds.minY,
        bounds.maxX, bounds.maxY, color, 0.95)
    drawLine(map, bounds.maxX, bounds.maxY,
        bounds.minX, bounds.maxY, color, 0.95)
    drawLine(map, bounds.minX, bounds.maxY,
        bounds.minX, bounds.minY, color, 0.95)
end

local function labelFor(site, community)
    local name = community and community.name
        or text(
            "UI_PNC_CommunityMapUnoccupied",
            "Unoccupied hideout"
        )
    if site.status == "claimed" then
        return name .. " ["
            .. text(
                "UI_PNC_CommunityMapClaimed",
                "claimed"
            ) .. "]"
    end
    if site.status == "vacant" then
        return name .. " ["
            .. text(
                "UI_PNC_CommunityMapVacant",
                "vacant"
            ) .. "]"
    end
    return name
end

local function pointSegmentDistance(
    px,
    py,
    x1,
    y1,
    x2,
    y2
)
    local dx = x2 - x1
    local dy = y2 - y1
    local lengthSquared = dx * dx + dy * dy
    if lengthSquared <= 0 then
        local ox = px - x1
        local oy = py - y1
        return math.sqrt(ox * ox + oy * oy)
    end
    local ratio = (
        (px - x1) * dx + (py - y1) * dy
    ) / lengthSquared
    ratio = math.max(0, math.min(1, ratio))
    local ox = px - (x1 + ratio * dx)
    local oy = py - (y1 + ratio * dy)
    return math.sqrt(ox * ox + oy * oy)
end

local function boundsLineDistance(map, bounds, mouseX, mouseY)
    if type(bounds) ~= "table" then return math.huge end
    local x1 = map.mapAPI:worldToUIX(
        bounds.minX,
        bounds.minY
    )
    local y1 = map.mapAPI:worldToUIY(
        bounds.minX,
        bounds.minY
    )
    local x2 = map.mapAPI:worldToUIX(
        bounds.maxX,
        bounds.minY
    )
    local y2 = map.mapAPI:worldToUIY(
        bounds.maxX,
        bounds.minY
    )
    local x3 = map.mapAPI:worldToUIX(
        bounds.maxX,
        bounds.maxY
    )
    local y3 = map.mapAPI:worldToUIY(
        bounds.maxX,
        bounds.maxY
    )
    local x4 = map.mapAPI:worldToUIX(
        bounds.minX,
        bounds.maxY
    )
    local y4 = map.mapAPI:worldToUIY(
        bounds.minX,
        bounds.maxY
    )
    return math.min(
        pointSegmentDistance(mouseX, mouseY, x1, y1, x2, y2),
        pointSegmentDistance(mouseX, mouseY, x2, y2, x3, y3),
        pointSegmentDistance(mouseX, mouseY, x3, y3, x4, y4),
        pointSegmentDistance(mouseX, mouseY, x4, y4, x1, y1)
    )
end

local function radiusLineDistance(map, home, mouseX, mouseY)
    local sx = map.mapAPI:worldToUIX(home.x, home.y)
    local sy = map.mapAPI:worldToUIY(home.x, home.y)
    local edgeX = map.mapAPI:worldToUIX(
        home.x + math.max(1, tonumber(home.radius) or 1),
        home.y
    )
    local edgeY = map.mapAPI:worldToUIY(
        home.x + math.max(1, tonumber(home.radius) or 1),
        home.y
    )
    local radiusX = edgeX - sx
    local radiusY = edgeY - sy
    local screenRadius = math.sqrt(
        radiusX * radiusX + radiusY * radiusY
    )
    local mouseDX = mouseX - sx
    local mouseDY = mouseY - sy
    return math.abs(
        math.sqrt(mouseDX * mouseDX + mouseDY * mouseDY)
            - screenRadius
    )
end

local function lineDistance(map, site, mouseX, mouseY)
    local distance = radiusLineDistance(
        map,
        site.home,
        mouseX,
        mouseY
    )
    if site.kind == "building" then
        distance = math.min(
            distance,
            boundsLineDistance(
                map,
                site.bounds,
                mouseX,
                mouseY
            )
        )
    end
    return distance
end


CommunityLayer.Internal = CommunityLayer.Internal or {}
local Internal = CommunityLayer.Internal
Internal.Text = text
Internal.IsVisible = isVisible
Internal.CommunitiesBySite = communitiesBySite
Internal.RelationFor = relationFor
Internal.PresentationType = presentationType
Internal.ColorFor = colorFor
Internal.DarkTextColor = darkTextColor
Internal.DrawLine = drawLine
Internal.DrawRadius = drawRadius
Internal.DrawBounds = drawBounds
Internal.LabelFor = labelFor
Internal.PointSegmentDistance = pointSegmentDistance
Internal.BoundsLineDistance = boundsLineDistance
Internal.RadiusLineDistance = radiusLineDistance
Internal.LineDistance = lineDistance

return CommunityLayer
