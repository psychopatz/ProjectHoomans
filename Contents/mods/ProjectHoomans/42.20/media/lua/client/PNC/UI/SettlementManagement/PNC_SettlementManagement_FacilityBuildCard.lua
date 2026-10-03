-- Shared facility build card and native preview surface.
--
-- This provider owns the reusable visual card consumed by both the facility
-- modal and the integrated Buildings tab.  BuildUI keeps the public exports.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.FacilityBuildUI = PNC.FacilityBuildUI or {}

local BuildUI = PNC.FacilityBuildUI
local Internal = BuildUI.Internal or {}
BuildUI.Internal = Internal
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local ImageResolver = UI.ImageResolver
    or require "PsychopatzCore/UI/Components/PsychopatzImageResolver"

local function previewCall(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function previewTexture(spriteName)
    if not spriteName then return nil end
    if type(tryGetTexture) == "function" then
        local ok, texture = pcall(tryGetTexture, tostring(spriteName))
        if ok and texture and type(texture.getWidth) == "function"
            and type(texture.getHeight) == "function"
        then
            return texture
        end
    end
    if type(getTexture) == "function" then
        local ok, texture = pcall(getTexture, tostring(spriteName))
        if ok and texture and type(texture.getWidth) == "function"
            and type(texture.getHeight) == "function"
        then
            return texture
        end
    end
    if type(getSprite) == "function" then
        local ok, sprite = pcall(getSprite, tostring(spriteName))
        local texture = ok and previewCall(sprite, "getTexture") or nil
        if texture then return texture end
    end
    return nil
end

local function previewTextureValue(texture, method, fallback)
    local value = previewCall(texture, method)
    value = tonumber(value)
    return value or fallback
end

local function drawNativePreview(element, preview, x, y, width, height, alpha)
    if type(preview) ~= "table" or type(preview.tiles) ~= "table"
        or #preview.tiles < 2 or not element
        or type(element.drawTextureScaled) ~= "function"
    then
        return false
    end
    local tileScale = tonumber(Core and Core.tileScale) or 1
    local draws, minX, minY, maxX, maxY = {}, nil, nil, nil, nil
    local masterX, masterY, masterZ = tonumber(preview.masterX) or 0,
        tonumber(preview.masterY) or 0, tonumber(preview.masterZ) or 0
    for _, tile in ipairs(preview.tiles) do
        local texture = previewTexture(tile.spriteName)
        if texture then
            local textureWidth = previewTextureValue(texture, "getWidth", 0)
            local textureHeight = previewTextureValue(texture, "getHeight", 0)
            if textureWidth > 0 and textureHeight > 0 then
                local tileX = tonumber(tile.x) or 0
                local tileY = tonumber(tile.y) or 0
                local tileZ = tonumber(tile.z) or 0
                local dx = ((tileX - masterX) - (tileY - masterY))
                    * 32 * tileScale
                local dy = ((tileX - masterX) + (tileY - masterY))
                    * 16 * tileScale
                    - (tileZ - masterZ) * 96 * tileScale
                local offsetX = previewTextureValue(texture, "getOffsetX", 0)
                local offsetY = previewTextureValue(texture, "getOffsetY", 0)
                local left, top = dx + offsetX, dy + offsetY
                local right, bottom = left + textureWidth,
                    top + textureHeight
                minX = minX and math.min(minX, left) or left
                minY = minY and math.min(minY, top) or top
                maxX = maxX and math.max(maxX, right) or right
                maxY = maxY and math.max(maxY, bottom) or bottom
                draws[#draws + 1] = {
                    texture = texture, x = left, y = top,
                    width = textureWidth, height = textureHeight,
                }
            end
        end
    end
    if #draws < 2 or not minX or not minY or not maxX or not maxY then
        return false
    end
    local compositeWidth, compositeHeight = maxX - minX, maxY - minY
    if compositeWidth <= 0 or compositeHeight <= 0 then return false end
    local scale = math.min(width / compositeWidth, height / compositeHeight)
    local originX = x + (width - compositeWidth * scale) / 2 - minX * scale
    local originY = y + (height - compositeHeight * scale) / 2 - minY * scale
    for _, draw in ipairs(draws) do
        element:drawTextureScaled(draw.texture,
            originX + draw.x * scale, originY + draw.y * scale,
            draw.width * scale, draw.height * scale, alpha or 1, 1, 1, 1)
    end
    return true
end

-- Shared by the facilities cards and the integrated Buildings tab. Keeping
-- the native face compositor here ensures both tabs show the same world
-- object orientation and multi-tile footprint.
BuildUI.DrawNativePreview = drawNativePreview

local function themeColor(name, fallback)
    return Theme.colors and Theme.colors[name] or fallback
end

local function fontHeight(font)
    if type(Theme.FontHeight) == "function" then
        local ok, value = pcall(Theme.FontHeight, font)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 16
end

local function textWidth(font, value)
    value = tostring(value or "")
    if type(Theme.TextWidth) == "function" then
        local ok, width = pcall(Theme.TextWidth, font, value)
        if ok and tonumber(width) then return tonumber(width) end
    end
    return #value * 7
end

local function fitText(value, font, maxWidth)
    local text = tostring(value or "")
    local width = math.max(1, tonumber(maxWidth) or 1)
    if textWidth(font, text) <= width then return text end
    local suffix = "..."
    local candidate = text
    while #candidate > 0 do
        candidate = string.sub(candidate, 1, #candidate - 1)
        if textWidth(font, candidate .. suffix) <= width then
            return candidate .. suffix
        end
    end
    return suffix
end

local function wrapText(value, font, maxWidth, maxLines)
    local text = tostring(value or "")
    local width = math.max(1, tonumber(maxWidth) or 1)
    local limit = math.max(1, math.floor(tonumber(maxLines) or 1))
    local lines, current = {}, ""
    if text == "" then return { "" } end
    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if current == "" or textWidth(font, candidate) <= width then
            current = candidate
        else
            lines[#lines + 1] = current
            current = word
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    if #lines <= limit then return lines end
    local output = {}
    for index = 1, limit do output[index] = lines[index] end
    output[limit] = fitText(output[limit] .. " " .. lines[limit + 1],
        font, width)
    return output
end

local function drawCentered(element, value, y, font, tint, centerX, maxWidth)
    local text = fitText(value, font, maxWidth)
    element:drawTextCentre(text, centerX, y,
        tint.r, tint.g, tint.b, tint.a or 1, font)
end

Internal.CardFontHeight = fontHeight
Internal.CardTextWidth = textWidth
Internal.CardFitText = fitText
Internal.CardWrapText = wrapText


local FacilityCard = ISPanel:derive("PNCFacilityBuildCard")

-- The Base widget uses the same card surface as the original modal. Exporting
-- the class keeps the visual contract in one place while allowing the modal
-- itself to remain available to legacy callers during migration.
BuildUI.FacilityCard = FacilityCard

function FacilityCard:onMouseDown()
    self.owner:setSelected(self.option.id)
    return true
end

local cardWarned

--[[
    Rendering the card body is separated from the stencil bookkeeping so the
    clip is always released. A Lua error inside a child's render aborts the whole
    UIManager pass, and a stencil that stays set would clip every later window;
    so the body runs in pcall and the clip is cleared unconditionally.
]]
local function renderCard(self)
    local option = self.option or {}
    local selected = self.owner.selectedId == option.id
    local border = selected and themeColor("accent",
        { r = 0.2, g = 0.72, b = 0.82, a = 1 })
        or themeColor("border", { r = 0.23, g = 0.28, b = 0.32, a = 0.9 })
    local textTint = option.enabled
        and themeColor("text", { r = 0.91, g = 0.94, b = 0.96, a = 1 })
        or { r = 0.76, g = 0.81, b = 0.84, a = 1 }
    local warning = themeColor("warning", { r = 0.94, g = 0.7, b = 0.27, a = 1 })
    local muted = { r = 0.70, g = 0.76, b = 0.80, a = 1 }
    local statusTint = option.enabled
        and themeColor("success", { r = 0.39, g = 0.78, b = 0.48, a = 1 })
        or themeColor("danger", { r = 0.94, g = 0.36, b = 0.31, a = 1 })
    local padding = 10
    local contentWidth = math.max(1, self.width - padding * 2)
    local titleFont, metaFont = UIFont.Small, UIFont.Small
    local titleHeight, lineHeight = fontHeight(titleFont),
        math.max(14, fontHeight(metaFont))
    -- Reserve the metadata block first, then give the native build image what
    -- is left. A fixed image height pushed the text out of short cards.
    local titleLines = wrapText(option.name, titleFont, contentWidth, 2)
    -- The Facilities tab renders the same numbers, unclipped, in its
    -- REQUIREMENTS pane, so it turns the card's material lines off instead of
    -- repeating two truncated copies of them over the preview image.
    local showMaterials = self.showMaterialLines ~= false
    local metaLines = showMaterials and 4 or 2
    local textBlockHeight = math.max(1, #titleLines) * titleHeight
        + metaLines * lineHeight + 10
    local imageHeight = math.max(0, math.min(136,
        math.floor(self.height * 0.44), self.height - textBlockHeight - 12))
    local imageY, textY = 6, imageHeight + 8
    local showImage = imageHeight >= 32

    local surfaceAlpha = self.owner and self.owner.window
        and self.owner.window.contentSurfaceAlpha or 0.92
    surfaceAlpha = math.max(0.84, math.min(0.98,
        tonumber(surfaceAlpha) or 0.92))
    self:drawRect(0, 0, self.width, self.height, selected
        and math.min(0.98, surfaceAlpha + 0.04) or surfaceAlpha,
        0.045, 0.06, 0.07)
    self:drawRectBorder(0, 0, self.width, self.height,
        border.a or 1, border.r, border.g, border.b)
    local imageAlpha = option.enabled and 1 or 0.42
    if showImage then
        if not drawNativePreview(self, option.previewTiles, padding, imageY,
            contentWidth, imageHeight, imageAlpha)
        then
            ImageResolver.Draw(self, option.texture, padding, imageY,
                contentWidth, imageHeight, imageAlpha)
        end
    end

    for index, line in ipairs(titleLines) do
        drawCentered(self, line, textY + (index - 1) * titleHeight,
            titleFont, textTint, self.width / 2, contentWidth)
    end
    textY = textY + math.max(1, #titleLines) * titleHeight + 3
    if showMaterials then
        drawCentered(self, option.costText, textY, metaFont, warning,
            self.width / 2, contentWidth)
        textY = textY + lineHeight
        drawCentered(self, option.sourceText, textY, metaFont, muted,
            self.width / 2, contentWidth)
        textY = textY + lineHeight
    end
    drawCentered(self, option.skillText, textY, metaFont, muted,
        self.width / 2, contentWidth)
    textY = textY + lineHeight
    drawCentered(self, option.status, textY, metaFont, statusTint,
        self.width / 2, contentWidth)
end

function FacilityCard:render()
    ISPanel.render(self)
    -- Clip to the card. Facility text wraps to an unknown number of lines and
    -- used to be painted straight over the details/requirements bands below.
    if self.setStencilRect then
        self:setStencilRect(0, 0, self.width, self.height)
    end
    local ok, err = pcall(renderCard, self)
    if self.clearStencilRect then self:clearStencilRect() end
    if not ok and not cardWarned then
        cardWarned = true
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("facility card render failed: " .. tostring(err))
        end
    end
end

function FacilityCard:new(x, y, width, height, owner, option)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self); self.__index = self
    object.owner, object.option = owner, option
    object.background = false
    return object
end


return BuildUI
