require "ISUI/ISLabel"
require "ISUI/ISPanel"
require "ISUI/ISTickBox"
require "ISUI/ISTextEntryBox"

PNC = PNC or {}
PNC.ProvisionRulePanel = PNC.ProvisionRulePanel or {}

local RulePanel = PNC.ProvisionRulePanel
local Theme = PsychopatzCore.UI.Theme

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
        model.changed = true
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
        item.entry = ISTextEntryBox:new(
            tostring(values[field.id] or field.min or 0), 0, 0, 70, 24
        )
        item.entry:initialise()
        item.entry:instantiate()
        -- PZ's numbers-only input rejects decimal separators on some builds.
        -- Native hunger/thirst utility fields are fractional; range validation
        -- still happens in the shared policy model when the form is applied.
        if item.entry.setOnlyNumbers and (tonumber(field.step) or 1) >= 1 then
            item.entry:setOnlyNumbers(true)
        end
        row.panel:addChild(item.entry)
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
    model:Set(row.definition.id, "enabled", row.enabled:isSelected(1))
    for _, item in ipairs(row.entries) do
        local value = tonumber(item.entry:getText())
        if value == nil then return false, "field_type_invalid" end
        model:Set(row.definition.id, item.definition.id,
            value)
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
    row.panel:setX(4)
    row.panel:setY(y)
    row.panel:setWidth(math.max(200, width - 8))
    local innerWidth = row.panel:getWidth()
    row.title:setX(12)
    row.title:setY(9)
    row.enabled:setX(compact and 12 or math.max(180, innerWidth - 126))
    row.enabled:setY(compact and 31 or 3)
    local descriptionY = compact and 59 or 36
    local lines = wrap(row.descriptionText, innerWidth - padding * 2)
    local visibleLines = math.min(3, #lines)
    for index, widget in ipairs(row.descriptionLines) do
        widget:setVisible(index <= visibleLines)
        if index <= visibleLines then
            widget:setName(lines[index])
            widget:setX(padding)
            widget:setY(descriptionY + (index - 1) * 18)
        end
    end
    local fieldY = descriptionY + visibleLines * 18 + 9
    for _, item in ipairs(row.entries) do
        item.label:setX(18)
        item.label:setY(fieldY + 4)
        item.entry:setX(math.max(150, innerWidth - 94))
        item.entry:setY(fieldY)
        item.entry:setWidth(76)
        item.entry:setHeight(24)
        fieldY = fieldY + 29
    end
    row.measure:setX(18)
    row.measure:setY(fieldY + 2)
    row.height = fieldY + 28
    row.panel:setHeight(row.height)
    return y + row.height
end

return RulePanel
