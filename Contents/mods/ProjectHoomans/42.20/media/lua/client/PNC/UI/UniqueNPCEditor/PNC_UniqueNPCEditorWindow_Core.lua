local EditorUI = PNC.UniqueNPCEditorUI
local Internal = EditorUI.Internal or {}
local UI = Internal.UI
local Layout = Internal.Layout
local Theme = Internal.Theme

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function text(value)
    if value == nil then return "" end
    return tostring(value)
end

local function fieldText(entry)
    return entry and entry.getText and entry:getText() or ""
end

local function setField(entry, value)
    if entry and entry.setText then entry:setText(text(value)) end
end

-- ISComboBox:getSelectedData() assumes selected is a valid option index.
-- Newly-created combos start at 0, so every read goes through this guard.
local function comboData(combo)
    local selected = combo and combo.getSelected and combo:getSelected()
        or combo and combo.selected
    local options = combo and combo.options
    if type(selected) ~= "number" or selected < 1
        or type(options) ~= "table" or not options[selected]
    then
        return nil
    end
    return options[selected].data
end

local function clearCombo(combo)
    if not combo then return end
    combo:clear()
    combo.selected = 0
end

local function selectCombo(combo, value)
    local found = false
    if not combo then return end
    if value ~= nil then
        combo:selectData(value)
        for _, optionValue in ipairs(combo.options or {}) do
            if optionValue.data == value then
                found = true
                break
            end
        end
        if not found and combo.addOptionWithData then
            combo:addOptionWithData(
                tr("UI_PNC_UniqueNPCEditor_Unavailable", "Unavailable: ")
                    .. tostring(value),
                value
            )
            combo:selectData(value)
        end
    end
    if combo.selected == 0 and combo.options and combo.options[1] then
        combo.selected = 1
    end
end

local function addLabel(parent, value)
    local label = ISLabel:new(0, 0, 24, tostring(value or ""),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    label:initialise()
    if UI.SetLabelTheme then UI.SetLabelTheme(label, "textMuted") end
    parent:addChild(label)
    return label
end

local function newCombo(parent, callback, target)
    local combo = ISComboBox:new(0, 0, 1, 1, target or parent, callback)
    combo:initialise()
    combo:instantiate()
    parent:addChild(combo)
    return combo
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item or {}
    local selected = list.selected == entry.index
    local muted = Theme.colors.textMuted
    local color = selected and Theme.colors.text or muted
    UI.DrawListSelection(list, y, list.itemheight, selected, alternate)
    list:drawText(Layout.Ellipsize(item.label or "", UIFont.Small,
        list:getWidth() * 0.46), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(text(item.value), UIFont.Small,
        list:getWidth() * 0.48), list:getWidth() * 0.50, y + 5,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    return y + list.itemheight
end


Internal.tr = tr
Internal.text = text
Internal.fieldText = fieldText
Internal.setField = setField
Internal.comboData = comboData
Internal.clearCombo = clearCombo
Internal.selectCombo = selectCombo
Internal.addLabel = addLabel
Internal.newCombo = newCombo
Internal.drawDetail = drawDetail
EditorUI.Internal = Internal
