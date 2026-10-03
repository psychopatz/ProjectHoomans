PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local Internal = Shared.Internal
local round = Internal.round
local bodyTextureCache = Internal.bodyTextureCache

local function bodyTexture(path)
    local key = tostring(path)
    if bodyTextureCache[key] == nil then
        bodyTextureCache[key] = getTexture(path)
    end
    return bodyTextureCache[key]
end

function Shared.ProtectionColor(value)
    local ratio = Shared.Clamp((tonumber(value) or 0) / 100, 0, 1)
    return 0.9 - ratio * 0.62, 0.12 + ratio * 0.72, 0.1
end

function Shared.TemperatureColor(value)
    local ratio = Shared.Clamp(tonumber(value) or 0, 0, 1)
    if ratio < 0.5 then return 0.08, 0.35 + ratio, 1 - ratio * 0.7 end
    return 0.2 + ratio * 0.8, 1 - (ratio - 0.5) * 1.6, 0.12
end

function Shared.DrawBodyMap(view, isFemale, x, y, width, height, values, colorForValue)
    local sex = isFemale and "female" or "male"
    local base = bodyTexture("media/ui/BodyParts/" .. sex .. "_base_white")
    local outline = bodyTexture("media/ui/BodyParts/bps_" .. sex .. "_outlines")
    local originalWidth = base and (base.getWidthOrig and base:getWidthOrig() or base:getWidth()) or 123
    local originalHeight = base and (base.getHeightOrig and base:getHeightOrig() or base:getHeight()) or 302
    local scale = math.min(width / math.max(1, originalWidth), height / math.max(1, originalHeight))
    local drawWidth = originalWidth * scale
    local drawHeight = originalHeight * scale
    local drawX = x + (width - drawWidth) / 2
    local bounds = { x = drawX, y = y, width = drawWidth, height = drawHeight, scale = scale, parts = {} }
    if base then view:drawTextureScaled(base, drawX, y, drawWidth, drawHeight, 0.25, 1, 1, 1) end
    for _, definition in ipairs(Shared.BodyParts) do
        local entry = values and values[definition.id] or nil
        local value = type(entry) == "table" and entry.value or entry
        local texture = bodyTexture("media/ui/BodyParts/bps_" .. sex .. "_" .. definition.texture)
        if texture then
            local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
            local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
            local textureWidth = texture.getWidth and texture:getWidth() or 0
            local textureHeight = texture.getHeight and texture:getHeight() or 0
            local nodeX = tonumber(definition.nodeX) or 0
            local nodeY = tonumber(definition.nodeY) or 0
            if isFemale and definition.femaleNodeX then nodeX = definition.femaleNodeX end
            if not isFemale and definition.maleNodeX then nodeX = definition.maleNodeX end
            bounds.parts[definition.id] = {
                x = drawX + (offsetX + textureWidth / 2 + nodeX) * scale,
                y = y + (offsetY + textureHeight / 2 + nodeY) * scale,
            }
        end
        if value ~= nil then
            local r, g, b = 1, 1, 1
            if colorForValue then r, g, b = colorForValue(value) end
            if texture then
                local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
                local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
                local textureWidth = texture.getWidth and texture:getWidth() or 0
                local textureHeight = texture.getHeight and texture:getHeight() or 0
                view:drawTextureScaled(texture, drawX + offsetX * scale, y + offsetY * scale,
                    textureWidth * scale, textureHeight * scale, 0.8, r, g, b)
            end
        end
    end
    if outline then view:drawTextureScaled(outline, drawX, y, drawWidth, drawHeight, 1, 1, 1, 1) end
    return bounds
end
function Shared.DrawSection(panel, title, x, y, width)
    panel:drawText(tostring(title), x, y, 1, 1, 1, 1, UIFont.Medium)
    local lineY = y + (getTextManager and getTextManager():getFontHeight(UIFont.Medium) or 18) + 2
    panel:drawRect(x, lineY, width, 1, 0.6, 0.4, 0.4, 0.4)
    return lineY + 8
end

function Shared.DrawLabelValue(panel, label, value, x, y, labelWidth, valueAlpha)
    panel:drawTextRight(tostring(label), x + labelWidth, y, 1, 1, 1, 1, UIFont.Small)
    panel:drawText(tostring(value), x + labelWidth + 10, y, 1, 1, 1, valueAlpha or 0.62, UIFont.Small)
    return y + (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14) + 6
end

function Shared.DrawBar(panel, label, value, maximum, x, y, width, color)
    local fontHeight = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14
    local ratio = Shared.Clamp((tonumber(value) or 0) / math.max(0.0001, tonumber(maximum) or 1), 0, 1)
    color = color or { r = 0.72, g = 0.72, b = 0.72 }
    panel:drawText(tostring(label), x, y, 1, 1, 1, 1, UIFont.Small)
    panel:drawTextRight(tostring(round(value, 1)) .. "/" .. tostring(round(maximum, 1)), x + width, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    y = y + fontHeight + 3
    panel:drawRect(x, y, width, 10, 0.85, 0.08, 0.08, 0.08)
    panel:drawRect(x + 1, y + 1, math.max(0, (width - 2) * ratio), 8, 0.9, color.r, color.g, color.b)
    panel:drawRectBorder(x, y, width, 10, 0.85, 0.45, 0.45, 0.45)
    return y + 18
end

return Shared
