-- Debug-only right-click discovery actions for strategic map entities.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"

PNC = PNC or {}

local State = PNC.Network.ClientState
local Types = PNC.WorldDiscoveryTypes

local function canDebug()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

local function sendDiscovery(target)
    if not target or not PNC.Client
        or not PNC.Client.RequestWorldDiscovery
    then return false end
    return PNC.Client.RequestWorldDiscovery("debug_discover", {
        kind = target.kind,
        entityID = target.entityID,
    })
end

local function communityAt(map, x, y)
    local snapshot = State.communityDebug or {}
    local communityBySite = {}
    for _, community in ipairs(snapshot.communities or {}) do
        if community.status == "active" and community.siteID then
            communityBySite[community.siteID] = community
        end
    end
    local best
    local bestDistance = 12
    for _, site in ipairs(snapshot.sites or {}) do
        local community = communityBySite[site.id]
        local home = site.home
        if community and home and home.x and home.y then
            local sx = map.mapAPI:worldToUIX(home.x, home.y)
            local sy = map.mapAPI:worldToUIY(home.x, home.y)
            local dx, dy = x - sx, y - sy
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= bestDistance then
                bestDistance = distance
                best = {
                    kind = Types.KIND_SETTLEMENT,
                    entityID = tostring(community.id),
                    label = tostring(community.name or "settlement"),
                }
            end
        end
    end
    return best
end

local function groupAt(map, x, y)
    local snapshot = State.directorDebug or {}
    local best
    local bestDistance = 12
    for _, group in ipairs(snapshot.groups or {}) do
        local location = group.location
        if location and location.x and location.y then
            local sx = map.mapAPI:worldToUIX(location.x, location.y)
            local sy = map.mapAPI:worldToUIY(location.x, location.y)
            local dx, dy = x - sx, y - sy
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= bestDistance then
                bestDistance = distance
                best = {
                    kind = Types.KIND_MOBILE_GROUP,
                    entityID = tostring(group.id),
                    label = tostring(group.groupType
                        or getText("UI_PNC_MobileGroup")),
                }
            end
        end
    end
    return best
end

if ISWorldMap and not ISWorldMap._pncWorldDiscoveryDebugPatched then
    ISWorldMap._pncWorldDiscoveryDebugPatched = true
    local originalRightMouseUp = ISWorldMap.onRightMouseUp
    function ISWorldMap:onRightMouseUp(x, y)
        if canDebug() and self.mapAPI
            and not (PNC.MapCommands and PNC.MapCommands.Active)
        then
            local targets = {
                communityAt(self, x, y),
                groupAt(self, x, y),
            }
            local context
            for _, target in ipairs(targets) do
                if target then
                    context = context or ISContextMenu.get(
                        tonumber(self.playerNum) or 0,
                        x + self:getAbsoluteX(),
                        y + self:getAbsoluteY()
                    )
                    context:addOption(
                        "[DEBUG] Discover " .. target.label,
                        target,
                        sendDiscovery
                    )
                end
            end
            if context then return true end
        end
        return originalRightMouseUp(self, x, y)
    end
end

return true
