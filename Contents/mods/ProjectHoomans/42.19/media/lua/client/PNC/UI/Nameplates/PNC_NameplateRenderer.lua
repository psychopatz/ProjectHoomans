PNC = PNC or {}
PNC.NameplateRenderer = PNC.NameplateRenderer or {}

local Renderer = PNC.NameplateRenderer
local Presentation = PNC.NameplatePresentation
local Layout = Presentation.Layout
local Fonts = Presentation.Fonts

local DEBUG_COLOR = { r = 0.8, g = 0.9, b = 1.0, a = 1.0 }
local PATH_COLOR = { r = 0.15, g = 0.82, b = 1.0, a = 0.82 }
local PATH_BLOCKED_COLOR = { r = 1.0, g = 0.3, b = 0.2, a = 0.9 }
local PATH_MARKER_HALF_SIZE = 4

local function drawStatusBar(manager, left, top, width, height, ratio, color, alpha, backgroundAlpha)
    manager:drawRect(
        left - Layout.padding,
        top - Layout.padding,
        width + (Layout.padding * 2),
        height + (Layout.padding * 2),
        backgroundAlpha * alpha,
        0,
        0,
        0
    )
    manager:drawRect(left, top, width * ratio, height, color.a * alpha, color.r, color.g, color.b)
    manager:drawRectBorder(
        left - Layout.padding,
        top - Layout.padding,
        width + (Layout.padding * 2),
        height + (Layout.padding * 2),
        alpha,
        math.min(1, color.r + 0.08),
        math.min(1, color.g + 0.08),
        math.min(1, color.b + 0.08)
    )
end

local function healthTextColor(healthRatio)
    if healthRatio < 0.25 then
        return { r = 0.8, g = 0.1, b = 0.1, a = 1.0 }
    end
    if healthRatio < 0.6 then
        return { r = 0.8, g = 0.8, b = 0.1, a = 1.0 }
    end
    return { r = 0.1, g = 0.8, b = 0.1, a = 1.0 }
end

local function drawHealth(manager, entry, metrics, screenX, barLeft, barTop, alpha, heartIcon)
    if not entry.healthVisible then return end
    drawStatusBar(
        manager,
        barLeft,
        barTop,
        metrics.barWidth,
        metrics.barHeight,
        entry.healthRatio,
        entry.barColor,
        alpha,
        0.55
    )

    local totalWidth = metrics.heartIconSize + metrics.heartIconGap + (entry.hpTextWidth or 0)
    local counterX = screenX - (totalWidth / 2)
    local counterY = barTop - (Layout.hpTextTopGap / metrics.zoom)
    if heartIcon then
        manager:drawTextureScaled(
            heartIcon,
            counterX,
            counterY + (2 / metrics.zoom),
            metrics.heartIconSize,
            metrics.heartIconSize,
            alpha,
            1,
            1,
            1
        )
    end
    Presentation.DrawOutlinedText(
        manager,
        entry.hpText,
        counterX + metrics.heartIconSize + metrics.heartIconGap,
        counterY,
        healthTextColor(entry.healthRatio),
        alpha,
        Fonts.hp
    )
end

local function drawStamina(manager, entry, metrics, barLeft, barTop, alpha)
    if not entry.staminaVisible then return nil end
    local top = entry.healthVisible
        and (barTop + metrics.barHeight + (6 / metrics.zoom)) or barTop
    drawStatusBar(
        manager,
        barLeft,
        top,
        metrics.barWidth,
        metrics.barHeight,
        entry.staminaRatio,
        entry.staminaColor,
        alpha,
        0.48
    )
    return top
end

local function drawDebugText(manager, entry, screenX, y, alpha)
    Presentation.DrawOutlinedText(
        manager,
        entry.debugText,
        screenX - ((entry.debugTextWidth or 0) / 2),
        y,
        DEBUG_COLOR,
        alpha,
        Fonts.debug
    )
end

