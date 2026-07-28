PNC = PNC or {}
PNC.NameplateRenderer = PNC.NameplateRenderer or {}

local Renderer = PNC.NameplateRenderer
local Presentation = PNC.NameplatePresentation
local Layout = Presentation.Layout
local Fonts = Presentation.Fonts

local DEBUG_COLOR = { r = 0.8, g = 0.9, b = 1.0, a = 1.0 }
local INFECTION_COLOR = { r = 1.0, g = 0.12, b = 0.08, a = 1.0 }
local PATH_COLOR = { r = 0.15, g = 0.82, b = 1.0, a = 0.82 }
local PATH_BLOCKED_COLOR = { r = 1.0, g = 0.3, b = 0.2, a = 0.9 }
local PATH_FINAL_COLOR = { r = 0.45, g = 0.72, b = 1.0, a = 0.42 }
local PATH_MARKER_HALF_SIZE = 15
local PATH_FINAL_MARKER_HALF_SIZE = 8

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

local function drawHealth(manager, entry, metrics, barLeft, barTop, alpha)
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
    local lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    if entry.debugText and entry.debugText ~= "" then
        Presentation.DrawOutlinedText(
            manager,
            entry.debugText,
            screenX - ((entry.debugTextWidth or 0) / 2),
            y,
            DEBUG_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    if entry.infectionDebugText and entry.infectionDebugText ~= "" then
        Presentation.DrawOutlinedText(
            manager,
            entry.infectionDebugText,
            screenX - ((entry.infectionDebugTextWidth or 0) / 2),
            y,
            INFECTION_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    return y
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

local function drawLive(manager, entry, metrics, currentTime, showDebug)
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

    if entry.treatmentVisible and entry.treatmentText ~= "" then
        local treatmentHeight = getTextManager():getFontHeight(Fonts.debug) + 2
        Presentation.DrawOutlinedText(
            manager,
            entry.treatmentText,
            screenX - ((entry.treatmentTextWidth or 0) / 2),
            nameY - treatmentHeight,
            entry.treatmentColor,
            0.95 * alpha,
            Fonts.debug
        )
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
    drawHealth(manager, entry, metrics, barLeft, barTop, alpha)
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

local function rounded(value, digits)
    local number = tonumber(value)
    local scale
    if number == nil then return nil end
    scale = 10 ^ (digits or 2)
    return tostring(math.floor(number * scale + 0.5) / scale)
end

function Renderer.BuildPathDebugLines(debugState, currentFinalDistance)
    local lines = {}
    local policy
    local provider
    local route
    local movement
    local diagnostic
    local pathIndex
    local pathLength
    local steeringIndex
    local goalDistance
    local finalDistance
    local turnDot
    local turnDegrees
    if type(debugState) ~= "table" then return lines end
    policy = tostring(debugState.navigationPolicy or "unknown")
    provider = tostring(debugState.navigationProvider or "unknown")
    route = tostring(
        debugState.navigationPlanReason
            or debugState.navigationSteeringKind
            or "direct"
    )
    pathIndex = tonumber(debugState.navigationPathIndex)
    steeringIndex = tonumber(
        debugState.navigationSteeringIndex
    )
    pathLength = tonumber(debugState.navigationPathLength) or 0
    if pathIndex and pathLength > 0 then
        route = route .. " wp=" .. tostring(pathIndex)
            .. "/" .. tostring(pathLength)
        if steeringIndex and steeringIndex ~= pathIndex then
            route = route .. " aim=" .. tostring(steeringIndex)
        end
    elseif debugState.navigationSteeringKind then
        route = route .. " " .. tostring(
            debugState.navigationSteeringKind
        )
    end
    if debugState.navigationTraversalKind then
        route = route .. " edge="
            .. tostring(debugState.navigationTraversalKind)
    end
    lines[#lines + 1] = "NAV " .. policy .. "/" .. provider
        .. " | " .. route

    goalDistance = rounded(debugState.moveGoalDistance, 2)
    finalDistance = rounded(
        currentFinalDistance or debugState.moveFinalDistance,
        2
    )
    movement = tostring(debugState.movePhase or "idle")
        .. "/" .. tostring(debugState.moveMode or "-")
        .. " step=" .. tostring(debugState.moveLastStep or "-")
    if goalDistance then movement = movement .. " goal=" .. goalDistance end
    if finalDistance then movement = movement .. " final=" .. finalDistance end
    movement = movement .. " np="
        .. tostring(tonumber(debugState.moveNonProgressSteps) or 0)
    if (tonumber(debugState.moveRetargetCount) or 0) > 0 then
        movement = movement .. " rt="
            .. tostring(tonumber(debugState.moveRetargetCount) or 0)
    end
    turnDot = tonumber(debugState.moveSteeringTurnDot)
    if turnDot then
        turnDot = math.max(-1, math.min(1, turnDot))
        turnDegrees = math.floor(
            math.deg(math.acos(turnDot)) + 0.5
        )
        movement = movement .. " turn="
            .. tostring(turnDegrees)
    end
    lines[#lines + 1] = movement

    if debugState.moveBlockReason
        or debugState.moveBlockedStepReason
        or (tonumber(debugState.navigationPlanFailures) or 0) > 0
        or debugState.navigationInvalidationReason
    then
        diagnostic = "DIAG block="
            .. tostring(
                debugState.moveBlockReason
                    or debugState.moveBlockedStepReason
                    or "-"
            )
            .. " failures="
            .. tostring(
                tonumber(debugState.navigationPlanFailures) or 0
            )
        if debugState.navigationInvalidationReason then
            diagnostic = diagnostic .. " replan="
                .. tostring(debugState.navigationInvalidationReason)
        end
        lines[#lines + 1] = diagnostic
    end
    return lines
end

local function drawPathGoal(manager, entry)
    local zombie = entry.zombie
    local debugState = entry.snapshot and (
        entry.snapshot.pathDebugState
            or entry.snapshot.debugState
    )
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
    local finalGoal = debugState.moveFinalGoal
    local finalX = finalGoal and tonumber(finalGoal.x) or nil
    local finalY = finalGoal and tonumber(finalGoal.y) or nil
    local finalZ = finalGoal and tonumber(finalGoal.z) or nil
    local finalScreenX
    local finalScreenY
    local lines
    local lineHeight
    local labelX
    local labelY
    local textWidth
    local textColor
    local currentFinalDistance
    local i

    if finalX and finalY and finalZ then
        currentFinalDistance = math.sqrt(
            ((finalX - worldX) * (finalX - worldX))
                + ((finalY - worldY) * (finalY - worldY))
        )
    end

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
    if finalX and finalY and finalZ
        and (
            math.abs(finalX - goalX) > 0.05
            or math.abs(finalY - goalY) > 0.05
            or math.abs(finalZ - goalZ) > 0.05
        )
    then
        finalScreenX = isoToScreenX(
            manager.playerIndex,
            finalX,
            finalY,
            finalZ
        ) - manager.x
        finalScreenY = isoToScreenY(
            manager.playerIndex,
            finalX,
            finalY,
            finalZ
        ) - manager.y
        manager:drawLine2(
            endX,
            endY,
            finalScreenX,
            finalScreenY,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
        manager:drawLine2(
            finalScreenX - PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenY,
            finalScreenX + PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenY,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
        manager:drawLine2(
            finalScreenX,
            finalScreenY - PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenX,
            finalScreenY + PATH_FINAL_MARKER_HALF_SIZE,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
    end

    lines = Renderer.BuildPathDebugLines(
        debugState,
        currentFinalDistance
    )
    lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    labelX = (startX + endX) / 2
    labelY = math.min(startY, endY)
        - (#lines * lineHeight)
        - 4
    textColor = debugState.moveBlockReason
        and PATH_BLOCKED_COLOR or PATH_COLOR
    for i = 1, #lines do
        textWidth = getTextManager():MeasureStringX(
            Fonts.debug,
            lines[i]
        )
        Presentation.DrawOutlinedText(
            manager,
            lines[i],
            labelX - (textWidth / 2),
            labelY + ((i - 1) * lineHeight),
            textColor,
            1,
            Fonts.debug
        )
    end
end

function Renderer.Render(manager, settings)
    if not settings.enabled or not manager.player then
        manager:clearStencilRect()
        return
    end

    local metrics = Presentation.ScaleFor(manager.playerIndex)
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
            drawLive(manager, entry, metrics, currentTime, settings.showAIDebug)
        end
    end
    manager:clearStencilRect()
end

return Renderer
