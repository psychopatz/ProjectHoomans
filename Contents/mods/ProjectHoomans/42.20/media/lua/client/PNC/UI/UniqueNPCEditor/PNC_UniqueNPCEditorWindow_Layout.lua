local Window = ISPNCUniqueNPCEditorWindow
local Internal = Window.Internal or {}
local Layout = Internal.Layout

local function layoutEditorFrame(self, rect)
    local toolbar = Layout.Flow(self.toolbar, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = self.uiScale, minWidth = 86, gap = 6 })
    local leftGap = Layout.Pixels(10, self.uiScale)
    local portraitWidth = math.min(Layout.Pixels(280, self.uiScale),
        math.max(Layout.Pixels(220, self.uiScale), math.floor(rect.width * 0.30)))
    local leftWidth = rect.width - portraitWidth - leftGap
    local top = toolbar.bottom + Layout.Pixels(8, self.uiScale)
    local availableHeight = math.max(Layout.Pixels(160, self.uiScale),
        rect.y + rect.height - top)
    local stacked = leftWidth < Layout.Pixels(430, self.uiScale)
    local tabHeight = availableHeight
    local portraitX
    local portraitY = top
    local portraitHeight = availableHeight
    if stacked then
        leftWidth = rect.width
        portraitWidth = rect.width
        tabHeight = math.max(Layout.Pixels(230, self.uiScale),
            math.floor((availableHeight - leftGap) * 0.62))
        tabHeight = math.min(tabHeight,
            math.max(Layout.Pixels(1, self.uiScale), availableHeight - leftGap))
        portraitY = top + tabHeight + leftGap
        portraitHeight = math.max(Layout.Pixels(120, self.uiScale),
            availableHeight - tabHeight - leftGap)
        portraitX = rect.x
    else
        portraitX = rect.x + leftWidth + leftGap
    end
    Layout.SetBounds(self.tabPanel, rect.x, top, leftWidth, tabHeight)
    local viewHeight = math.max(Layout.Pixels(1, self.uiScale),
        tabHeight - self.tabPanel.tabHeight)
    Layout.SetBounds(self.formView, 0, self.tabPanel.tabHeight,
        leftWidth, viewHeight)
    Layout.SetBounds(self.appearanceTab, 0, self.tabPanel.tabHeight,
        leftWidth, viewHeight)
    self.appearanceTab.uiScale = self.uiScale
    if self.appearanceTab.onResponsiveLayout then
        self.appearanceTab:onResponsiveLayout()
    end
    return leftWidth, viewHeight, portraitX, portraitY, portraitWidth, portraitHeight, top, stacked
end

