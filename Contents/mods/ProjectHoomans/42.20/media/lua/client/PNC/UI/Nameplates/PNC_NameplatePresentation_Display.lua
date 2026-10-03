local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function copySpeechColor(value, fallback)
    if type(value) ~= "table" then
        return {
            r = fallback.r,
            g = fallback.g,
            b = fallback.b,
            a = fallback.a,
        }
    end
    local red = tonumber(value.r) or fallback.r
    local green = tonumber(value.g) or fallback.g
    local blue = tonumber(value.b) or fallback.b
    local alpha = tonumber(value.a) or fallback.a
    local scale = math.max(red, green, blue) > 1 and (1 / 255) or 1
    if alpha > 1 then alpha = alpha / 255 end
    return {
        r = clamp(red * scale, 0, 1),
        g = clamp(green * scale, 0, 1),
        b = clamp(blue * scale, 0, 1),
        a = clamp(alpha, 0, 1),
    }
end

function Presentation.ShouldShowHealth(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    return (tonumber(snapshot.recentDamageUntil) or 0) > currentTime
end

function Presentation.ShouldShowStamina(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    if (tonumber(snapshot.staminaVisibleUntil) or 0) > currentTime then return true end
    return Presentation.StaminaRatio(snapshot) < 0.999
end

function Presentation.ScaleFor(playerIndex)
    local zoom = getCore():getZoom(playerIndex)
    if zoom <= 0 then zoom = 1 end
    local divisor = zoom > 1 and (zoom * 1.15) or 1
    local barScale = DisplaySettings
        and DisplaySettings.GetNameplateBarScale
        and DisplaySettings.GetNameplateBarScale() or 1
    return {
        zoom = zoom,
        barWidth = (Presentation.Layout.barWidth * barScale) / divisor,
        barHeight = (Presentation.Layout.barHeight * barScale) / divisor,
        barGap = (Presentation.Layout.barGap * barScale) / zoom,
        nameYOffset = Presentation.Layout.nameYOffset / zoom,
        barYOffset = Presentation.Layout.barYOffset / zoom,
    }
end

function Presentation.CacheTextMetric(entry, key, text, font)
    local widthKey = key .. "Width"
    local fontKey = key .. "Font"
    if entry[key] ~= text or not entry[widthKey]
        or entry[fontKey] ~= font
    then
        entry[key] = text
        entry[fontKey] = font
        entry[widthKey] = getTextManager():MeasureStringX(font, text)
    end
end

function Presentation.DrawOutlinedText(manager, text, x, y, color, alpha, font)
    local textAlpha
    local red
    local green
    local blue
    if not text or text == "" then return end
    textAlpha = alpha or 1
    red = color and tonumber(color.r) or 1
    green = color and tonumber(color.g) or 1
    blue = color and tonumber(color.b) or 1
    local outlineAlpha = math.min(1, textAlpha * 0.95)
    manager:drawText(text, x - 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x + 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y - 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y + 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y, red, green, blue, textAlpha, font)
end

function Presentation.CreateSpeechTextObject(text, color, maxCharsPerLine)
    if not TextDrawObject or not TextDrawObject.new then return nil end
    text = tostring(text or "")
    if text == "" then return nil end
    text = string.gsub(text, "\r\n?", "\n")
    text = string.gsub(text, "\n", "[br/]")
    color = copySpeechColor(color, Presentation.DefaultSpeechColor)
    local object = TextDrawObject.new(
        255, 255, 255,
        true,   -- allow explicit [br/] line breaks
        false,  -- images
        false,  -- chat icons
        false,  -- inline color tags; the message color is authoritative
        false,  -- inline font tags
        true    -- equalize line heights like player chat
    )
    object:setDefaultColors(color.r, color.g, color.b, 1.0)
    object:setOutlineColors(0, 0, 0, 255)
    object:ReadString(
        Presentation.Fonts.speech or Presentation.Fonts.debug,
        text,
        math.max(1, math.floor(tonumber(maxCharsPerLine)
            or Presentation.Layout.speechMaxCharsPerLine))
    )
    return object
end

