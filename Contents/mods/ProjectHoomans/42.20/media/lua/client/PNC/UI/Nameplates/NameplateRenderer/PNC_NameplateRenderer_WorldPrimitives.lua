local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local COMBAT_MARKER_HALF_SIZE = 9

local function screenPoint(manager, x, y, z)
    return isoToScreenX(manager.playerIndex, x, y, z) - manager.x,
        isoToScreenY(manager.playerIndex, x, y, z) - manager.y
end

local function drawWorldLine(manager, x1, y1, z1, x2, y2, z2, color)
    local sx1
    local sy1
    local sx2
    local sy2
    sx1, sy1 = screenPoint(manager, x1, y1, z1)
    sx2, sy2 = screenPoint(manager, x2, y2, z2)
    manager:drawLine2(
        sx1,
        sy1,
        sx2,
        sy2,
        color.a,
        color.r,
        color.g,
        color.b
    )
end

local function drawWorldThickLine(
    manager,
    x1,
    y1,
    z1,
    x2,
    y2,
    z2,
    color,
    thickness,
    shadowAlpha
)
    local sx1, sy1 = screenPoint(manager, x1, y1, z1)
    local sx2, sy2 = screenPoint(manager, x2, y2, z2)
    local dx = sx2 - sx1
    local dy = sy2 - sy1
    local length = math.sqrt((dx * dx) + (dy * dy))
    local width = math.max(1, math.floor(tonumber(thickness) or 3))
    local half = (width - 1) * 0.5
    local nx = 0
    local ny = 0
    local shadow = shadowAlpha == nil and 0.72 or tonumber(shadowAlpha) or 0
    if length > 0.001 then
        nx = -dy / length
        ny = dx / length
    end
    if width <= 1 or length <= 0.001 then
        if shadow > 0 then
            manager:drawLine2(sx1, sy1 + 1, sx2, sy2 + 1, shadow, 0, 0, 0)
        end
        manager:drawLine2(sx1, sy1, sx2, sy2, color.a, color.r, color.g, color.b)
        return
    end
    if shadow > 0 then
        local backOffset = half + 1
        manager:drawLine2(
            sx1 - (nx * backOffset),
            sy1 - (ny * backOffset),
            sx2 - (nx * backOffset),
            sy2 - (ny * backOffset),
            shadow,
            0,
            0,
            0
        )
        manager:drawLine2(
            sx1 + (nx * backOffset),
            sy1 + (ny * backOffset),
            sx2 + (nx * backOffset),
            sy2 + (ny * backOffset),
            shadow,
            0,
            0,
            0
        )
    end
    local step
    for step = 0, width - 1 do
        local offset = step - half
        manager:drawLine2(
            sx1 + (nx * offset),
            sy1 + (ny * offset),
            sx2 + (nx * offset),
            sy2 + (ny * offset),
            color.a,
            color.r,
            color.g,
            color.b
        )
    end
end

local function drawWorldMarker(manager, x, y, z, color, size)
    local sx
    local sy
    size = tonumber(size) or COMBAT_MARKER_HALF_SIZE
    sx, sy = screenPoint(manager, x, y, z)
    manager:drawLine2(
        sx - size,
        sy,
        sx + size,
        sy,
        color.a,
        color.r,
        color.g,
        color.b
    )
    manager:drawLine2(
        sx,
        sy - size,
        sx,
        sy + size,
        color.a,
        color.r,
        color.g,
        color.b
    )
end

local function drawWorldTile(manager, x, y, z, color)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = tonumber(z) or 0
    drawWorldLine(manager, x, y, z, x + 1, y, z, color)
    drawWorldLine(manager, x + 1, y, z, x + 1, y + 1, z, color)
    drawWorldLine(manager, x + 1, y + 1, z, x, y + 1, z, color)
    drawWorldLine(manager, x, y + 1, z, x, y, z, color)
    if type(addAreaHighlightForPlayer) == "function" then
        addAreaHighlightForPlayer(
            manager.playerIndex,
            x, y, x + 1, y + 1, z,
            color.r, color.g, color.b, color.a
        )
    end
end

local function drawWorldCircle(
    manager,
    centerX,
    centerY,
    z,
    radius,
    color,
    dashed,
    segmentsOverride,
    thickness
)
    local segments = math.max(
        8,
        math.floor(tonumber(segmentsOverride) or 28)
    )
    local previousX
    local previousY
    local x
    local y
    local angle
    local i
    local lineWidth = tonumber(thickness) or 1
    radius = tonumber(radius)
    if not radius or radius <= 0 then return end
    for i = 0, segments do
        angle = (i / segments) * math.pi * 2
        x = centerX + math.cos(angle) * radius
        y = centerY + math.sin(angle) * radius
        if previousX ~= nil
            and (not dashed or i % 2 == 0)
        then
            if lineWidth > 1 then
                drawWorldThickLine(
                    manager,
                    previousX,
                    previousY,
                    z,
                    x,
                    y,
                    z,
                    color,
                    lineWidth,
                    0.55
                )
            else
                drawWorldLine(
                    manager,
                    previousX,
                    previousY,
                    z,
                    x,
                    y,
                    z,
                    color
                )
            end
        end
        previousX = x
        previousY = y
    end
end

Internal.ScreenPoint = screenPoint
Internal.DrawWorldLine = drawWorldLine
Internal.DrawWorldThickLine = drawWorldThickLine
Internal.DrawWorldMarker = drawWorldMarker
Internal.DrawWorldTile = drawWorldTile
Internal.DrawWorldCircle = drawWorldCircle

return Internal