local function layoutEditorForm(self, leftWidth, viewHeight)
    local formWidth = leftWidth
    local formHeight = viewHeight
    local y = Layout.Pixels(10, self.uiScale)
    local smallHeight = Layout.Pixels(26, self.uiScale)
    local rowHeight = Layout.Pixels(29, self.uiScale)
    local labelWidth = Layout.Pixels(88, self.uiScale)
    local columnGap = Layout.Pixels(8, self.uiScale)
    local twoColumns = formWidth >= Layout.Pixels(600, self.uiScale)
    local columnWidth = twoColumns
        and math.floor((formWidth - columnGap) / 2) or formWidth
    local inputWidth = math.max(Layout.Pixels(1, self.uiScale),
        columnWidth - labelWidth)
    Layout.SetBounds(self.fileLabel, 0, y, labelWidth, smallHeight)
    Layout.SetBounds(self.fileCombo, labelWidth, y,
        formWidth - labelWidth, smallHeight)
    y = y + smallHeight + Layout.Pixels(24, self.uiScale)
    local identityY = y
    for index, row in ipairs(self.coreRows) do
        local column = twoColumns and (index - 1) % 2 or 0
        local rowIndex = twoColumns
            and math.floor((index - 1) / 2) or index - 1
        local x = column * (columnWidth + columnGap)
        local rowY = identityY + rowIndex * rowHeight
        Layout.SetBounds(row.labelControl, x, rowY, labelWidth, smallHeight)
        Layout.SetBounds(row.entry, x + labelWidth, rowY,
            inputWidth, smallHeight)
    end
    local identityRows = twoColumns
        and math.ceil(#self.coreRows / 2) or #self.coreRows
    local addY = identityY + identityRows * rowHeight
        + Layout.Pixels(28, self.uiScale)
    local addControlWidth = formWidth - labelWidth
    for index, row in ipairs(self.addRows) do
        local rowY = addY + (index - 1) * rowHeight
        Layout.SetBounds(row.labelControl, 0, rowY, labelWidth, smallHeight)
        local buttonWidth = Layout.Pixels(54, self.uiScale)
        local buttonX = formWidth - buttonWidth
        Layout.SetBounds(row.button, buttonX, rowY, buttonWidth, smallHeight)
        local available = math.max(Layout.Pixels(1, self.uiScale),
            addControlWidth - buttonWidth - columnGap)
        local entryX = labelWidth
        if #row.entries == 2 then
            local each = math.max(Layout.Pixels(1, self.uiScale),
                math.floor((available - columnGap) / 2))
            Layout.SetBounds(row.entries[1], entryX, rowY, each, smallHeight)
            Layout.SetBounds(row.entries[2], entryX + each + columnGap,
                rowY, each, smallHeight)
        else
            Layout.SetBounds(row.entries[1], entryX, rowY,
                available, smallHeight)
        end
    end
    local detailsY = addY + #self.addRows * rowHeight
        + Layout.Pixels(25, self.uiScale)
    local buttonHeight = Layout.Pixels(26, self.uiScale)
    local detailsButtonsY = formHeight - buttonHeight
    local detailsHeight = math.max(Layout.Pixels(70, self.uiScale),
        detailsButtonsY - detailsY - Layout.Pixels(5, self.uiScale))
    Layout.SetBounds(self.details, 0, detailsY, formWidth, detailsHeight)
    local resetWidth = Layout.Pixels(120, self.uiScale)
    local removeWidth = Layout.Pixels(75, self.uiScale)
    Layout.SetBounds(self.resetDetailsButton, 0, detailsButtonsY,
        resetWidth, buttonHeight)
    Layout.SetBounds(self.removeButton,
        resetWidth + columnGap, detailsButtonsY,
        removeWidth, buttonHeight)
    Layout.SetBounds(self.statusLabel,
        resetWidth + removeWidth + columnGap * 2,
        detailsButtonsY, formWidth - resetWidth - removeWidth - columnGap * 2,
        buttonHeight)
    return addY, detailsY, twoColumns
end

local function layoutEditorPortrait(self, portraitX, portraitY, portraitWidth, portraitHeight)
    self.portraitPanel:setVisible(true)
    Layout.SetBounds(self.portraitPanel, portraitX, portraitY,
        portraitWidth, portraitHeight)
    if self.portraitPanel.setPortraitBounds then
        self.portraitPanel:setPortraitBounds(portraitX, portraitY,
            portraitWidth, portraitHeight)
    end
end

function ISPNCUniqueNPCEditorWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 58, bottom = 12 })
    local leftWidth, viewHeight, portraitX, portraitY, portraitWidth, portraitHeight, top, stacked =
        layoutEditorFrame(self, rect)
    local addY, detailsY, twoColumns =
        layoutEditorForm(self, leftWidth, viewHeight)
    layoutEditorPortrait(self, portraitX, portraitY, portraitWidth, portraitHeight)
    self.layout = {
        x = rect.x, y = top, leftWidth = leftWidth,
        addY = addY, detailsY = detailsY, portraitX = portraitX,
        portraitWidth = portraitWidth,
        twoColumns = twoColumns, stacked = stacked,
    }
end


