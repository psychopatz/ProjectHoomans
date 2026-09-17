-- Drawing and screen-space helpers for the perception debug overlay.
-- This module is deliberately stateless so future perception layers can reuse
-- the same world-to-screen and hover primitives without duplicating UI code.
require "ISUI/ISUIElement"

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Primitives = PNC.PerceptionDebug.OverlayPrimitives or {}
PNC.PerceptionDebug.OverlayPrimitives = Primitives

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

Primitives.Number = number

local function screenBounds(index)
    local left = type(getPlayerScreenLeft) == "function"
        and getPlayerScreenLeft(index) or 0
    local top = type(getPlayerScreenTop) == "function"
        and getPlayerScreenTop(index) or 0
    local width = type(getPlayerScreenWidth) == "function"
        and getPlayerScreenWidth(index) or nil
    local height = type(getPlayerScreenHeight) == "function"
        and getPlayerScreenHeight(index) or nil
    if not width or not height then
        local core = type(getCore) == "function" and getCore() or nil
        width = core and core:getScreenWidth() or 1920
        height = core and core:getScreenHeight() or 1080
    end
    return tonumber(left) or 0, tonumber(top) or 0,
        tonumber(width) or 1920, tonumber(height) or 1080
end

function Primitives.DrawerFor(overlay, index)
    if not ISUIElement or type(ISUIElement.new) ~= "function" then
        return nil
    end
    local x, y, width, height = screenBounds(index)
    local drawer = overlay.drawer
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        if drawer.setCapture then drawer:setCapture(false) end
        overlay.drawer = drawer
    else
        drawer:setX(x)
        drawer:setY(y)
        drawer:setWidth(width)
        drawer:setHeight(height)
    end
    return drawer
end

function Primitives.Point(drawer, index, x, y, z)
    if type(isoToScreenX) ~= "function"
        or type(isoToScreenY) ~= "function"
    then return nil end
    local screenX = isoToScreenX(index, x, y, z)
    local screenY = isoToScreenY(index, x, y, z)
    if screenX == nil or screenY == nil then return nil end
    return screenX - (number(drawer.x) or 0),
        screenY - (number(drawer.y) or 0)
end

function Primitives.WorldLine(drawer, index, x1, y1, z1, x2, y2, z2, color)
    if not drawer or type(drawer.drawLine2) ~= "function" then return end
    local sx1, sy1 = Primitives.Point(drawer, index, x1, y1, z1)
    local sx2, sy2 = Primitives.Point(drawer, index, x2, y2, z2)
    if not sx1 or not sy1 or not sx2 or not sy2 then return end
    drawer:drawLine2(sx1, sy1, sx2, sy2, color.a, color.r,
        color.g, color.b)
end

function Primitives.WorldMarker(drawer, index, x, y, z, color, size)
    local sx, sy = Primitives.Point(drawer, index, x, y, z)
    if not sx or not sy or type(drawer.drawLine2) ~= "function" then return end
    size = number(size) or 7
    drawer:drawLine2(sx - size, sy, sx + size, sy, color.a,
        color.r, color.g, color.b)
    drawer:drawLine2(sx, sy - size, sx, sy + size, color.a,
        color.r, color.g, color.b)
end

function Primitives.WorldTile(drawer, index, x, y, z, color)
    x, y, z = math.floor(number(x) or 0), math.floor(number(y) or 0),
        number(z) or 0
    Primitives.WorldLine(drawer, index, x, y, z, x + 1, y, z, color)
    Primitives.WorldLine(drawer, index, x + 1, y, z, x + 1, y + 1, z, color)
    Primitives.WorldLine(drawer, index, x + 1, y + 1, z, x, y + 1, z, color)
    Primitives.WorldLine(drawer, index, x, y + 1, z, x, y, z, color)
end

function Primitives.WorldCircle(drawer, index, x, y, z, radius, color)
    radius = number(radius)
    if not radius or radius <= 0 then return end
    local segments = math.max(12, math.floor(math.min(48, radius * 2)))
    local previousX, previousY
    for segment = 0, segments do
        local angle = segment / segments * math.pi * 2
        local worldX = x + math.cos(angle) * radius
        local worldY = y + math.sin(angle) * radius
        if previousX then
            Primitives.WorldLine(drawer, index, previousX, previousY, z,
                worldX, worldY, z, color)
        end
        previousX, previousY = worldX, worldY
    end
end

function Primitives.ObjectPoint(drawer, index, object)
    return Primitives.Point(drawer, index,
        (number(object and object.x) or 0) + 0.5,
        (number(object and object.y) or 0) + 0.5,
        number(object and object.z) or 0)
end

function Primitives.HoveredWorld(drawer, index, object, mouseX, mouseY)
    local sx, sy = Primitives.ObjectPoint(drawer, index, object)
    if not sx or not sy then return nil end
    local dx, dy = mouseX - sx, mouseY - sy
    local xStep = 16
    if type(isoToScreenX) == "function" then
        local x = number(object.x) or 0
        local y = number(object.y) or 0
        local z = number(object.z) or 0
        local base = isoToScreenX(index, x, y, z)
        local nextX = isoToScreenX(index, x + 1, y, z)
        local nextY = isoToScreenX(index, x, y + 1, z)
        if base and nextX and nextY then
            xStep = math.max(8, math.abs(nextX - base),
                math.abs(nextY - base))
        end
    end
    local size = math.max(14, xStep * 1.5)
    if math.abs(dx) <= size and math.abs(dy) <= size then
        return dx * dx + dy * dy
    end
    return nil
end

function Primitives.DrawText(drawer, value, x, y, color, font)
    if not drawer or type(drawer.drawText) ~= "function" then return end
    drawer:drawText(tostring(value or ""), x, y, color.r, color.g,
        color.b, color.a or 1, font or UIFont.Small)
end

function Primitives.DrawLabel(drawer, index, x, y, z, value, color, offsetY)
    if value == nil or value == "" then return end
    local sx, sy = Primitives.Point(drawer, index, x, y, z)
    if not sx or not sy then return end
    local width = math.max(80, #tostring(value) * 7 + 14)
    local left = math.max(4, math.min((drawer.width or 1920) - width - 4,
        sx - width / 2))
    local top = math.max(4, sy - (number(offsetY) or 22))
    if drawer.drawRect then
        drawer:drawRect(left, top, width, 20, 0.84, 0.02, 0.04, 0.07)
    end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(left, top, width, 20, 0.92,
            color.r, color.g, color.b)
    end
    Primitives.DrawText(drawer, value, left + 7, top + 3, {
        r = 1, g = 1, b = 1, a = 1,
    })
end

function Primitives.DrawRoomZone(drawer, index, zone, color)
    local bounds = zone and zone.roomBounds or nil
    if not bounds or type(addAreaHighlightForPlayer) ~= "function" then return end
    local minX, minY = number(bounds.minX), number(bounds.minY)
    local maxX, maxY = number(bounds.maxX), number(bounds.maxY)
    if not minX or not minY or not maxX or not maxY then return end
    addAreaHighlightForPlayer(index, minX, minY, maxX + 1, maxY + 1,
        number(zone.z) or number(bounds.z) or 0,
        color.r, color.g, color.b, color.a)
end

function Primitives.DrawCampZone(drawer, index, zone, color)
    if not zone then return end
    Primitives.WorldCircle(drawer, index, number(zone.x) or 0,
        number(zone.y) or 0, number(zone.z) or 0,
        number(zone.radius) or 16, color)
    Primitives.WorldMarker(drawer, index, number(zone.x) or 0,
        number(zone.y) or 0, number(zone.z) or 0, color, 9)
end

return Primitives
