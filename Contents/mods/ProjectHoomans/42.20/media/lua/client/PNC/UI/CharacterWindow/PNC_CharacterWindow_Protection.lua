PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared

function Tabs.RenderProtection(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local rows = Shared.BuildClothingRows(snapshot, payload, view.npcId)
    local protection = Shared.BuildBodyProtection(view.npcId, snapshot, payload, rows)
    local padding = 12
    local bodyWidth = Shared.Clamp(math.floor(view.width * 0.27), 96, 145)
    local bodyHeight = math.min(280, math.max(180, view.height - padding * 2))
    local contentX = padding + bodyWidth + 18
    local contentWidth = math.max(150, view.width - contentX - padding)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local y = topY
    local i

    Shared.DrawBodyMap(view, resolved.isFemale == true, padding, padding, bodyWidth, bodyHeight, protection, Shared.ProtectionColor)

    y = Shared.DrawSection(view, Shared.Text("UI_PNC_Character_Protection_Section", "Clothing Protection"), contentX, y, contentWidth)
    y = Shared.DrawBar(view, Shared.Text("UI_PNC_Character_Protection_AverageBite", "Average Bite Defense"), protection.biteAverage, 100, contentX, y, contentWidth, { r = 0.68, g = 0.3, b = 0.2 })
    y = Shared.DrawBar(view, Shared.Text("UI_PNC_Character_Protection_AverageScratch", "Average Scratch Defense"), protection.scratchAverage, 100, contentX, y, contentWidth, { r = 0.72, g = 0.58, b = 0.22 })

    local biteWidth = math.min(56, math.floor(contentWidth * 0.2))
    local scratchWidth = math.min(64, math.floor(contentWidth * 0.22))
    local partWidth = math.max(72, contentWidth - biteWidth - scratchWidth)
    view:drawText(Shared.Text("UI_PNC_Character_Protection_Part", "Part"), contentX, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    view:drawTextRight(Shared.Text("UI_PNC_Character_Protection_Bite", "Bite"), contentX + partWidth + biteWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    view:drawTextRight(Shared.Text("UI_PNC_Character_Protection_Scratch", "Scratch"), contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
    y = y + fontHeight + 3
    for _, definition in ipairs(Shared.BodyParts) do
        local entry = protection[definition.id]
        local br, bg, bb = Shared.ProtectionColor(entry.bite)
        local sr, sg, sb = Shared.ProtectionColor(entry.scratch)
        view:drawText(Shared.Text(definition.labelKey, definition.label), contentX, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
        view:drawTextRight(tostring(Shared.Round(entry.bite, 0)) .. "%", contentX + partWidth + biteWidth, y, br, bg, bb, 1, UIFont.Small)
        view:drawTextRight(tostring(Shared.Round(entry.scratch, 0)) .. "%", contentX + contentWidth, y, sr, sg, sb, 1, UIFont.Small)
        y = y + fontHeight + 2
    end

    y = y + 7
    y = Shared.DrawSection(view, Shared.Text("UI_PNC_Character_Protection_WornItems", "Worn Items"), contentX, y, contentWidth)
    if #rows == 0 then
        view:drawText(Shared.Text("UI_PNC_Character_Protection_NoClothing", "No protective clothing equipped."), contentX, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
        y = y + fontHeight + 8
    else
        local valueWidth = math.min(66, math.floor(contentWidth * 0.22))
        local itemWidth = math.max(70, contentWidth - valueWidth * 2 - 12)
        view:drawText(Shared.Text("UI_PNC_Character_Protection_Item", "Item"), contentX, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight(Shared.Text("UI_PNC_Character_Protection_Condition", "Condition"), contentX + itemWidth + valueWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        view:drawTextRight(Shared.Text("UI_PNC_Character_Protection_Holes", "Holes"), contentX + contentWidth, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 3
        view:drawRect(contentX, y, contentWidth, 1, 0.55, 0.4, 0.4, 0.4)
        y = y + 5
        for i = 1, #rows do
            local row = rows[i]
            local label = PsychopatzCore.UI.Layout.Ellipsize(row.name .. " (" .. row.location .. ")", UIFont.Small, itemWidth - 8)
            view:drawText(label, contentX, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
            local condition = row.conditionMax > 0 and tostring(Shared.Round(row.condition, 0)) .. "/" .. tostring(Shared.Round(row.conditionMax, 0)) or "-"
            view:drawTextRight(condition, contentX + itemWidth + valueWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            view:drawTextRight(tostring(row.holes or 0), contentX + contentWidth, y, 0.78, 0.78, 0.78, 1, UIFont.Small)
            y = y + fontHeight + 5
        end
    end

    return math.max(y, padding + bodyHeight) + 12
end

return Tabs
