-- Carried consumables/currency are a list, not body-location equipment slots.
local Window, UI = ISPNCNPCAuthoringEditor, PsychopatzCore.UI
local I, L = Window.Internal, UI.Layout
local function tr(k, text) return I.tr(k, text) end
function Window:buildCarriedInventory()
    self.carriedPanel = ISPanel:new(0, 0, 1, 1)
    self.carriedPanel:initialise(); self.carriedPanel:instantiate(); self.pages.loadout:addChild(self.carriedPanel)
    self.carriedList = UI.CreateList(self.carriedPanel, { itemHeight = 56 })
    self.carriedList.doDrawItem = function(list, y, entry, alternate)
        local row = entry.item
        UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
        local item = PNC.NPCAuthoringCatalog.Find(row.type)
        local texture = item and item.script:getNormalTexture()
        if texture then list:drawTextureScaledAspect(texture, 6, y + 6, 36, 36, 1, 1, 1, 1) end
        list:drawText(L.Ellipsize(item and item.label or row.type or '', UIFont.Small, math.max(1, list.width - 70)), 48, y + 4, .95, .95, .95, 1, UIFont.Small)
        local destination = row.destination == 'bag' and tr('UI_PNC_Authoring_Bag', 'Bag (when available)') or tr('UI_PNC_Authoring_Pockets', 'Pockets')
        list:drawText(L.Ellipsize('×' .. tostring(row.quantity) .. '  ' .. destination, UIFont.Small, math.max(1, list.width - 70)), 48, y + list.itemheight / 2, .65, .75, .78, 1, UIFont.Small)
        return y + list.itemheight
    end
    self.carriedActions = {}
    for _, spec in ipairs({ { 'add', 'AddItem', 'Add carried item or bag' }, { 'edit', 'EditCarried', 'Edit quantity / destination' }, { 'remove', 'RemoveCarried', 'Remove item' } }) do
        local action = spec[1]
        self.carriedActions[#self.carriedActions + 1] = UI.CreateButton(self.carriedPanel, {
            title = tr('UI_PNC_Authoring_' .. spec[2], spec[3]), target = self, variant = 'quiet',
            onclick = function(target)
                if action == 'add' then return target:openSlot({ kind = 'carry', id = 'new', group = 'carry', label = tr('UI_PNC_Authoring_AddItem', 'Add carried item or bag') }) end
                local entry = target.carriedList.items[target.carriedList.selected]
                if not entry then return end
                if action == 'edit' then return target:openSlot(entry.item) end
                local ok, reason = target:applyLoadout(entry.item)
                if not ok and reason then target:setStatus(reason) end
            end })
    end
    self.carriedList:setOnMouseDownFunction(self, function(target) target:refreshCarriedActions() end)
end
function Window:refreshCarriedActions()
    local selected = self.carriedList.items[self.carriedList.selected] ~= nil
    local editable = self:fieldCapability('startingItems').editable ~= false
    for index, button in ipairs(self.carriedActions) do PNC.NPCAuthoringFields.EnableButton(button, editable and (index == 1 or selected)) end
end
function Window:refreshCarriedInventory()
    if not self.carriedList then return end
    local previous = self.carriedList.items[self.carriedList.selected]
    local id = previous and previous.item.id
    self.carriedList:clear()
    for _, row in ipairs(self.slotRows or {}) do
        if row.group == 'carry' and row.kind == 'item' then
            self.carriedList:addItem(row.type, row)
            if row.id == id then self.carriedList.selected = #self.carriedList.items end
        end
    end
    self:refreshCarriedActions()
end
function Window:layoutCarriedInventory(x, y, width, height, rowHeight, gap)
    L.SetBounds(self.carriedPanel, x, y, width, height)
    self.carriedList.itemheight = math.max(L.Pixels(56, self.uiScale), (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) * 2 + 14)
    local actions = L.Flow(self.carriedActions, { x = 0, y = 0, width = width }, { scale = self.uiScale, minWidth = 120, gap = gap })
    local usedHeight = math.max(height, actions.bottom + gap + rowHeight * 2)
    L.SetBounds(self.carriedPanel, x, y, width, usedHeight)
    L.SetBounds(self.carriedList, 0, actions.bottom + gap, width, usedHeight - actions.bottom - gap)
    return usedHeight
end
return Window
