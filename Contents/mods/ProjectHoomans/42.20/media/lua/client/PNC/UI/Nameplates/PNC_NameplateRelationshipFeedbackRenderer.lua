-- Reusable world-space relationship feedback display.  This module only
-- draws a short-lived record supplied by the relationship feedback pipe.
PNC = PNC or {}
PNC.NameplateRelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer or {}

local Renderer = PNC.NameplateRelationshipFeedbackRenderer
local Feedback = PNC.NameplateRelationshipFeedback
local Presentation = PNC.NameplatePresentation

local UP_COLOR = { r = 0.18, g = 1.0, b = 0.30, a = 1.0 }
local DOWN_COLOR = { r = 1.0, g = 0.22, b = 0.18, a = 1.0 }
local OUTLINE_COLOR = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }

local function rounded(value)
    value = tonumber(value) or 0
    return math.floor(value * 10 + (value < 0 and -0.5 or 0.5)) / 10
end

local function signed(value)
    value = rounded(value)
    return (value > 0 and "+" or "") .. tostring(value)
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
    local scale = 1 / zoom
    local size = math.max(8, math.floor((12 * scale) + 0.5))
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
        Presentation.DrawOutlinedText(
            manager,
            signed(feedback.score),
            x + (size * 0.5) + (3 * scale),
            top - (2 * scale),
            color,
            alpha,
            Presentation.Fonts and Presentation.Fonts.debug or UIFont.Small
        )
    end
    return true
end

Renderer.Colors = {
    up = UP_COLOR,
    down = DOWN_COLOR,
}

return Renderer
