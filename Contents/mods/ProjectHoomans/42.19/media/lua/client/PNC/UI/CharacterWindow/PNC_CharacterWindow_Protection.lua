PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared

local bodyTextures = {}

local function bodyTexture(isFemale)
    local key = isFemale and "female" or "male"
    if bodyTextures[key] == nil then
        bodyTextures[key] = getTexture("media/ui/defense/" .. key .. "_base.png")
    end
    return bodyTextures[key]
end

local function drawBody(view, texture, x, y, width, height)
    if not texture then return end
    local textureWidth = texture.getWidthOrig and texture:getWidthOrig() or texture:getWidth()
    local textureHeight = texture.getHeightOrig and texture:getHeightOrig() or texture:getHeight()
    local scale = math.min(width / math.max(1, textureWidth), height / math.max(1, textureHeight))
    local drawWidth = textureWidth * scale
    local drawHeight = textureHeight * scale
    view:drawTextureScaled(texture, x + (width - drawWidth) / 2, y, drawWidth, drawHeight, 1, 0.88, 0.88, 0.88)
end

function Tabs.RenderProtection(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local equipment = Shared.GetEquipment(snapshot, payload)
    local rows = Shared.BuildClothingRows(snapshot, payload)
    local summary = Shared.SummarizeClothing(rows)
    local padding = 12
    local bodyWidth = Shared.Clamp(math.floor(view.width * 0.27), 96, 145)
    local bodyHeight = math.min(280, math.max(180, view.height - padding * 2))
    local contentX = padding + bodyWidth + 18
    local contentWidth = math.max(150, view.width - contentX - padding)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local y = topY
    local i

    drawBody(view, bodyTexture(resolved.isFemale == true), padding, padding, bodyWidth, bodyHeight)

    y = Shared.DrawSection(view, "Clothing Protection", contentX, y, contentWidth)
    y = Shared.DrawBar(view, "Average Bite Defense", summary.biteAverage, 100, contentX, y, contentWidth, { r = 0.68, g = 0.3, b = 0.2 })
    y = Shared.DrawBar(view, "Average Scratch Defense", summary.scratchAverage, 100, contentX, y, contentWidth, { r = 0.72, g = 0.58, b = 0.22 })
    y = Shared.DrawLabelValue(view, "Primary", equipment.primaryFullType or "Bare hands", contentX, y + 2, 72)
    y = Shared.DrawLabelValue(view, "Secondary", equipment.secondaryFullType or "-", contentX, y, 72)

    y = y + 7
    y = Shared.DrawSection(view, "Worn Items", contentX, y, contentWidth)
    if #rows == 0 then
        view:drawText("No protective clothing equipped.", contentX, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + fontHeight + 8
    else
        local valueWidth = math.min(54, math.floor(contentWidth * 0.18))
        local itemWidth = math.max(70, contentWidth - valueWidth * 2 - 12)
        view:drawText("Item", contentX, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Bite", contentX + itemWidth + valueWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Scratch", contentX + contentWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 3
        view:drawRect(contentX, y, contentWidth, 1, 0.55, 0.4, 0.4, 0.4)
        y = y + 5
        for i = 1, #rows do
            local row = rows[i]
            local label = PsychopatzCore.UI.Layout.Ellipsize(row.name .. " (" .. row.location .. ")", UIFont.Small, itemWidth - 8)
            view:drawText(label, contentX, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
            view:drawTextRight(tostring(Shared.Round(row.bite, 1)) .. "%", contentX + itemWidth + valueWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            view:drawTextRight(tostring(Shared.Round(row.scratch, 1)) .. "%", contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            y = y + fontHeight + 5
        end
    end

    return math.max(y, padding + bodyHeight) + 12
end

return Tabs
