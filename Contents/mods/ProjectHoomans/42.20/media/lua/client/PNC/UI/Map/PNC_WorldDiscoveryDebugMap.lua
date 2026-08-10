-- Debug-only right-click discovery actions for strategic map entities.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"

PNC = PNC or {}
PNC.WorldDiscoveryDebugMap = PNC.WorldDiscoveryDebugMap or {}

local State = PNC.Network.ClientState
local Types = PNC.WorldDiscoveryTypes
local DebugMap = PNC.WorldDiscoveryDebugMap
DebugMap.ShowRawEntities = DebugMap.ShowRawEntities == true

local function text(key)
    return getText and getText(key) or key
end

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

local function sendDiscoveryAll(scope)
    if not PNC.Client or not PNC.Client.RequestWorldDiscovery then
        return false
    end
    return PNC.Client.RequestWorldDiscovery("debug_discover_all", {
        scope = tostring(scope or "all"),
    })
end

local function toggleRawEntities()
    DebugMap.ShowRawEntities = not DebugMap.ShowRawEntities
    if DebugMap.ShowRawEntities and PNC.Client then
        if PNC.Client.RequestCommunityDebug then
            PNC.Client.RequestCommunityDebug()
        end
        if PNC.Client.RequestDirectorDebug then
            PNC.Client.RequestDirectorDebug()
        end
    end
    return true
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
        local originalResult = originalRightMouseUp(self, x, y)
        if canDebug() and self.mapAPI
            and not (PNC.MapCommands and PNC.MapCommands.Active)
        then
            local targets = {
                communityAt(self, x, y),
                groupAt(self, x, y),
            }
            local context = ISContextMenu.get(
                tonumber(self.playerNum) or 0,
                x + self:getAbsoluteX(),
                y + self:getAbsoluteY()
            )
            for _, target in ipairs(targets) do
                if target then
                    context:addOption(
                        text("UI_PNC_DebugDiscoveryDiscover")
                            .. " " .. target.label,
                        target,
                        sendDiscovery
                    )
                end
            end
            context:addOption(
                text("UI_PNC_DebugDiscoveryAllSettlements"),
                "settlements", sendDiscoveryAll
            )
            context:addOption(
                text("UI_PNC_DebugDiscoveryAllGroups"),
                "mobile_groups", sendDiscoveryAll
            )
            context:addOption(
                text("UI_PNC_DebugDiscoveryAllSignals"),
                "all", sendDiscoveryAll
            )
            context:addOption(
                text(DebugMap.ShowRawEntities
                    and "UI_PNC_DebugDiscoveryHideRaw"
                    or "UI_PNC_DebugDiscoveryShowRaw"),
                nil, toggleRawEntities
            )
            return true
        end
        return originalResult
    end
end

return true
