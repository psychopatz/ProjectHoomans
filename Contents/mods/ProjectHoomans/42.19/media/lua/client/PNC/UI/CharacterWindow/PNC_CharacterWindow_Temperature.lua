PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared

function Tabs.RenderTemperature(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local rows = Shared.BuildClothingRows(snapshot, payload, view.npcId)
    local insulation = Shared.BuildBodyInsulation(view.npcId, snapshot, payload, rows)
    local thermal = Shared.GetThermalState(view.npcId)
    local padding = 12
    local bodyWidth = Shared.Clamp(math.floor(view.width * 0.27), 96, 145)
    local bodyHeight = math.min(280, math.max(180, view.height - padding * 2))
    local contentX = padding + bodyWidth + 18
    local contentWidth = math.max(150, view.width - contentX - padding)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local y = topY
    local i

    Shared.DrawBodyMap(view, resolved.isFemale == true, padding, padding, bodyWidth, bodyHeight, insulation, Shared.TemperatureColor)

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
    y = Shared.DrawBar(view, "Average Insulation", insulation.insulationAverage * 100, 100, contentX, y, contentWidth, { r = 0.76, g = 0.42, b = 0.18 })
    y = Shared.DrawBar(view, "Average Wind Resistance", insulation.windAverage * 100, 100, contentX, y, contentWidth, { r = 0.32, g = 0.57, b = 0.75 })

    local warmthWidth = math.min(64, math.floor(contentWidth * 0.22))
    local windWidth = math.min(56, math.floor(contentWidth * 0.2))
    local partWidth = math.max(72, contentWidth - warmthWidth - windWidth)
    view:drawText("Part", contentX, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    view:drawTextRight("Warmth", contentX + partWidth + warmthWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    view:drawTextRight("Wind", contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    y = y + fontHeight + 3
    for _, definition in ipairs(Shared.BodyParts) do
        local entry = insulation[definition.id]
        local r, g, b = Shared.TemperatureColor(entry.insulation)
        view:drawText(definition.label, contentX, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
        view:drawTextRight(tostring(Shared.Round(entry.insulation * 100, 0)) .. "%", contentX + partWidth + warmthWidth, y, r, g, b, 1, UIFont.Small)
        view:drawTextRight(tostring(Shared.Round(entry.wind * 100, 0)) .. "%", contentX + contentWidth, y, 0.42, 0.7, 0.92, 1, UIFont.Small)
        y = y + fontHeight + 2
    end

    y = y + 7
    y = Shared.DrawSection(view, "Worn Items", contentX, y, contentWidth)
    if #rows == 0 then
        view:drawText("No insulating clothing equipped.", contentX, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + fontHeight + 8
    else
        local valueWidth = math.min(62, math.floor(contentWidth * 0.2))
        local itemWidth = math.max(70, contentWidth - valueWidth * 2 - 12)
        view:drawText("Garment", contentX, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Condition", contentX + itemWidth + valueWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight("Wet", contentX + contentWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 3
        view:drawRect(contentX, y, contentWidth, 1, 0.55, 0.4, 0.4, 0.4)
        y = y + 5
        for i = 1, #rows do
            local row = rows[i]
            local label = PsychopatzCore.UI.Layout.Ellipsize(row.name, UIFont.Small, itemWidth - 8)
            view:drawText(label, contentX, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
            local condition = row.conditionMax > 0 and tostring(Shared.Round(row.condition, 0)) .. "/" .. tostring(Shared.Round(row.conditionMax, 0)) or "-"
            view:drawTextRight(condition, contentX + itemWidth + valueWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            view:drawTextRight(tostring(Shared.Round(row.wetness or 0, 0)) .. "%", contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            y = y + fontHeight + 5
        end
    end

    return math.max(y, padding + bodyHeight) + 12
end

return Tabs
