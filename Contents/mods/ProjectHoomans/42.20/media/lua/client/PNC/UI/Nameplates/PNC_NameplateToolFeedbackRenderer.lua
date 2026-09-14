-- World-space renderer for short-lived LLM command feedback.
-- It only consumes the normalized client record; it never executes commands
-- or touches the NPC animation state.
PNC = PNC or {}
PNC.NameplateToolFeedbackRenderer =
    PNC.NameplateToolFeedbackRenderer or {}

local Renderer = PNC.NameplateToolFeedbackRenderer
local Feedback = PNC.NameplateToolFeedback
local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

local COLORS = {
    accepted = { r = 0.22, g = 1.0, b = 0.42, a = 1.0 },
    queued = { r = 0.12, g = 0.88, b = 1.0, a = 1.0 },
    rejected = { r = 1.0, g = 0.55, b = 0.18, a = 1.0 },
}

local function lineHeight(font)
    if getTextManager then
        local manager = getTextManager()
        if manager and manager.getFontHeight then
            local height = tonumber(manager:getFontHeight(font))
            if height and height > 0 then return height end
        end
    end
    return 16
end

local function measure(text, font)
    if getTextManager then
        local manager = getTextManager()
        if manager and manager.MeasureStringX then
            return tonumber(manager:MeasureStringX(font, text)) or 0
        end
    end
    return #tostring(text or "") * 7
end

function Renderer.Draw(manager, npcID, screenX, nameY, options)
    if not manager or not manager.drawText
        or not Presentation or not Presentation.DrawOutlinedText
    then
        return false
    end
    options = type(options) == "table" and options or {}
    local feedback = Feedback and Feedback.Get
        and Feedback.Get(npcID, options.currentTime) or nil
    if not feedback then return false end
    local text = Feedback.GetDisplayText(feedback)
    if not text or text == "" then return false end
    local font = options.font
        or Presentation.Fonts and Presentation.Fonts.debug
    local scale = DisplaySettings
        and DisplaySettings.GetRelationshipFeedbackScale
        and DisplaySettings.GetRelationshipFeedbackScale() or 1
    local zoom = math.max(1, tonumber(options.zoom) or 1)
    local geometryScale = scale / zoom
    local width = tonumber(options.textWidth) or measure(text, font)
    local height = lineHeight(font)
    local y = tonumber(options.y)
        or ((tonumber(nameY) or 0) - height - (4 * geometryScale))
    local x = (tonumber(screenX) or 0) - (width * 0.5)
    local alpha = (tonumber(options.alpha) or 1)
        * (tonumber(feedback.alpha) or 1)
    local color = COLORS[feedback.status] or COLORS.queued
    local markerSize = math.max(3, math.floor(5 * geometryScale + 0.5))
    local markerX = x - markerSize - (4 * geometryScale)
    local markerY = y + math.max(1, math.floor((height - markerSize) * 0.5))
    if manager.drawRect then
        manager:drawRect(
            markerX,
            markerY,
            markerSize,
            markerSize,
            color.a * alpha,
            color.r,
            color.g,
            color.b
        )
    end
    Presentation.DrawOutlinedText(
        manager,
        text,
        x,
        y,
        color,
        alpha,
        font
    )
    return true, height + (4 * geometryScale)
end

Renderer.Colors = COLORS

return Renderer
