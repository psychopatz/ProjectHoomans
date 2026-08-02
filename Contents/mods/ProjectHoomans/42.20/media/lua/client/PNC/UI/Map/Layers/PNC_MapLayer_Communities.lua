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
    return getText and getText(key) or fallback or key
end

local function isVisible()
    return PNC.MapDisplay
        and PNC.MapDisplay.AreBasesVisible
        and PNC.MapDisplay.AreBasesVisible()
        and ClientState.communityDebugAuthorized == true
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

local function statusText(snapshot, site, community)
    local relation = relationFor(snapshot, community)
    if site.status == "vacant" or not community
        or community.status ~= "active"
        or relation and relation.factionStatus
            and relation.factionStatus ~= "active"
    then
        return text(
            "UI_PNC_CommunityMapCollapsed",
            "Collapsed / unoccupied"
        )
    end
    if relation and relation.isPlayerFaction == true then
        return text(
            "UI_PNC_CommunityMapOwnFaction",
            "Your faction"
        )
    end
    if relation and relation.atWar == true then
        return text(
            "UI_PNC_CommunityMapAtWar",
            "At war with your faction"
        )
    end
    if relation and relation.allied == true then
        return text(
            "UI_PNC_CommunityMapAllied",
            "Allied with your faction"
        )
    end
    return text(
        "UI_PNC_CommunityMapRelation",
        "Relation"
    ) .. ": " .. tostring(
        relation and relation.state or "unknown"
    )
end

local function drawHoverCard(
    map,
    snapshot,
    site,
    community,
    mouseX,
    mouseY,
    color
)
    local relation = relationFor(snapshot, community)
    local emblem = relation and relation.emblem
    local emblemSize = 52
    local emblemPanelWidth = emblemSize + 12
    local cardPadding = 9
    local name = community and community.name
        or text(
            "UI_PNC_CommunityMapUnoccupied",
            "Unoccupied hideout"
        )
    local population = community
        and tostring(community.currentPopulation or 0)
            .. "/" .. tostring(
                community.populationCapacity or 0
            )
        or "0"
    local lines = {
        name,
        text(
            "UI_PNC_CommunityMapPopulation",
            "Population"
        ) .. ": " .. population,
        statusText(snapshot, site, community),
    }
    local manager = getTextManager and getTextManager() or nil
    local infoWidth = 130
    local index
    for index = 1, #lines do
        local measured = manager and manager.MeasureStringX
            and manager:MeasureStringX(
                UIFont.Small,
                lines[index]
            ) or #lines[index] * 7
        infoWidth = math.max(infoWidth, measured + cardPadding * 2)
    end
    local lineHeight = manager and manager.getFontHeight
        and manager:getFontHeight(UIFont.Small) or 14
    local height = math.max(
        lineHeight * #lines + 14,
        emblemSize + 12
    )
    local width = emblemPanelWidth + infoWidth
    local x = math.min(
        map.width - width - 5,
        mouseX + 12
    )
    local y = math.min(
        map.height - height - 5,
        mouseY + 12
    )
    if x < 5 then x = 5 end
    if y < 5 then y = 5 end
    map:drawRect(x, y, width, height, 0.94, 0.055, 0.055, 0.055)
    map:drawRectBorder(
        x,
        y,
        width,
        height,
        1,
        color.r,
        color.g,
        color.b
    )
    map:drawRect(
        x + emblemPanelWidth,
        y + 1,
        1,
        height - 2,
        0.72,
        color.r,
        color.g,
        color.b
    )
    if emblem and EmblemRenderer and EmblemRenderer.Draw then
        EmblemRenderer.Draw(
            map,
            emblem,
            x + 6,
            y + (height - emblemSize) / 2,
            emblemSize,
            { border = true }
        )
    end
    for index = 1, #lines do
        local shade = index == 1 and 1 or 0.78
        map:drawText(
            lines[index],
            x + emblemPanelWidth + cardPadding,
            y + 5 + (index - 1) * lineHeight,
            shade,
            shade,
            shade,
            1,
            UIFont.Small
        )
    end
end

