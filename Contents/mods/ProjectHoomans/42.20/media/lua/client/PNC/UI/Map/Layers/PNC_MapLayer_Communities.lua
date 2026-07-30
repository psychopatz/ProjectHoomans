-- Admin/debug world-map visualization for persistent community sites.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"

PNC = PNC or {}
PNC.CommunityMapLayer = PNC.CommunityMapLayer or {}

local CommunityLayer = PNC.CommunityMapLayer
local Layers = PNC.MapLayers
local ClientState = PNC.Network.ClientState

local function text(key, fallback)
    return getText and getText(key) or fallback or key
end

local function isVisible()
    return PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.IsVisible
        and PNC.CommunityDebugOverlay.IsVisible()
        and ClientState.communityDebugAuthorized == true
end

local function communityForSite(snapshot, siteID)
    local best
    local bestAt = -1
    for _, community in ipairs(
        snapshot and snapshot.communities or {}
    ) do
        if community.siteID == siteID then
            local at = math.max(
                tonumber(community.destroyedAt) or 0,
                tonumber(community.archivedAt) or 0,
                tonumber(community.createdAt) or 0
            )
            if not best or at > bestAt
                or at == bestAt and community.id < best.id
            then
                best = community
                bestAt = at
            end
        end
    end
    return best
end

local function colorFor(site)
    if site.status == "claimed" then
        return { r = 0.25, g = 0.65, b = 1.0 }
    end
    if site.status == "occupied" then
        return { r = 0.25, g = 1.0, b = 0.45 }
    end
    return { r = 1.0, g = 0.62, b = 0.12 }
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
    local mouseX = map:getMouseX()
    local mouseY = map:getMouseY()
    for _, site in ipairs(snapshot.sites or {}) do
        local home = site.home
        if home and home.x and home.y then
            local color = colorFor(site)
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
            local hovered = math.abs(mouseX - sx) <= 10
                and math.abs(mouseY - sy) <= 10
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
            local community = communityForSite(
                snapshot,
                site.id
            )
            map:drawTextCentre(
                labelFor(site, community),
                sx,
                sy + 7,
                color.r,
                color.g,
                color.b,
                1,
                UIFont.Small
            )
        end
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
        order = 150,
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
