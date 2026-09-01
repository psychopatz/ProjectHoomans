require "ISUI/ISLabel"
require "ISUI/ISPanel"
require "ISUI/ISTickBox"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ProvisionRulePanel = PNC.ProvisionRulePanel or {}

local RulePanel = PNC.ProvisionRulePanel
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function label(parent, value)
    local widget = ISLabel:new(0, 0, 20, value, 1, 1, 1, 1,
        UIFont.Small, true)
    widget:initialise()
    parent:addChild(widget)
    return widget
end

function RulePanel.Create(parent, definition, model, tr)
    local values = model:Get(definition.id) or definition.defaults
    local row = { definition = definition, entries = {}, height = 126 }
    row.panel = ISPanel:new(0, 0, 100, row.height)
    row.panel:initialise()
    row.panel:instantiate()
    row.panel.backgroundColor = Theme.Color("surfaceRaised")
    row.panel.borderColor = Theme.Color("border")
    parent:addChild(row.panel)
    row.title = label(row.panel, tr(definition.ui.labelKey))
    row.descriptionText = tr(definition.ui.descriptionKey)
    row.descriptionLines = {
        label(row.panel, ""), label(row.panel, ""), label(row.panel, ""),
    }
    row.measure = label(row.panel, tr("UI_PNC_Provision_MeasuredAs") .. ": "
        .. tr(definition.ui.measureKey))
    row.enabled = ISTickBox:new(0, 0, 70, 24, "", row, function()
        model:MarkChanged()
    end)
    row.enabled:initialise()
    row.enabled:addOption(tr("UI_PNC_Provision_Enabled"), 1)
    row.enabled:setSelected(1, values.enabled == true)
    row.panel:addChild(row.enabled)
    if row.enabled.setTooltip then
        row.enabled:setTooltip(tr(definition.ui.descriptionKey))
    end
    for _, field in ipairs(definition.ui.fields or {}) do
        local item = { definition = field }
        item.label = label(row.panel, tr(field.labelKey))
        item.entry = UI.CreateTextEntry(row.panel, {
            text = tostring(values[field.id] or field.min or 0),
            width = 70,
            height = 24,
            onlyNumbers = (tonumber(field.step) or 1) >= 1,
        })
        -- PZ's numbers-only input rejects decimal separators on some builds.
        -- Native hunger/thirst utility fields are fractional; range validation
        -- still happens in the shared policy model when the form is applied.
        row.entries[#row.entries + 1] = item
    end
    return row
end

local function wrap(value, maximumWidth)
    local lines = {}
    local current = ""
    for word in string.gmatch(tostring(value or ""), "%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if current ~= ""
            and Theme.TextWidth(UIFont.Small, candidate) > maximumWidth
        then
            lines[#lines + 1] = current
            current = word
        else
            current = candidate
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

function RulePanel.Read(row, model)
    local ok, reason = model:Set(
        row.definition.id, "enabled", row.enabled:isSelected(1)
    )
    if not ok then return false, reason end
    for _, item in ipairs(row.entries) do
        local value = tonumber(item.entry:getText())
        if value == nil then return false, "field_type_invalid" end
        ok, reason = model:Set(
            row.definition.id, item.definition.id, value
        )
        if not ok then return false, reason end
    end
    return true
end

function RulePanel.Refresh(row, model)
    local values = model:Get(row.definition.id) or row.definition.defaults
    row.enabled:setSelected(1, values.enabled == true)
    for _, item in ipairs(row.entries) do
        item.entry:setText(tostring(values[item.definition.id] or 0))
    end
end

function RulePanel.Layout(row, width, y)
    row.y = y
    local padding = 12
    local compact = width < 420
    local panelWidth = math.max(200, width - 8)
    Layout.SetBounds(row.panel, 4, y, panelWidth,
        math.max(1, row.height or 1))
    local innerWidth = row.panel:getWidth()
    Layout.SetBounds(row.title, 12, 9, math.max(1, innerWidth - 24), 24)
    local enabledX = compact and 12 or math.max(180, innerWidth - 126)
    Layout.SetBounds(row.enabled, enabledX, compact and 31 or 3,
        math.max(1, row.enabled.width or 70), 24)
    local descriptionY = compact and 59 or 36
    local lines = wrap(row.descriptionText, innerWidth - padding * 2)
    local visibleLines = math.min(3, #lines)
    for index, widget in ipairs(row.descriptionLines) do
        widget:setVisible(index <= visibleLines)
        if index <= visibleLines then
            UI.SetLabelText(widget, lines[index])
            Layout.SetBounds(widget, padding,
                descriptionY + (index - 1) * 18,
                math.max(1, innerWidth - padding * 2), 18)
        end
    end
    local fieldY = descriptionY + visibleLines * 18 + 9
    for _, item in ipairs(row.entries) do
        Layout.SetBounds(item.label, 18, fieldY + 4,
            math.max(1, innerWidth - 118), 24)
        Layout.SetBounds(item.entry, math.max(150, innerWidth - 94),
            fieldY, 76, 24)
        fieldY = fieldY + 29
    end
    Layout.SetBounds(row.measure, 18, fieldY + 2,
        math.max(1, innerWidth - 36), 24)
    row.height = fieldY + 28
    Layout.SetBounds(row.panel, 4, y, panelWidth, row.height)
    return y + row.height
end

return RulePanel
