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
    segmentsOverride
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
    radius = tonumber(radius)
    if not radius or radius <= 0 then return end
    for i = 0, segments do
        angle = (i / segments) * math.pi * 2
        x = centerX + math.cos(angle) * radius
        y = centerY + math.sin(angle) * radius
        if previousX ~= nil
            and (not dashed or i % 2 == 0)
        then
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
        previousX = x
        previousY = y
    end
end

Internal.ScreenPoint = screenPoint
Internal.DrawWorldLine = drawWorldLine
Internal.DrawWorldMarker = drawWorldMarker
Internal.DrawWorldTile = drawWorldTile
Internal.DrawWorldCircle = drawWorldCircle

return Internal
