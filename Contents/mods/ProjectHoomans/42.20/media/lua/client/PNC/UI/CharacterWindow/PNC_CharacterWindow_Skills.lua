PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

require "PNC/UI/Knowledge/PNC_KnowledgePresentation"

local Tabs = PNC.CharacterWindowTabs
local Catalog = PNC.SkillCatalog
local Shared = PNC.CharacterWindowShared
local KnowledgePresentation = PNC.KnowledgePresentation
local ClientState = PNC.Network.ClientState

local filledTexture
local borderTexture
local separatorTexture

local function loadTextures()
    if filledTexture ~= nil then return end
    filledTexture = getTexture("media/ui/SkillPanel/SkillUnit_Fill.png")
    borderTexture = getTexture("media/ui/SkillPanel/SkillUnit_Border.png")
    separatorTexture = getTexture("media/ui/XpSystemUI/SkillBarSeparator.png")
end

local function drawSkillUnits(view, level, x, y, unit, spacing)
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
end

function Tabs.RenderSkills(view, snapshot, payload, topY)
    loadTextures()
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local groups = Catalog and Catalog.GetGroups and Catalog.GetGroups() or {}
    local skillLevels = resolved.skillLevels or {}
    local knowledge = ClientState.npcKnowledge and ClientState.npcKnowledge[view.npcId] or nil
    local padding = 12
    local y = topY
    local i
    local j
    local group
    local skill
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local scrollWidth = view.vscroll and view.vscroll:getWidth() or 0
    local right = view.width - padding - scrollWidth
    local spacing = Shared.Clamp(getCore and getCore():getOptionFontSizeReal() or 2, 1, 4)
    local unit = Shared.Clamp(math.floor((view.width * .42 - spacing * 9) / 10), 7, 14)
    local barX = right - (unit * 10 + spacing * 9)
    local rowHeight = math.max(fontHeight, unit) + 5
    local labelX = padding + 22

    for i = 1, #groups do
        group = groups[i]
        view:drawText(group.display, padding + 8, y, 1, 1, 1, 1, UIFont.Small)
        y = y + fontHeight + 3
        if separatorTexture then
            view:drawTextureScaled(separatorTexture, padding, y, right - padding, 2, 1, 1, 1, 1)
        else
            view:drawRect(padding, y, right - padding, 1, 0.6, 0.4, 0.4, 0.4)
        end
        y = y + 7
        for j = 1, #(group.skills or {}) do
            skill = group.skills[j]
            local unlocked = KnowledgePresentation.IsKnown(knowledge, "skill." .. tostring(skill.id))
            local level = unlocked and Shared.Clamp(math.floor(tonumber(skillLevels[skill.id]) or 0), 0, 10) or 0
            local label = PsychopatzCore.UI.Layout.Ellipsize(skill.display, UIFont.Small, math.max(60, barX - labelX - 10))
            view:drawText(label, labelX, y, unlocked and 0.9 or 0.5, unlocked and 0.9 or 0.5, unlocked and 0.9 or 0.5, 1, UIFont.Small)
            if unlocked then
                drawSkillUnits(view, level, barX, y + math.floor((fontHeight - unit) / 2), unit, spacing)
            else
                view:drawText(Shared.Text("UI_PNC_Character_Skills_Locked", "LOCKED"), barX, y, 0.7, 0.55, 0.18, 1, UIFont.Small)
            end
            y = y + rowHeight
        end
        y = y + 9
    end
    if #groups == 0 then
        view:drawTextCentre(Shared.Text("UI_PNC_Character_Skills_NoData", "No skill data available"), view.width / 2, y + 30, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + 60
    end
    return y
end

return Tabs
