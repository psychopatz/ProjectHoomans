PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Catalog = PNC.SkillCatalog
local Shared = PNC.CharacterWindowShared

local filledTexture
local borderTexture
local separatorTexture

local function loadTextures()
    if filledTexture ~= nil then return end
    filledTexture = getTexture("media/ui/SkillPanel/SkillUnit_Fill.png")
    borderTexture = getTexture("media/ui/SkillPanel/SkillUnit_Border.png")
    separatorTexture = getTexture("media/ui/XpSystemUI/SkillBarSeparator.png")
end

local function drawSkillUnits(view, level, x, y, availableWidth)
    local spacing = math.max(1, math.min(4, getCore and getCore():getOptionFontSizeReal() or 2))
    local unit = math.max(7, math.min(14, math.floor((availableWidth - spacing * 9) / 10)))
    local i
    for i = 0, 9 do
        local drawX = x + i * (unit + spacing)
        if i < level and filledTexture then
            view:drawTextureScaled(filledTexture, drawX, y, unit, unit, 1, 1, 0.89, 0.38)
        elseif i < level then
            view:drawRect(drawX + 1, y + 1, unit - 2, unit - 2, 1, 1, 0.89, 0.38)
        end
        if borderTexture then
            local shade = i < level and 0.95 or 0.25
            view:drawTextureScaled(borderTexture, drawX, y, unit, unit, 1, shade, shade, shade)
        else
            view:drawRectBorder(drawX, y, unit, unit, 0.9, i < level and 0.95 or 0.25, i < level and 0.86 or 0.25, i < level and 0.42 or 0.25)
        end
    end
    return unit
end

function Tabs.RenderSkills(view, snapshot, payload, topY)
    loadTextures()
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local groups = Catalog and Catalog.GetGroups and Catalog.GetGroups() or {}
    local skillLevels = resolved.skillLevels or {}
    local padding = 12
    local y = topY
    local i
    local j
    local group
    local skill
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local barWidth = Shared.Clamp(math.floor(view.width * 0.42), 120, 220)
    local barX = view.width - padding - barWidth
    local labelX = padding + 22

    for i = 1, #groups do
        group = groups[i]
        view:drawText(group.display, padding + 8, y, 1, 1, 1, 1, UIFont.Small)
        y = y + fontHeight + 3
        if separatorTexture then
            view:drawTextureScaled(separatorTexture, padding, y, view.width - padding * 2, 2, 1, 1, 1, 1)
        else
            view:drawRect(padding, y, view.width - padding * 2, 1, 0.6, 0.4, 0.4, 0.4)
        end
        y = y + 7
        for j = 1, #(group.skills or {}) do
            skill = group.skills[j]
            local level = Shared.Clamp(math.floor(tonumber(skillLevels[skill.id]) or 0), 0, 10)
            local label = PsychopatzCore.UI.Layout.Ellipsize(skill.display, UIFont.Small, math.max(60, barX - labelX - 10))
            view:drawText(label, labelX, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
            local unit = drawSkillUnits(view, level, barX, y + math.floor((fontHeight - 10) / 2), barWidth)
            y = y + math.max(fontHeight + 5, unit + 5)
        end
        y = y + 9
    end
    if #groups == 0 then
        view:drawTextCentre("No skill data available", view.width / 2, y + 30, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + 60
    end
    return y
end

return Tabs
