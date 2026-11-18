-- Body-part navigation and equipment tiles; editing stays in the loadout model.
local Window, UI = ISPNCNPCAuthoringEditor, PsychopatzCore.UI
local I, L = Window.Internal, UI.Layout
local Slots, Catalog, Fields = PNC.NPCAuthoringSlots, PNC.NPCAuthoringCatalog, PNC.NPCAuthoringFields
function Window:buildLoadoutNavigation()
    self.loadoutPart = 'torso'
    self.loadoutParts = {}
    for _, group in ipairs(Slots.Groups()) do
        local control = UI.CreateButton(self.pages.loadout, { title = I.tr('UI_PNC_Authoring_Group_' .. group.key, group.label),
            target = self, variant = 'quiet', onclick = function(target)
                target.loadoutPart = group.id
                target.slotContent:setYScroll(0)
                target.pages.loadout:setYScroll(0)
                target:refreshLoadoutPage(); target:requestResponsiveLayout()
            end })
        control.part = group
        self.loadoutParts[#self.loadoutParts + 1] = control
    end
    self:buildCarriedInventory()
end
function Window:refreshLoadoutNavigation()
    local counts = {}
    for _, row in ipairs(self.slotRows or {}) do
        counts[row.group] = counts[row.group] or { total = 0, equipped = 0 }
        counts[row.group].total = counts[row.group].total + 1
        if row.type then counts[row.group].equipped = counts[row.group].equipped + 1 end
    end
    if not counts[self.loadoutPart] then self.loadoutPart = 'carry' end
    for _, button in ipairs(self.loadoutParts) do
        local group, count = button.part, counts[button.part.id]
        local title = I.tr('UI_PNC_Authoring_Group_' .. group.key, group.label)
        button:setTitle(title .. ' (' .. tostring(count and count.equipped or 0) .. ')')
        button.pncPartVisible = count ~= nil
        button:setVisible(count ~= nil)
        Fields.SelectButton(button, self.loadoutPart == group.id, true)
    end
    self:refreshCarriedInventory()
end
function Window:layoutSlotTiles()
    if not self.slotContent then return end
    local gap, size = L.Pixels(8, self.uiScale), L.Pixels(100, self.uiScale)
    local width = math.max(1, self.slotContent.width - 18)
    local columns = math.max(1, math.floor((width + gap) / (size + gap)))
    local tileWidth = math.max(1, (width - gap * (columns - 1)) / columns)
    local order = 0
    for index, row in ipairs(self.slotRows or {}) do
        local tile = self.slotTiles[index]
        local visible = row.group == self.loadoutPart and self.loadoutPart ~= 'carry'
        tile:setVisible(visible); tile.clear:setVisible(visible and row.type ~= nil)
        if visible then
            local x, y = order % columns * (tileWidth + gap), math.floor(order / columns) * (size + gap)
            L.SetBounds(tile, x, y, tileWidth, size)
            local clearSize = math.min(tileWidth, math.max(L.Pixels(22, self.uiScale), (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) + 6))
            L.SetBounds(tile.clear, x + tileWidth - clearSize, y, clearSize, clearSize)
            order = order + 1
        end
    end
    local height = math.ceil(order / columns) * (size + gap)
    self.slotContent.contentHeight, self.slotContent.maxScroll = height, math.max(0, height - self.slotContent.height)
    self.slotContent:setScrollHeight(height)
    self.slotContent:setYScroll(math.max(-self.slotContent.maxScroll, math.min(0, self.slotContent:getYScroll())))
    self.slotContent:onResize()
end
function Window:layoutLoadoutPage(width, height, rowHeight, gap)
    local w, y = math.max(1, width - gap * 2 - 16), rowHeight + gap * 2
    local carry = self.loadoutPart == 'carry'
    self.outfitBrowse:setVisible(not carry); self.outfitValue:setVisible(not carry)
    self.loadoutModeRow.labelControl:setVisible(not carry); self.loadoutModeRow.entry:setVisible(not carry)
    if not carry then
        local browseWidth = math.min(w, L.Pixels(170, self.uiScale))
        L.SetBounds(self.outfitBrowse, gap, y, browseWidth, rowHeight)
        L.SetBounds(self.outfitValue, gap + browseWidth + gap, y, math.max(1, w - browseWidth - gap), rowHeight)
        self.outfitValue:setName(L.Ellipsize(self.outfitCaption or '', UIFont.Small, math.max(1, w - browseWidth - gap)))
        self.outfitValue.tooltip = self.outfitCaption
        y = y + rowHeight + gap
        L.SetBounds(self.loadoutModeRow.labelControl, gap, y, w, rowHeight); y = y + rowHeight
        local columns = w >= L.Pixels(500, self.uiScale) and 4 or 2
        self.loadoutModeRow.entry.columns = columns
        local choiceHeight = rowHeight * (columns == 4 and 1 or 2) + (columns == 4 and 0 or 4)
        L.SetBounds(self.loadoutModeRow.entry, gap, y, math.min(w, L.Pixels(650, self.uiScale)), choiceHeight)
        self.loadoutModeRow.entry:onResize(); y = y + choiceHeight + gap
    end
    local controls = {}
    for _, control in ipairs(self.loadoutParts or {}) do if control.pncPartVisible then controls[#controls + 1] = control end end
    local nav = L.Flow(controls, { x = gap, y = y, width = w }, { scale = self.uiScale, minWidth = 100, gap = 5 })
    y = nav.bottom + gap
    local h = math.max(rowHeight * 3, height - y - gap)
    self.slotContent:setVisible(not carry); self.carriedPanel:setVisible(carry)
    L.SetBounds(self.slotContent, gap, y, w, h)
    local inventoryHeight = self:layoutCarriedInventory(gap, y, w, h, rowHeight, gap)
    if carry then h = inventoryHeight end
    local page = self.pages.loadout
    page.contentHeight, page.maxScroll = y + h + gap, math.max(0, y + h + gap - height)
    page:setScrollHeight(page.contentHeight); page:onResize()
    page:setYScroll(math.max(-page.maxScroll, math.min(0, page:getYScroll())))
    self:layoutSlotTiles()
    if self.itemExplorer then L.SetBounds(self.itemExplorer, 0, 0, self.width, self.height); self.itemExplorer:onResize() end
end
return Window
