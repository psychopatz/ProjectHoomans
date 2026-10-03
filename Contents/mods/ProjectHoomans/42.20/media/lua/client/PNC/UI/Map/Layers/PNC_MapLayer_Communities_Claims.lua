-- Community map vacant-site claims and registration provider.

PNC = PNC or {}
PNC.CommunityMapLayer = PNC.CommunityMapLayer or {}
local CommunityLayer = PNC.CommunityMapLayer
local Internal = CommunityLayer.Internal or {}
CommunityLayer.Internal = Internal
local Layers = PNC.MapLayers
local ClientState = PNC.Network.ClientState
local TravelLayer = PNC.MapTravelLayer
local text = Internal.Text
local isVisible = Internal.IsVisible
local relationFor = Internal.RelationFor
local colorFor = Internal.ColorFor

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
