local Window = ISPNCNPCAuthoringEditor
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

local function layoutDebugForm(self, leftWidth, viewHeight)
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

local function companionRowVisible(self, row)
    local capability = self:fieldCapability(row.fieldID or row.id)
    if not capability or capability.visible == false then return false end
    return row.id ~= "faction" and row.id ~= "hair" and row.id ~= "beard"
end

local function companionRowLocked(self, row)
    local capability = self:fieldCapability(row.fieldID or row.id)
    return capability and capability.editable == false
        and (row.id == "surname" or row.id == "gender")
end

local function layoutCompanionRow(self, row, y, width)
    local labelWidth = math.min(Layout.Pixels(132, self.uiScale),
        math.max(Layout.Pixels(96, self.uiScale), math.floor(width * 0.32)))
    local rowHeight = Layout.Pixels(30, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    Layout.SetBounds(row.labelControl, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(companionRowLocked(self, row)
        and row.readOnlyValue or row.entry,
        labelWidth + gap, y, width - labelWidth - gap, rowHeight)
    if row.entry and row.entry.setVisible then
        row.entry:setVisible(not companionRowLocked(self, row))
    end
    if row.readOnlyValue and row.readOnlyValue.setVisible then
        row.readOnlyValue:setVisible(companionRowLocked(self, row))
    end
    return y + rowHeight + Layout.Pixels(4, self.uiScale)
end

local function layoutCompanionAddRow(self, row, y, width)
    local labelWidth = math.min(Layout.Pixels(132, self.uiScale),
        math.max(Layout.Pixels(96, self.uiScale), math.floor(width * 0.32)))
    local rowHeight = Layout.Pixels(30, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local buttonWidth = Layout.Pixels(58, self.uiScale)
    local inputWidth = math.max(Layout.Pixels(1, self.uiScale),
        width - labelWidth - gap - buttonWidth - gap)
    Layout.SetBounds(row.labelControl, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(row.button, width - buttonWidth, y,
        buttonWidth, rowHeight)
    if #row.entries == 2 then
        local each = math.max(Layout.Pixels(1, self.uiScale),
            math.floor((inputWidth - gap) / 2))
        Layout.SetBounds(row.entries[1], labelWidth + gap, y, each, rowHeight)
        Layout.SetBounds(row.entries[2], labelWidth + gap + each + gap,
            y, each, rowHeight)
    else
        Layout.SetBounds(row.entries[1], labelWidth + gap, y,
            inputWidth, rowHeight)
    end
    return y + rowHeight + Layout.Pixels(4, self.uiScale)
end

local function layoutCompanionForm(self, formWidth, viewHeight)
    local y = Layout.Pixels(10, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local sectionHeight = Layout.Pixels(24, self.uiScale)
    local listHeight = Layout.Pixels(116, self.uiScale)
    local rowByID = {}
    for _, row in ipairs(self.coreRows or {}) do rowByID[row.id] = row end

    local function section(name)
        local label = self.sectionLabels and self.sectionLabels[name]
        if label then
            Layout.SetBounds(label, 0, y, formWidth, sectionHeight)
            label:setVisible(true)
        end
        y = y + sectionHeight + gap
    end

    local function rows(ids)
        for _, id in ipairs(ids) do
            local row = rowByID[id]
            if row and companionRowVisible(self, row) then
                y = layoutCompanionRow(self, row, y, formWidth)
            elseif row then
                Layout.SetBounds(row.labelControl, 0, 0, 0, 0)
                Layout.SetBounds(row.entry, 0, 0, 0, 0)
                if row.readOnlyValue then
                    Layout.SetBounds(row.readOnlyValue, 0, 0, 0, 0)
                end
            end
        end
    end

    section("identity")
    rows({ "forename", "nickname", "surname", "gender" })
    y = y + gap
    section("background")
    rows({ "archetype", "equipmentMode" })
    y = y + gap
    section("skills")
    local listY = y
    local list = self.inspectorVisible and self.details or self.configuredDetails
    if list then
        Layout.SetBounds(list, 0, listY, formWidth,
            math.min(listHeight, math.max(Layout.Pixels(70, self.uiScale),
                viewHeight * 0.26)))
    end
    if self.configuredDetails then
        self.configuredDetails:setVisible(self.inspectorVisible ~= true
            and self.draft ~= nil)
    end
    if self.details then self.details:setVisible(self.inspectorVisible == true) end
    y = listY + listHeight
    if self.removeConfiguredButton then
        Layout.SetBounds(self.removeConfiguredButton, 0, y,
            Layout.Pixels(80, self.uiScale), sectionHeight)
        self.removeConfiguredButton:setVisible(
            self.inspectorVisible ~= true and self.draft ~= nil)
    end
    if self.removeButton then self.removeButton:setVisible(false) end
    if self.resetDetailsButton then self.resetDetailsButton:setVisible(false) end
    y = y + sectionHeight + gap
    section("traits")
    for _, row in ipairs(self.addRows or {}) do
        local capability = self:fieldCapability(row.fieldID or row.id)
        local visible = capability and capability.visible ~= false
        if visible then
            y = layoutCompanionAddRow(self, row, y, formWidth)
        else
            Layout.SetBounds(row.labelControl, 0, 0, 0, 0)
            Layout.SetBounds(row.button, 0, 0, 0, 0)
            for _, entry in ipairs(row.entries or {}) do
                Layout.SetBounds(entry, 0, 0, 0, 0)
            end
        end
    end
    Layout.SetBounds(self.statusLabel, 0, y, formWidth, sectionHeight)
    y = y + sectionHeight + gap

    if self.formView.setScrollHeight then self.formView:setScrollHeight(y) end
    self.formView.contentHeight = math.max(viewHeight, y)
    self.formView.maxScroll = math.max(0, self.formView.contentHeight - viewHeight)
    self.companionLayout = {
        contentHeight = self.formView.contentHeight,
        collectionY = listY,
        collectionHeight = listHeight,
        statusY = y - sectionHeight - gap,
        statusHeight = sectionHeight,
        scrollBounded = self.formView.contentHeight >= viewHeight,
    }
    return y, listY, true
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

function ISPNCNPCAuthoringEditor:onResponsiveLayout()
    local rect = self:getContentRect({ top = 0, bottom = 0 })
    local leftWidth, viewHeight, portraitX, portraitY, portraitWidth, portraitHeight, top, stacked =
        layoutEditorFrame(self, rect)
    local addY, detailsY, twoColumns
    if self.presentationMode == "companion" then
        addY, detailsY, twoColumns = layoutCompanionForm(self,
            leftWidth, viewHeight)
    else
        addY, detailsY, twoColumns = layoutDebugForm(self,
            leftWidth, viewHeight)
    end
    layoutEditorPortrait(self, portraitX, portraitY, portraitWidth, portraitHeight)
    self.layout = {
        x = rect.x, y = top, leftWidth = leftWidth,
        addY = addY, detailsY = detailsY, portraitX = portraitX,
        portraitY = portraitY, portraitWidth = portraitWidth,
        portraitHeight = portraitHeight,
        twoColumns = twoColumns, stacked = stacked,
        companion = self.companionLayout,
    }
end


