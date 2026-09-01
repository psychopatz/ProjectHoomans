local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts

local PATH_COLOR = { r = 0.15, g = 0.82, b = 1.0, a = 0.82 }
local PATH_BLOCKED_COLOR = { r = 1.0, g = 0.3, b = 0.2, a = 0.9 }
local PATH_FINAL_COLOR = { r = 0.45, g = 0.72, b = 1.0, a = 0.42 }
local PATH_MARKER_HALF_SIZE = 15
local PATH_FINAL_MARKER_HALF_SIZE = 8

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

Internal.DrawPathGoal = drawPathGoal

return Renderer