local function drawDebugOnly(manager, entry, metrics)
    local screenX = isoToScreenX(manager.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - manager.x
    local screenY = isoToScreenY(manager.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - manager.y
    local nameY = screenY - metrics.nameYOffset
    Presentation.DrawOutlinedText(
        manager,
        entry.name,
        screenX - ((entry.nameWidth or 0) / 2),
        nameY,
        entry.nameColor,
        0.9,
        Fonts.name
    )
    drawDebugText(manager, entry, screenX, nameY + Layout.nameDebugGap, 0.9)
end

local function drawLive(manager, entry, metrics, currentTime, heartIcon, showDebug)
    local zombie = entry.zombie
    if not zombie or zombie:isDead() then return end
    local alpha = zombie.getAlpha and zombie:getAlpha(manager.playerIndex) or 1
    if alpha <= 0 then return end

    local screenX = isoToScreenX(manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - manager.x
    local screenY = isoToScreenY(manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - manager.y
    local nameY = screenY - metrics.nameYOffset
    local barLeft = screenX - (metrics.barWidth / 2)
    local barTop = screenY - metrics.barYOffset
    if entry.snapshot.healthState == "incapacitated" then
        entry.barColor = Presentation.IncapacitatedColor(currentTime)
    end

    Presentation.DrawOutlinedText(
        manager,
        entry.name,
        screenX - ((entry.nameWidth or 0) / 2),
        nameY,
        entry.nameColor,
        entry.nameColor.a * alpha,
        Fonts.name
    )
    drawHealth(manager, entry, metrics, screenX, barLeft, barTop, alpha, heartIcon)
    local staminaTop = drawStamina(manager, entry, metrics, barLeft, barTop, alpha)

    if showDebug then
        local debugY
        if entry.staminaVisible then
            debugY = (entry.healthVisible and staminaTop or barTop) + metrics.barHeight + Layout.debugTextGap
        elseif entry.healthVisible then
            debugY = barTop + metrics.barHeight + Layout.debugTextGap
        else
            debugY = nameY + Layout.nameDebugGap
        end
        drawDebugText(manager, entry, screenX, debugY, 0.95 * alpha)
    end
end

local function drawPathGoal(manager, entry)
    local zombie = entry.zombie
    local debugState = entry.snapshot and entry.snapshot.debugState
    local goal = debugState and debugState.moveGoal
    if not zombie or zombie:isDead() or type(goal) ~= "table" then return end

    local goalX = tonumber(goal.x)
    local goalY = tonumber(goal.y)
    local goalZ = tonumber(goal.z)
    if not goalX or not goalY or not goalZ then return end

    local worldX = zombie:getX()
    local worldY = zombie:getY()
    local worldZ = zombie:getZ()
    local startX = isoToScreenX(manager.playerIndex, worldX, worldY, worldZ) - manager.x
    local startY = isoToScreenY(manager.playerIndex, worldX, worldY, worldZ) - manager.y
    local endX = isoToScreenX(manager.playerIndex, goalX, goalY, goalZ) - manager.x
    local endY = isoToScreenY(manager.playerIndex, goalX, goalY, goalZ) - manager.y
    local color = debugState.moveBlockReason and PATH_BLOCKED_COLOR or PATH_COLOR

    manager:drawLine2(startX, startY, endX, endY, color.a, color.r, color.g, color.b)
    manager:drawLine2(
        endX - PATH_MARKER_HALF_SIZE,
        endY,
        endX + PATH_MARKER_HALF_SIZE,
        endY,
        color.a,
        color.r,
        color.g,
        color.b
    )
    manager:drawLine2(
        endX,
        endY - PATH_MARKER_HALF_SIZE,
        endX,
        endY + PATH_MARKER_HALF_SIZE,
        color.a,
        color.r,
        color.g,
        color.b
    )
end

function Renderer.Render(manager, settings)
    if not settings.enabled or not manager.player then
        manager:clearStencilRect()
        return
    end

    local metrics = Presentation.ScaleFor(manager.playerIndex)
    local heartIcon = Presentation.GetHeartTexture()
    local currentTime = getTimeInMillis()
    if settings.showPathDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly then drawPathGoal(manager, entry) end
        end
    end
    for _, entry in pairs(manager.entries) do
        if entry.debugOnly then
            drawDebugOnly(manager, entry, metrics)
        else
            drawLive(manager, entry, metrics, currentTime, heartIcon, settings.showAIDebug)
        end
    end
    manager:clearStencilRect()
end

return Renderer