function CommunityLayer.Render(map)
    if not isVisible() or not map or not map.mapAPI then
        return
    end
    if PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.Update
    then
        PNC.CommunityDebugOverlay.Update(false)
    end
    local snapshot = ClientState.communityDebug or {}
    local communityLookup = communitiesBySite(snapshot)
    local mouseX = map:getMouseX()
    local mouseY = map:getMouseY()
    local markerAtMouse = TravelLayer
        and TravelLayer.FindMarkerAt
        and TravelLayer.FindMarkerAt(
            map,
            mouseX,
            mouseY,
            3
        ) or nil
    local hoveredSite
    local hoveredCommunity
    local hoveredColor
    local bestDistance = 7
    for _, site in ipairs(snapshot.sites or {}) do
        local home = site.home
        if home and home.x and home.y then
            local community = communityLookup[site.id]
            local color = colorFor(
                snapshot,
                site,
                community
            )
            drawRadius(map, home, color)
            if site.kind == "building" then
                drawBounds(map, site.bounds, color)
            end
            local sx = map.mapAPI:worldToUIX(
                home.x,
                home.y
            )
            local sy = map.mapAPI:worldToUIY(
                home.x,
                home.y
            )
            local distance = not markerAtMouse
                and lineDistance(
                    map,
                    site,
                    mouseX,
                    mouseY
                ) or math.huge
            local hovered = distance <= 6
            if hovered and distance < bestDistance then
                hoveredSite = site
                hoveredCommunity = community
                hoveredColor = color
                bestDistance = distance
            end
            map:drawRect(
                sx - (hovered and 5 or 3),
                sy - (hovered and 5 or 3),
                hovered and 10 or 6,
                hovered and 10 or 6,
                1,
                color.r,
                color.g,
                color.b
            )
            local relation = relationFor(snapshot, community)
            local emblem = relation and relation.emblem
            if emblem and EmblemRenderer
                and EmblemRenderer.Draw
            then
                EmblemRenderer.Draw(
                    map,
                    emblem,
                    sx - 8,
                    sy - 8,
                    16
                )
            end
            local labelColor = darkTextColor(color)
            map:drawTextCentre(
                labelFor(site, community),
                sx,
                sy + 10,
                labelColor.r,
                labelColor.g,
                labelColor.b,
                1,
                UIFont.Small
            )
        end
    end
    if hoveredSite then
        drawHoverCard(
            map,
            snapshot,
            hoveredSite,
            hoveredCommunity,
            mouseX,
            mouseY,
            hoveredColor
        )
    end
end

local function contains(site, x, y)
    local bounds = site.bounds or {}
    if site.kind == "building"
        and tonumber(bounds.minX)
        and x >= bounds.minX and x <= bounds.maxX
        and y >= bounds.minY and y <= bounds.maxY
    then
        return true
    end
    local home = site.home or {}
    local dx = x - (tonumber(home.x) or 0)
    local dy = y - (tonumber(home.y) or 0)
    local radius = tonumber(home.radius) or 0
    return dx * dx + dy * dy <= radius * radius
end

local function vacantSiteAt(x, y)
    local snapshot = ClientState.communityDebug or {}
    local candidates = {}
    for _, site in ipairs(snapshot.sites or {}) do
        if site.status == "vacant" and contains(site, x, y) then
            candidates[#candidates + 1] = site
        end
    end
    table.sort(candidates, function(left, right)
        local leftRadius = tonumber(
            left.home and left.home.radius
        ) or 0
        local rightRadius = tonumber(
            right.home and right.home.radius
        ) or 0
        if leftRadius ~= rightRadius then
            return leftRadius < rightRadius
        end
        return left.id < right.id
    end)
    return candidates[1]
end

local function claimSite(site)
    if not site or not PNC.Client
        or not PNC.Client.SendDebug
    then
        return false
    end
    local sent = PNC.Client.SendDebug(
        "community_debug_action",
        {
            communityAction = "claim_site",
            siteID = site.id,
        }
    )
    if sent and PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.Update
    then
        PNC.CommunityDebugOverlay.Update(true)
    end
    return sent
end

if Layers and Layers.Register then
    Layers.Register("pnc_community_sites", {
        -- Base geometry stays beneath NPC dots and their hover portrait.
        order = 90,
        isVisible = isVisible,
        render = CommunityLayer.Render,
    })
end

if ISWorldMap and not ISWorldMap._pncCommunitySitesPatched then
    ISWorldMap._pncCommunitySitesPatched = true
    local originalRightMouseUp =
        ISWorldMap.onRightMouseUp
    function ISWorldMap:onRightMouseUp(x, y)
        if isVisible()
            and not (
                PNC.MapCommands
                and PNC.MapCommands.Active
            )
        then
            local worldX =
                self.mapAPI:uiToWorldX(x, y)
            local worldY =
                self.mapAPI:uiToWorldY(x, y)
            local site = vacantSiteAt(worldX, worldY)
            if site then
                local context = ISContextMenu.get(
                    tonumber(self.playerNum) or 0,
                    x + self:getAbsoluteX(),
                    y + self:getAbsoluteY()
                )
                context:addOption(
                    text(
                        "UI_PNC_CommunityClaimSite",
                        "Claim abandoned hideout"
                    ),
                    site,
                    claimSite
                )
                return true
            end
        end
        return originalRightMouseUp(self, x, y)
    end
end

return CommunityLayer
