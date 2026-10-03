local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts

local PATH_COLOR = { r = 0.15, g = 0.82, b = 1.0, a = 0.82 }
local PATH_BLOCKED_COLOR = { r = 1.0, g = 0.3, b = 0.2, a = 0.9 }
local PATH_FINAL_COLOR = { r = 0.45, g = 0.72, b = 1.0, a = 0.42 }
local PATH_MARKER_HALF_SIZE = 15
local PATH_FINAL_MARKER_HALF_SIZE = 8

local function drawPathGeometry(manager, zombie, goal, debugState)
    local worldX = zombie:getX()
    local worldY = zombie:getY()
    local worldZ = zombie:getZ()
    local goalX = tonumber(goal.x)
    local goalY = tonumber(goal.y)
    local goalZ = tonumber(goal.z)
    local startX = isoToScreenX(
        manager.playerIndex, worldX, worldY, worldZ
    ) - manager.x
    local startY = isoToScreenY(
        manager.playerIndex, worldX, worldY, worldZ
    ) - manager.y
    local endX = isoToScreenX(
        manager.playerIndex, goalX, goalY, goalZ
    ) - manager.x
    local endY = isoToScreenY(
        manager.playerIndex, goalX, goalY, goalZ
    ) - manager.y
    local color = debugState.moveBlockReason
        and PATH_BLOCKED_COLOR or PATH_COLOR
    local finalGoal = debugState.moveFinalGoal
    local finalX = finalGoal and tonumber(finalGoal.x) or nil
    local finalY = finalGoal and tonumber(finalGoal.y) or nil
    local finalZ = finalGoal and tonumber(finalGoal.z) or nil
    local currentFinalDistance
    if finalX and finalY and finalZ then
        currentFinalDistance = math.sqrt(
            ((finalX - worldX) * (finalX - worldX))
                + ((finalY - worldY) * (finalY - worldY))
        )
    end
    manager:drawLine2(startX, startY, endX, endY,
        color.a, color.r, color.g, color.b)
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
        local finalScreenX = isoToScreenX(
            manager.playerIndex,
            finalX,
            finalY,
            finalZ
        ) - manager.x
        local finalScreenY = isoToScreenY(
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
    return startX, startY, endX, endY, currentFinalDistance
end

local function drawPathLabels(manager, lines, startX, startY, endX, endY,
    debugState)
    local lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local labelX = (startX + endX) / 2
    local labelY = math.min(startY, endY)
        - (#lines * lineHeight)
        - 4
    local textColor = debugState.moveBlockReason
        and PATH_BLOCKED_COLOR or PATH_COLOR
    for index = 1, #lines do
        local textWidth = getTextManager():MeasureStringX(
            Fonts.debug,
            lines[index]
        )
        Presentation.DrawOutlinedText(
            manager,
            lines[index],
            labelX - (textWidth / 2),
            labelY + ((index - 1) * lineHeight),
            textColor,
            1,
            Fonts.debug
        )
    end
end

local function drawPathGoal(manager, entry)
    local zombie = entry.zombie
    local debugState = entry.snapshot and (
        entry.snapshot.pathDebugState
            or entry.snapshot.debugState
    )
    local goal = debugState and debugState.moveGoal
    if not zombie or zombie:isDead() or type(goal) ~= 'table' then return end
    if not tonumber(goal.x) or not tonumber(goal.y) or not tonumber(goal.z) then
        return
    end
    local startX, startY, endX, endY, currentFinalDistance = drawPathGeometry(
        manager,
        zombie,
        goal,
        debugState
    )
    local lines = Renderer.BuildPathDebugLines(
        debugState,
        currentFinalDistance
    )
    drawPathLabels(
        manager,
        lines,
        startX,
        startY,
        endX,
        endY,
        debugState
    )
end

Internal.DrawPathGoal = drawPathGoal

return Renderer
