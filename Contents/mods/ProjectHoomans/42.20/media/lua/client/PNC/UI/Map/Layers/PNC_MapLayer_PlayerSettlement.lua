-- Player-owned settlement coverage for the vanilla world map.

require "ISUI/Maps/ISWorldMap"

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC = PNC or {}
local Presentation = PNC.PlayerSettlementMapPresentation
    or require "PNC/UI/Map/Layers/PNC_MapLayer_PlayerSettlement_Presentation"
PNC.PlayerSettlementMapLayer = PNC.PlayerSettlementMapLayer or {}

local Layer = PNC.PlayerSettlementMapLayer
local Layers = PNC.MapLayers
local TravelLayer = PNC.MapTravelLayer

Layer.RefreshMs = tonumber(Layer.RefreshMs) or 1500
Layer.LastRequestAt = tonumber(Layer.LastRequestAt) or 0
Layer.RequestedWithoutClock = Layer.RequestedWithoutClock == true

local COLORS = {
    border = { r = 0.12, g = 0.72, b = 1.00 },
    label = { r = 0.05, g = 0.32, b = 0.48 },
}

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function now()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function snapshotAndSettlement()
    local snapshot = clientState().colonyManagement
    return snapshot, snapshot and snapshot.settlement or nil
end

local function isVisible()
    if not PNC.MapDisplay or not PNC.MapDisplay.AreBasesVisible then
        return true
    end
    return PNC.MapDisplay.AreBasesVisible() == true
end

Layer.IsVisible = isVisible

function Layer.Update(force)
    local snapshot, settlement = snapshotAndSettlement()
    if settlement and settlement.geometry then
        Layer.RequestedWithoutClock = false
        return true
    end

    local timestamp = now()
    if force ~= true then
        if timestamp > 0 then
            if Layer.LastRequestAt > 0
                and timestamp - Layer.LastRequestAt < Layer.RefreshMs
            then
                return false
            end
        elseif Layer.RequestedWithoutClock then
            return false
        end
    end
    Layer.LastRequestAt = timestamp
    Layer.RequestedWithoutClock = timestamp <= 0

    local client = PNC.ColonyManagementClient
    if client and type(client.RequestSnapshot) == "function" then
        client.RequestSnapshot()
        return true
    end
    if PNC.Client and type(PNC.Client.RequestColonyManagement) == "function" then
        PNC.Client.RequestColonyManagement()
        return true
    end
    return false
end

local function numericBounds(bounds)
    if type(bounds) ~= "table" then return nil end
    local minX, minY = tonumber(bounds.minX), tonumber(bounds.minY)
    local maxX, maxY = tonumber(bounds.maxX), tonumber(bounds.maxY)
    if not minX or not minY or not maxX or not maxY
        or minX > maxX or minY > maxY
    then
        return nil
    end
    return minX, minY, maxX, maxY
end

local function contains(settlement, x, y)
    local geometry = settlement and settlement.geometry or nil
    local minX, minY, maxX, maxY = numericBounds(
        geometry and geometry.bounds
    )
    if not minX then return false end
    local tileX, tileY = math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0)
    if tileX < minX or tileX > maxX
        or tileY < minY or tileY > maxY
    then
        return false
    end

    local region = geometry and geometry.region
    if type(region) == "table"
        and type(GridRegion.containsXY) == "function"
    then
        return GridRegion.containsXY(region, tileX, tileY) == true
    end
    return true
end

function Layer.FindAt(map, mouseX, mouseY)
    if not map or not map.mapAPI then return nil end
    local worldX = map.mapAPI:uiToWorldX(mouseX, mouseY)
    local worldY = map.mapAPI:uiToWorldY(mouseX, mouseY)
    local snapshot, settlement = snapshotAndSettlement()
    if settlement and contains(settlement, worldX, worldY) then
        return settlement, snapshot, worldX, worldY
    end
    return nil
end

local function drawLine(map, x1, y1, x2, y2, color, alpha)
    if map.javaObject and map.javaObject.DrawLine then
        map.javaObject:DrawLine(nil,
            map.mapAPI:worldToUIX(x1, y1),
            map.mapAPI:worldToUIY(x1, y1),
            map.mapAPI:worldToUIX(x2, y2),
            map.mapAPI:worldToUIY(x2, y2),
            2, color.r, color.g, color.b, alpha)
    end
end

local function drawBounds(map, bounds, color)
    local minX, minY, maxX, maxY = numericBounds(bounds)
    if not minX then return false end

    -- Bounds are inclusive tile coordinates. The +1 edges draw the border on
    -- the outside of the final claimed tile instead of through its center.
    maxX, maxY = maxX + 1, maxY + 1
    drawLine(map, minX, minY, maxX, minY, color, 0.95)
    drawLine(map, maxX, minY, maxX, maxY, color, 0.95)
    drawLine(map, maxX, maxY, minX, maxY, color, 0.95)
    drawLine(map, minX, maxY, minX, minY, color, 0.95)
    if map.javaObject and map.javaObject.DrawLine then return true end

    if map.drawRectBorder then
        local x1 = map.mapAPI:worldToUIX(minX, minY)
        local y1 = map.mapAPI:worldToUIY(minX, minY)
        local x2 = map.mapAPI:worldToUIX(maxX, maxY)
        local y2 = map.mapAPI:worldToUIY(maxX, maxY)
        map:drawRectBorder(math.min(x1, x2), math.min(y1, y2),
            math.abs(x2 - x1), math.abs(y2 - y1), 0.95,
            color.r, color.g, color.b)
    end
    return true
end

function Layer.Render(map)
    if not isVisible() or not map or not map.mapAPI then return end
    Layer.Update(false)
    local snapshot, settlement = snapshotAndSettlement()
    local geometry = settlement and settlement.geometry or nil
    local bounds = geometry and geometry.bounds or nil
    if not settlement or not numericBounds(bounds) then return end

    local mouseX = map.getMouseX and map:getMouseX() or 0
    local mouseY = map.getMouseY and map:getMouseY() or 0
    local markerAtMouse = TravelLayer and TravelLayer.FindMarkerAt
        and TravelLayer.FindMarkerAt(map, mouseX, mouseY, 3) or nil
    local hovered = not markerAtMouse
        and Layer.FindAt(map, mouseX, mouseY) ~= nil
    local color = COLORS.border
    drawBounds(map, bounds, color)

    local minX, minY, maxX, maxY = numericBounds(bounds)
    local centerX = (minX + maxX + 1) / 2
    local centerY = (minY + maxY + 1) / 2
    local screenX = map.mapAPI:worldToUIX(centerX, centerY)
    local screenY = map.mapAPI:worldToUIY(centerX, centerY)
    local size = hovered and 12 or 8
    map:drawRect(screenX - size / 2, screenY - size / 2, size, size,
        1, color.r, color.g, color.b)
    map:drawRectBorder(screenX - size / 2, screenY - size / 2,
        size, size, 1, 0.03, 0.03, 0.03)
    map:drawTextCentre(Presentation.Name(snapshot, settlement), screenX,
        screenY + 11, COLORS.label.r, COLORS.label.g, COLORS.label.b,
        1, UIFont.Small)
    if hovered then
        Presentation.DrawHover(map, snapshot, settlement,
            mouseX, mouseY, color)
    end
end

if Layers and Layers.Register then
    Layers.Register("pnc_player_settlement", {
        -- NPC travel dots render after this layer and retain hover priority.
        order = 95,
        isVisible = isVisible,
        render = Layer.Render,
    })
end

return Layer
