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

local function drawBody(view, texture, x, y, width, height, thermal)
    if not texture then return end
    local textureWidth = texture.getWidthOrig and texture:getWidthOrig() or texture:getWidth()
    local textureHeight = texture.getHeightOrig and texture:getHeightOrig() or texture:getHeight()
    local scale = math.min(width / math.max(1, textureWidth), height / math.max(1, textureHeight))
    local drawWidth = textureWidth * scale
    local drawHeight = textureHeight * scale
    local uiTemperature = thermal and tonumber(thermal.coreTemperatureUI) or 0.5
    local cold = Shared.Clamp((0.5 - uiTemperature) * 2, 0, 1)
    local hot = Shared.Clamp((uiTemperature - 0.5) * 2, 0, 1)
    view:drawTextureScaled(
        texture,
        x + (width - drawWidth) / 2,
        y,
        drawWidth,
        drawHeight,
        1,
        0.88 + hot * 0.12,
        0.88 - math.max(cold, hot) * 0.25,
        0.88 + cold * 0.12
    )
end

function Tabs.RenderTemperature(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local rows = Shared.BuildClothingRows(snapshot, payload)
    local summary = Shared.SummarizeClothing(rows)
    local thermal = Shared.GetThermalState(view.npcId)
    local padding = 12
    local bodyWidth = Shared.Clamp(math.floor(view.width * 0.27), 96, 145)
    local bodyHeight = math.min(280, math.max(180, view.height - padding * 2))
    local contentX = padding + bodyWidth + 18
    local contentWidth = math.max(150, view.width - contentX - padding)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local y = topY
    local i

    drawBody(view, bodyTexture(resolved.isFemale == true), padding, padding, bodyWidth, bodyHeight, thermal)

    y = Shared.DrawSection(view, "Body Temperature", contentX, y, contentWidth)
    if thermal and thermal.coreTemperature then
        y = Shared.DrawBar(view, "Core Temperature", thermal.coreTemperature, 42, contentX, y, contentWidth, { r = 0.82, g = 0.34, b = 0.18 })
        y = Shared.DrawLabelValue(view, "Reading", tostring(Shared.Round(thermal.coreTemperature, 1)) .. " C", contentX, y + 2, 92)
        y = Shared.DrawLabelValue(view, "Heat Output", tostring(Shared.Round((thermal.heatGenerationUI or 0) * 100, 0)) .. "%", contentX, y, 92)
    else
        view:drawText("Live temperature telemetry is available while this NPC is loaded.", contentX, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + fontHeight + 10
    end

    y = Shared.DrawSection(view, "Clothing Insulation", contentX, y, contentWidth)
    y = Shared.DrawBar(view, "Average Insulation", summary.insulationAverage * 100, 100, contentX, y, contentWidth, { r = 0.76, g = 0.42, b = 0.18 })
    y = Shared.DrawBar(view, "Average Wind Resistance", summary.windAverage * 100, 100, contentX, y, contentWidth, { r = 0.32, g = 0.57, b = 0.75 })

    y = y + 4
    if #rows == 0 then
        view:drawText("No insulating clothing equipped.", contentX, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + fontHeight + 8
    else
        local valueWidth = math.min(52, math.floor(contentWidth * 0.18))
        local itemWidth = math.max(70, contentWidth - valueWidth * 2 - 12)
        view:drawText("Garment", contentX, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Warmth", contentX + itemWidth + valueWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Wind", contentX + contentWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 3
        view:drawRect(contentX, y, contentWidth, 1, 0.55, 0.4, 0.4, 0.4)
        y = y + 5
        for i = 1, #rows do
            local row = rows[i]
            local label = PsychopatzCore.UI.Layout.Ellipsize(row.name, UIFont.Small, itemWidth - 8)
            view:drawText(label, contentX, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
            view:drawTextRight(tostring(Shared.Round(row.insulation * 100, 0)) .. "%", contentX + itemWidth + valueWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            view:drawTextRight(tostring(Shared.Round(row.wind * 100, 0)) .. "%", contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            y = y + fontHeight + 5
        end
    end

    return math.max(y, padding + bodyHeight) + 12
end

return Tabs
