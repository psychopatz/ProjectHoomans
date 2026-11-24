-- Compact grouped collection editing over the existing canonical field paths.
local Window = ISPNCNPCAuthoringEditor
local I, UI = Window.Internal, PsychopatzCore.UI
local L, tr = UI.Layout, I.tr
function Window:buildAttributeGroups()
    self.attributeGroups = {}
    for _, row in ipairs(self.addRows) do
        row.browse = UI.CreateButton(self.pages.attributes, { title = row.label, target = self,
            onclick = function(target) target:browseAttribute(row) end, variant = 'quiet' })
        row.configured = UI.CreateList(self.pages.attributes, { doDrawItem = I.drawDetail })
        row.configured.pncSmallFont = true
        if row.configured.setFont then row.configured:setFont(UIFont.Small, 6) end
        row.remove = UI.CreateButton(self.pages.attributes, { title = tr('UI_PNC_UniqueNPCEditor_Remove', 'Remove'), target = self,
            onclick = function(target)
                local selected = row.configured:getItem()
                if selected then target:removeConfiguredRow(selected.item) end
            end, variant = 'quiet' })
        row.empty = I.addLabel(self.pages.attributes, tr('UI_PNC_Authoring_NoConfigured', 'No entries yet'))
        row.configured:setOnMouseDownFunction(self, function(target, value)
            if row.id == 'skill' and value then
                I.selectCombo(target.skillCombo, value.key)
                local currentLevel = target.draft and target.draft.skillLevels
                    and target.draft.skillLevels[value.key]
                if currentLevel == nil then currentLevel = value.level end
                if currentLevel ~= nil then
                    target.skillLevelCombo:selectData(tonumber(currentLevel))
                    target.skillLevelCombo:refreshValue()
                end
            end
        end)
        self.attributeGroups[#self.attributeGroups + 1] = row
    end
end
function Window:browseAttribute(row)
    if not self.draft or self:fieldCapability(row.fieldID).editable == false then return end
    local items = {}
    for _, option in ipairs(row.entries[1].options or {}) do
        items[#items + 1] = { id = option.data, label = option.text, search = string.lower(option.text) }
    end
    self.itemExplorer:Show({ mode = 'choice', title = row.label, items = items,
        applyLabel = tr('UI_PNC_Authoring_Choose', 'Choose'), onChoose = function(item)
            I.selectCombo(row.entries[1], item.id)
            if row.id == 'skill' then row.browse:setTitle(item.label) end
            if row.id ~= 'skill' then self:addTrait(row.id, row.entries[1]) end
            return true
        end })
    self:requestResponsiveLayout()
end
function Window:refreshAttributeGroups()
    for _, group in ipairs(self.attributeGroups or {}) do
        group.configured:clear()
        if group.id == 'skill' then
            local option = self.skillCombo.options[self.skillCombo.selected]
            if option then group.browse:setTitle(option.text) end
        end
        for _, row in ipairs(self.configuredRows or {}) do
            if row.kind == group.id then group.configured:addItem(row.label, row) end
        end
        group.configured.selected = #group.configured.items > 0 and 1 or 0
        PNC.NPCAuthoringFields.EnableButton(group.remove, #group.configured.items > 0 and self:fieldCapability(group.fieldID).editable ~= false)
        group.empty:setVisible(#group.configured.items == 0)
    end
end
function Window:layoutAttributeGroups(width, rowHeight, gap)
    local w = math.max(1, width - gap * 2 - 16)
    local columns = w >= L.Pixels(700, self.uiScale) and 2 or 1
    local cell = (w - gap * (columns - 1)) / columns
    local groupHeight = rowHeight * 7 + gap * 4
    local visible = 0
    for _, row in ipairs(self.attributeGroups) do
        local cap = self:fieldCapability(row.fieldID)
        local show = cap.visible ~= false
        for _, control in ipairs({ row.labelControl, row.browse, row.configured, row.remove }) do control:setVisible(show) end
        for _, entry in ipairs(row.entries) do entry:setVisible(false) end
        row.button:setVisible(show and row.id == 'skill')
        row.browse:setEnable(cap.editable ~= false)
        row.empty:setVisible(show and #row.configured.items == 0)
        if show then
            local x, y = gap + visible % columns * (cell + gap), rowHeight + gap * 2 + math.floor(visible / columns) * groupHeight
            L.SetBounds(row.labelControl, x, y, cell, rowHeight)
            y = y + rowHeight + gap
            if row.id == 'skill' then
                local levelWidth, addWidth = math.min(112, cell * .3), math.min(64, cell * .18)
                L.SetBounds(row.browse, x, y, math.max(1, cell - levelWidth - addWidth - gap * 2), rowHeight)
                self.skillLevelCombo:setVisible(true)
                L.SetBounds(self.skillLevelCombo, x + cell - levelWidth - addWidth - gap, y, levelWidth, rowHeight)
                self.skillLevelCombo:onResize()
                L.SetBounds(row.button, x + cell - addWidth, y, addWidth, rowHeight)
            else L.SetBounds(row.browse, x, y, math.min(cell, L.Pixels(340, self.uiScale)), rowHeight) end
            y = y + rowHeight + gap
            L.SetBounds(row.configured, x, y, cell, rowHeight * 3)
            row.configured.itemheight = rowHeight
            L.SetBounds(row.empty, x + gap, y + rowHeight, cell - gap * 2, rowHeight)
            L.SetBounds(row.remove, x, y + rowHeight * 3 + gap, math.min(cell, L.Pixels(130, self.uiScale)), rowHeight)
            visible = visible + 1
        end
    end
    self.configuredDetails:setVisible(false); self.removeConfiguredButton:setVisible(false)
    local page = self.pages.attributes
    page.contentHeight = math.max(page.height, math.ceil(visible / columns) * groupHeight + rowHeight + gap * 2)
    page.maxScroll = math.max(0, page.contentHeight - page.height)
    page:setScrollHeight(page.contentHeight); page:setYScroll(math.max(-page.maxScroll, math.min(0, page:getYScroll()))); page:onResize()
end
return Window
