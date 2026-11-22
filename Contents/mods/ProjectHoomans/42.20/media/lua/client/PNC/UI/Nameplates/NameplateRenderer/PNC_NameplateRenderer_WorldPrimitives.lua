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

local function drawScreenThickLine(
    manager,
    sx1,
    sy1,
    sx2,
    sy2,
    color,
    thickness,
    shadowAlpha
)
    local width = math.max(1, math.floor(tonumber(thickness) or 3))
    local shadow = shadowAlpha == nil and 0.72 or tonumber(shadowAlpha) or 0
    if width <= 1 then
        if shadow > 0 then
            manager:drawLine2(sx1, sy1 + 1, sx2, sy2 + 1, shadow, 0, 0, 0)
        end
        manager:drawLine2(sx1, sy1, sx2, sy2, color.a, color.r, color.g, color.b)
        return
    end
    local dx = sx2 - sx1
    local dy = sy2 - sy1
    local length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.001 then
        if shadow > 0 then
            manager:drawLine2(sx1, sy1 + 1, sx2, sy2 + 1, shadow, 0, 0, 0)
        end
        manager:drawLine2(sx1, sy1, sx2, sy2, color.a, color.r, color.g, color.b)
        return
    end
    local half = (width - 1) * 0.5
    local nx = -dy / length
    local ny = dx / length
    if shadow > 0 then
        local backOffset = half + 1
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
    drawScreenThickLine(
        manager,
        sx1,
        sy1,
        sx2,
        sy2,
        color,
        thickness,
        shadowAlpha
    )
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
    radius = tonumber(radius)
    if not radius or radius <= 0 then return end
    local segments = math.max(
        8,
        math.floor(tonumber(segmentsOverride) or 28)
    )
    local lineWidth = tonumber(thickness) or 1
    local stepAngle = (math.pi * 2) / segments
    local prevSx
    local prevSy
    local i
    for i = 0, segments do
        local angle = i * stepAngle
        local sx, sy = screenPoint(
            manager,
            centerX + math.cos(angle) * radius,
            centerY + math.sin(angle) * radius,
            z
        )
        if prevSx ~= nil and (not dashed or i % 2 == 0) then
            if lineWidth > 1 then
                drawScreenThickLine(
                    manager,
                    prevSx,
                    prevSy,
                    sx,
                    sy,
                    color,
                    lineWidth,
                    0.55
                )
            else
                manager:drawLine2(
                    prevSx,
                    prevSy,
                    sx,
                    sy,
                    color.a,
                    color.r,
                    color.g,
                    color.b
                )
            end
        end
        prevSx = sx
        prevSy = sy
    end
end

Internal.ScreenPoint = screenPoint
Internal.DrawWorldLine = drawWorldLine
Internal.DrawScreenThickLine = drawScreenThickLine
Internal.DrawWorldThickLine = drawWorldThickLine
Internal.DrawWorldMarker = drawWorldMarker
Internal.DrawWorldTile = drawWorldTile
Internal.DrawWorldCircle = drawWorldCircle

return Internal
