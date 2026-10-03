-- Client overlay state synchronization, rendering, and reset lifecycle.
local Overlay = PNC.SettlementLayoutOverlay
local Internal = Overlay.Internal
local settlementKey = Internal.settlementKey

local function iconDrawer(playerNum)
    if not ISUIElement or not ISUIElement.new
        or not getPlayerScreenLeft or not getPlayerScreenTop
    then return nil end
    local x, y = getPlayerScreenLeft(playerNum), getPlayerScreenTop(playerNum)
    local width = getPlayerScreenWidth(playerNum)
    local height = getPlayerScreenHeight(playerNum)
    local drawer = Overlay.iconDrawer
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        drawer:setCapture(false)
        Overlay.iconDrawer = drawer
    else
        drawer:setX(x); drawer:setY(y)
        drawer:setWidth(width); drawer:setHeight(height)
    end
    return drawer
end

local function renderMarkers(playerNum)
    if not isoToScreenX or not isoToScreenY then return end
    local drawer = iconDrawer(playerNum)
    if not drawer then return end
    local mouseX = getMouseX and getMouseX() or nil
    local mouseY = getMouseY and getMouseY() or nil
    if mouseX ~= nil then mouseX = mouseX - drawer.x end
    if mouseY ~= nil then mouseY = mouseY - drawer.y end
    local hovered, hoveredDistance
    for _, marker in ipairs(Overlay.markers or {}) do
        marker.hovered = false
        if mouseX ~= nil and mouseY ~= nil then
            local screenX = isoToScreenX(playerNum,
                marker.x, marker.y, marker.z) - drawer.x
            local screenY = isoToScreenY(playerNum,
                marker.x, marker.y, marker.z) - drawer.y
            local xStep = math.abs(isoToScreenX(playerNum,
                marker.x + 1, marker.y, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local yStep = math.abs(isoToScreenX(playerNum,
                marker.x, marker.y + 1, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local tileWidth = math.max(16, 2 * math.max(xStep, yStep))
            local size = tileWidth * (tonumber(marker.tileScale) or 1)
            local dx = mouseX ~= nil and mouseX - screenX or nil
            local dy = mouseY ~= nil and mouseY - screenY or nil
            local distance = dx and dy and dx * dx + dy * dy or nil
            local hit = distance and math.abs(dx) <= math.max(12, size / 2)
                and math.abs(dy) <= math.max(12, size / 2)
            if hit and (not hoveredDistance or distance < hoveredDistance) then
                hovered, hoveredDistance = marker, distance
            end
        end
    end
    if hovered then hovered.hovered = true end
    Overlay.hoveredMarker = hovered
    return hovered, drawer
end

local function drawHoverLabel(drawer, marker)
    local label = marker and tostring(marker.label or "") or ""
    if label == "" or not drawer or not drawer.drawText then return end
    local mouseX = getMouseX and getMouseX() or drawer.x + 12
    local mouseY = getMouseY and getMouseY() or drawer.y + 12
    local x = mouseX - drawer.x + 12
    local y = mouseY - drawer.y + 12
    local width = math.max(86, #label * 7 + 18)
    local height = 24
    if x + width > drawer.width then x = drawer.width - width end
    if y + height > drawer.height then y = drawer.height - height end
    x, y = math.max(4, x), math.max(4, y)
    if drawer.drawRect then drawer:drawRect(x, y, width, height, 0.86, 0.02, 0.05, 0.07) end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(x, y, width, height, 0.95, 0.24, 0.72, 0.95)
    end
    drawer:drawText(label, x + 8, y + 5, 1, 1, 1, 1, UIFont and UIFont.Small)
end

function Overlay.Render()
    local selector = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.GridRegionSelector or nil
    if not Overlay.enabled or not addAreaHighlightForPlayer
        or selector and selector.instance
        and selector.instance.suppressPersistentOverlays == true
    then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0
    local hovered = renderMarkers(playerNum)
    for _, layer in ipairs(Overlay.layers or {}) do
        local visible = not layer.hoverOnly
        if not visible and hovered then
            visible = layer.id == hovered.id
                and (not layer.componentId or layer.componentId == hovered.id
                    or hovered.kind == "room")
        end
        if visible then
        for z, level in pairs(layer.region.levels or {}) do
            for y, spans in pairs(level.rows or {}) do
                local index
                for index = 1, #spans, 2 do
                    local color = layer.color
                    addAreaHighlightForPlayer(playerNum, spans[index], y,
                        spans[index + 1] + 1, y + 1, z,
                        color.r, color.g, color.b, color.a)
                end
            end
        end
        end
    end
    if hovered then
        local drawer = Overlay.iconDrawer
        drawHoverLabel(drawer, hovered)
    end
end

function Overlay.Reset()
    local state = PNC.Network and PNC.Network.ClientState or nil
    local restoreEnabled = Overlay.enabled == true
    Overlay.enabled = false
    Overlay.layers = {}
    Overlay.markers = {}
    Overlay.hoveredMarker = nil
    Overlay.settlementId = nil
    Overlay.revision = nil
    Overlay.snapshotKey = nil
    Overlay.restoreEnabled = restoreEnabled
    Overlay.resetRevision = tonumber(state and state.colonyManagementRevision) or 0
    Overlay.awaitingPostReset = true
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnTick then Events.OnTick.Add(Overlay.SyncFromClientState) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Reset) end
    Overlay.eventsInstalled = true
end

return Overlay
