-- Community map rendering and hover presentation provider.

PNC = PNC or {}
PNC.CommunityMapLayer = PNC.CommunityMapLayer or {}
local CommunityLayer = PNC.CommunityMapLayer
local Internal = CommunityLayer.Internal or {}
CommunityLayer.Internal = Internal
local ClientState = PNC.Network.ClientState
local Palette = PNC.NPCTypePalette
local TravelLayer = PNC.MapTravelLayer
local EmblemRenderer = PNC.FactionEmblemRenderer
local text = Internal.Text
local isVisible = Internal.IsVisible
local communitiesBySite = Internal.CommunitiesBySite
local relationFor = Internal.RelationFor
local colorFor = Internal.ColorFor
local darkTextColor = Internal.DarkTextColor
local drawRadius = Internal.DrawRadius
local drawBounds = Internal.DrawBounds
local lineDistance = Internal.LineDistance
local labelFor = Internal.LabelFor

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
    local leaderName = relation and relation.leaderName
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
            "UI_PNC_CommunityMapLeader",
            "Leader"
        ) .. ": " .. tostring(leaderName or "Unassigned"),
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
    if ClientState.communityDebugAuthorized ~= true then return end
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


return CommunityLayer
