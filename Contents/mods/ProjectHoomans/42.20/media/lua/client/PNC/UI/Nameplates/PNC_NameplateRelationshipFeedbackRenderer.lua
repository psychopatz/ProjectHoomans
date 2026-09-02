-- Reusable world-space relationship feedback display.  This module only
-- draws a short-lived record supplied by the relationship feedback pipe.
PNC = PNC or {}
PNC.NameplateRelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer or {}

local Renderer = PNC.NameplateRelationshipFeedbackRenderer
local Feedback = PNC.NameplateRelationshipFeedback
local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

local UP_COLOR = { r = 0.18, g = 1.0, b = 0.30, a = 1.0 }
local DOWN_COLOR = { r = 1.0, g = 0.22, b = 0.18, a = 1.0 }
local OUTLINE_COLOR = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }

Renderer.ARROW_SIZE = 12
Renderer.MIN_ARROW_SIZE = 4

local RELATIONSHIP_AXES = {
    {
        key = "approval",
        labelKey = "UI_PNC_RelationshipApproval",
        fallback = "Approval",
    },
    {
        key = "respect",
        labelKey = "UI_PNC_RelationshipRespect",
        fallback = "Respect",
    },
    {
        key = "familiarity",
        labelKey = "UI_PNC_RelationshipFamiliarity",
        fallback = "Familiarity",
    },
}

local function rounded(value)
    value = tonumber(value) or 0
    return math.floor(value * 10 + (value < 0 and -0.5 or 0.5)) / 10
end

local function signed(value)
    value = rounded(value)
    return (value > 0 and "+" or "") .. tostring(value)
end

local function translated(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then
        return value
    end
    return fallback
end

local function relationshipDetails(feedback)
    local details = {}
    local delta = feedback and feedback.delta or nil
    local index
    local axis
    local value
    for index = 1, #RELATIONSHIP_AXES do
        axis = RELATIONSHIP_AXES[index]
        value = tonumber(delta and delta[axis.key]) or 0
        if math.abs(value) > 0.05 then
            details[#details + 1] = translated(axis.labelKey, axis.fallback)
                .. " " .. signed(value)
        end
    end
    if #details == 0 then
        details[1] = translated(
            "UI_PNC_RelationshipChange",
            "Relationship"
        ) .. " " .. signed(feedback and feedback.score or 0)
    end
    return details
end

local function detailFont(scale)
    if DisplaySettings and DisplaySettings.GetRelationshipFeedbackFont then
        return DisplaySettings.GetRelationshipFeedbackFont()
    end
    if Presentation and Presentation.Fonts then
        return Presentation.Fonts.relationship
            or Presentation.Fonts.name
            or Presentation.Fonts.debug
    end
    return UIFont and (UIFont.Medium or UIFont.Small) or nil
end

local function detailLineHeight(font)
    if getTextManager then
        local textManager = getTextManager()
        if textManager and textManager.getFontHeight then
            local height = tonumber(textManager:getFontHeight(font))
            if height and height > 0 then return height end
        end
    end
    return 16
end

local function line(manager, x1, y1, x2, y2, color, alpha, size)
    local extra = tonumber(size) or 0
    if extra > 0 then
        manager:drawLine2(x1 - extra, y1, x2 - extra, y2,
            color.a * alpha, color.r, color.g, color.b)
        manager:drawLine2(x1 + extra, y1, x2 + extra, y2,
            color.a * alpha, color.r, color.g, color.b)
    end
    manager:drawLine2(x1, y1, x2, y2,
        color.a * alpha, color.r, color.g, color.b)
end

local function drawArrow(manager, x, y, size, direction, color, alpha)
    local half = size * 0.5
    local wingY = y + size * 0.42
    local stemBottom = y + size
    local outlineSize = math.max(1, math.floor(size * 0.08 + 0.5))
    local stemWidth = math.max(2, math.floor(size * 0.16 + 0.5))
    local stemX = x - (stemWidth * 0.5)
    if direction == "up" then
        line(manager, x, y, x - half, wingY,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, y, x + half, wingY,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, wingY, x, stemBottom,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, y, x - half, wingY, color, alpha, 0)
        line(manager, x, y, x + half, wingY, color, alpha, 0)
        line(manager, x, wingY, x, stemBottom, color, alpha, 0)
    else
        line(manager, x, stemBottom, x - half, y + size * 0.58,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, stemBottom, x + half, y + size * 0.58,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, y, x, y + size * 0.58,
            OUTLINE_COLOR, alpha, outlineSize)
        line(manager, x, stemBottom, x - half, y + size * 0.58,
            color, alpha, 0)
        line(manager, x, stemBottom, x + half, y + size * 0.58,
            color, alpha, 0)
        line(manager, x, y, x, y + size * 0.58, color, alpha, 0)
    end
    manager:drawRect(stemX, y + size * 0.28,
        stemWidth, math.max(2, math.floor(size * 0.55 + 0.5)),
        color.a * alpha, color.r, color.g, color.b)
end

function Renderer.Draw(manager, npcID, screenX, nameY, options)
    if not manager or not manager.drawLine2 or not manager.drawRect then
        return false
    end
    options = type(options) == "table" and options or {}
    local feedback = Feedback and Feedback.Get
        and Feedback.Get(npcID, options.currentTime) or nil
    if not feedback then return false end
    local zoom = math.max(1, tonumber(options.zoom) or 1)
    local feedbackScale = DisplaySettings
        and DisplaySettings.GetRelationshipFeedbackScale
        and DisplaySettings.GetRelationshipFeedbackScale() or 1
    local scale = feedbackScale / zoom
    local size = math.max(Renderer.MIN_ARROW_SIZE,
        math.floor((Renderer.ARROW_SIZE * scale) + 0.5))
    local nameWidth = tonumber(options.nameWidth) or 0
    local alpha = (tonumber(options.alpha) or 1)
        * (tonumber(feedback.alpha) or 1)
    local float = (tonumber(feedback.progress) or 0) * 6 * scale
    local top = (tonumber(nameY) or 0)
        + (feedback.direction == "up" and -float or float)
    local x = (tonumber(screenX) or 0) + (nameWidth * 0.5)
        + (8 * scale)
    local color = feedback.direction == "up" and UP_COLOR or DOWN_COLOR
    drawArrow(manager, x, top, size, feedback.direction, color, alpha)
    if options.showMagnitude ~= false and manager.drawText
        and Presentation and Presentation.DrawOutlinedText
    then
        local details = relationshipDetails(feedback)
        local font = detailFont(feedbackScale)
        local lineHeight = detailLineHeight(font)
        local detailTop = top
            - (((#details - 1) * lineHeight) * 0.5)
            - (2 * scale)
        local detailX = x + (size * 0.5) + (5 * scale)
        local index
        for index = 1, #details do
            Presentation.DrawOutlinedText(
                manager,
                details[index],
                detailX,
                detailTop + ((index - 1) * lineHeight),
                color,
                alpha,
                font
            )
        end
    end
    return true
end

Renderer.Colors = {
    up = UP_COLOR,
    down = DOWN_COLOR,
}

return Renderer
