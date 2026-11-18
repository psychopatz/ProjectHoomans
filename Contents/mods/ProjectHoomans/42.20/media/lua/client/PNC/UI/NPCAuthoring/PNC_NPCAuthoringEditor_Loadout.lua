require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringSlots'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringItemExplorer'
local Window, UI = ISPNCNPCAuthoringEditor, PsychopatzCore.UI
local I, L = Window.Internal, UI.Layout
local Catalog, Edits, Slots = PNC.NPCAuthoringCatalog, PNC.NPCAuthoringLoadout, PNC.NPCAuthoringSlots
local tr = I.tr
local function button(parent, target, title, callback)
    return UI.CreateButton(parent, { title = title, target = target, onclick = callback, variant = 'quiet' })
end
function Window:buildLoadoutPage()
    local page = self.pages.loadout
    self.appearanceTab.outfitLabel:setVisible(false)
    self.appearanceTab.outfitCombo:setVisible(false)
    for _, row in ipairs(self.coreRows) do
        if row.id == 'equipmentMode' then
            self.formView:removeChild(row.entry); self.formView:removeChild(row.labelControl)
            page:addChild(row.entry); page:addChild(row.labelControl); self.loadoutModeRow = row
        end
    end
    self.outfitBrowse = button(page, self, tr('UI_PNC_Authoring_BrowseOutfits', 'Browse outfits'), function(target) target:browseOutfits() end)
    self.outfitValue = I.addLabel(page, '')
    self.slotContent = ISPNCUniqueNPCAppearanceScrollPanel:new(0, 0, 1, 1)
    self.slotContent:initialise(); self.slotContent:instantiate(); page:addChild(self.slotContent)
    self.slotTiles, self.slotHeaders = {}, {}
    self.itemExplorer = ISPNCNPCAuthoringItemExplorer:new(0, 0, 1, 1)
    self.itemExplorer:initialise(); self.itemExplorer:instantiate(); self:addChild(self.itemExplorer)
    self.itemExplorer.onDismiss = function() self:requestResponsiveLayout() end
    self.itemExplorer:setVisible(false)
end
function Window:browseOutfits()
    local items = {}
    for _, option in ipairs(self.appearanceTab.outfitCombo.options or {}) do
        items[#items + 1] = { id = option.data, label = option.text, search = string.lower(option.text), category = '', source = '' }
    end
    self.itemExplorer:Show({ title = tr('UI_PNC_Authoring_BrowseOutfits', 'Browse outfits'), items = items,
        onChoose = function(item)
            local ok = self.appearanceTab:onOutfitChanged({ selected = 1, options = { { data = item.id } } })
            return ok ~= false, ok == false and tr('UI_PNC_Authoring_UnavailableOutfit', 'This outfit is unavailable') or nil
        end })
    self:requestResponsiveLayout()
end
function Window:openSlot(slot)
    if not self.draft then return end
    if self:pullForm() == false then return end
    self.loadoutSlot = slot
    local allowed
    if slot.kind == 'worn' then
        allowed = {}
        for _, item in ipairs(Catalog.Clothing(slot.id)) do allowed[item.id] = true end
    end
    self.itemExplorer:Show({ title = slot.label, allowed = allowed,
        onChoose = function(item, quantity, destination) return self:applyLoadout(slot, item.id, quantity, destination) end })
    self:requestResponsiveLayout()
end
function Window:applyLoadout(slot, fullType, quantity, destination)
    if not self.draft then return false end
    local capability = self:fieldCapability(slot.kind == 'worn' and 'appearance' or 'startingItems')
    if capability.editable == false then return false, capability.sourceLabel end
    local spec, native, reason
    local targetSlot = slot
    if fullType then
        native, reason = Catalog.Create(fullType)
        if not native then return false, tr('UI_PNC_Authoring_UnavailableItem', 'This item is unavailable') end
        spec, reason = PNC.Inventory.CaptureNativeItem(native)
        if not spec then return false, tostring(reason) end
        spec.stack = slot.kind == 'carry' and quantity or 1
        if spec.maxWeight then spec.stack = 1 end
        spec.preferredContainer = destination == 'bag' and 'bag' or nil
        if slot.kind == 'attach' then
            local occupied = {}
            for _, item in ipairs(self.draft.startingItems or {}) do if item.attachedSlot then occupied[item.attachedSlot] = true end end
            local location = PNC.Equipment.ResolveAttachedLocation(native, nil, occupied)
            if not location then return false, tr('UI_PNC_Authoring_Incompatible', 'No compatible free slot') end
            targetSlot = { kind = 'attached', id = location }
        end
        if slot.kind == 'held' then
            for _, item in ipairs(self.draft.startingItems or {}) do
                if item.equipSlot and item.equipSlot ~= slot.id then
                    local other = Catalog.Create(item.type)
                    if native:isTwoHandWeapon() or other and other:isTwoHandWeapon() then
                        return false, tr('UI_PNC_Authoring_TwoHands', 'Clear the other hand before equipping a two-handed item')
                    end
                end
            end
        end
    elseif slot.kind == 'carry' or slot.kind == 'attach' then return false end
    local candidate = PNC.NPCAuthoring.Registry.Copy(self.draft)
    local record = self.previewDraft and self.previewDraft.runtimeRecord
    local ok
    ok, reason = Edits.SetSlot(candidate, targetSlot, spec, record)
    if not ok then return false, tr('UI_PNC_Authoring_ClothingConflict', 'Clothing conflicts with another slot') end
    local valid
    valid, reason = I.Model.BuildBlueprint(candidate)
    if not valid then return false, tostring(reason) end
    self.draft = candidate
    self:syncControls(); self:refreshPreview(false)
    return true
end
function Window:refreshLoadoutPage()
    if not self.slotContent then return end
    local rows = self.draft and Slots.Build(self.draft, self.previewDraft and self.previewDraft.runtimeRecord) or {}
    self.slotRows = rows
    for index, slot in ipairs(rows) do
        local tile = self.slotTiles[index]
        if not tile then
            tile = button(self.slotContent, self, '', function(target, clicked) target:openSlot(clicked.slot) end)
            tile.render = function(control)
                ISButton.render(control)
                local row = control.slot
                if not row then return end
                local item = row.type and Catalog.Find(row.type)
                local texture = item and item.script:getNormalTexture()
                if texture then control:drawTextureScaledAspect(texture, 8, 5, control.width - 16, control.height - 31, 1, 1, 1, 1) end
                control:drawTextCentre(L.Ellipsize(row.label, UIFont.Small, math.max(1, control.width - 8)), control.width / 2,
                    control.height - (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) - 4, 0.88, 0.93, 0.94, 1, UIFont.Small)
            end
            tile.clear = button(self.slotContent, self, '×', function(target, clicked)
                local ok, reason = target:applyLoadout(clicked.slot)
                if not ok and reason then target:setStatus(reason) end
            end)
            self.slotTiles[index] = tile
        end
        tile.slot, tile.clear.slot = slot, slot
        local entry = slot.type and Catalog.Find(slot.type)
        tile.tooltip = slot.label .. '\n' .. (entry and entry.label or slot.type and (tr('UI_PNC_Authoring_UnavailableItem', 'This item is unavailable') .. ': ' .. slot.type) or tr('UI_PNC_Authoring_EmptySlot', 'Empty / generated slot'))
        tile:setVisible(true)
        tile.clear:setVisible(slot.kind ~= 'carry' and slot.kind ~= 'attach')
    end
    for index = #rows + 1, #self.slotTiles do self.slotTiles[index]:setVisible(false); self.slotTiles[index].clear:setVisible(false) end
    self:layoutSlotTiles()
    local outfit = self.draft and self.draft.appearance and self.draft.appearance.outfit
    local outfitID = outfit and outfit.mode == 'item' and 'named:' .. tostring(outfit.id) or outfit and outfit.mode or 'random'
    local label = ''
    for _, option in ipairs(self.appearanceTab.outfitCombo.options or {}) do if option.data == outfitID then label = option.text end end
    self.outfitCaption = label
    self.outfitValue:setName(label)
end
function Window:layoutSlotTiles()
    if not self.slotContent then return end
    local g, tileSize = L.Pixels(8, self.uiScale), L.Pixels(86, self.uiScale)
    local width = math.max(1, self.slotContent.width - 18)
    local columns = math.max(1, math.floor((width + g) / (tileSize + g)))
    local tileWidth = math.max(1, (width - g * (columns - 1)) / columns)
    local groups = {}
    for _, group in ipairs(Slots.Groups()) do groups[#groups + 1] = group end
    groups[#groups + 1] = { id = 'held', key = 'Held', label = 'Held items and attachments' }
    groups[#groups + 1] = { id = 'carry', key = 'Carried', label = 'Carried items' }
    local y, headerIndex = 0, 0
    for _, group in ipairs(groups) do
        local members = {}
        for index, row in ipairs(self.slotRows or {}) do if row.group == group.id then members[#members + 1] = index end end
        if #members > 0 then
            headerIndex = headerIndex + 1
            local label = self.slotHeaders[headerIndex] or I.addLabel(self.slotContent, '')
            self.slotHeaders[headerIndex] = label
            label:setName(tr('UI_PNC_Authoring_Group_' .. group.key, group.label)); label:setVisible(true)
            L.SetBounds(label, 0, y, width, L.Pixels(26, self.uiScale)); y = y + L.Pixels(30, self.uiScale)
            for order, index in ipairs(members) do
                local x, top = (order - 1) % columns * (tileWidth + g), y + math.floor((order - 1) / columns) * (tileSize + g)
                local tile = self.slotTiles[index]
                L.SetBounds(tile, x, top, tileWidth, tileSize)
                local clearSize = math.min(tileWidth, math.max(L.Pixels(22, self.uiScale),
                    (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) + 6))
                L.SetBounds(tile.clear, x + tileWidth - clearSize, top, clearSize, clearSize)
            end
            y = y + math.ceil(#members / columns) * (tileSize + g)
        end
    end
    for index = headerIndex + 1, #self.slotHeaders do self.slotHeaders[index]:setVisible(false) end
    self.slotContent.contentHeight = y
    self.slotContent.maxScroll = math.max(0, y - self.slotContent.height)
    self.slotContent:setScrollHeight(y)
    self.slotContent:setYScroll(math.max(-self.slotContent.maxScroll, math.min(0, self.slotContent:getYScroll())))
    self.slotContent:onResize()
end
function Window:layoutLoadoutPage(width, height, rowHeight, gap)
    local w = math.max(1, width - gap * 2 - 16)
    L.SetBounds(self.outfitBrowse, gap, gap, math.min(w, L.Pixels(170, self.uiScale)), rowHeight)
    self.outfitValue:setName(L.Ellipsize(self.outfitCaption or "", UIFont.Small, w))
    self.outfitValue.tooltip = self.outfitCaption
    L.SetBounds(self.outfitValue, gap, gap + rowHeight, w, rowHeight)
    L.SetBounds(self.loadoutModeRow.labelControl, gap, rowHeight * 2 + gap * 2, w, rowHeight)
    self.loadoutModeRow.labelControl:setVisible(true); self.loadoutModeRow.entry:setVisible(true)
    L.SetBounds(self.loadoutModeRow.entry, gap, rowHeight * 3 + gap * 2, math.min(w, L.Pixels(360, self.uiScale)), rowHeight * 2 + 4)
    self.loadoutModeRow.entry:onResize()
    local top = rowHeight * 5 + gap * 3 + 4
    local contentHeight = math.max(rowHeight * 3, height - top - gap)
    L.SetBounds(self.slotContent, gap, top, w, contentHeight)
    local page = self.pages.loadout
    page.contentHeight = top + contentHeight + gap
    page.maxScroll = math.max(0, page.contentHeight - height)
    page:setScrollHeight(page.contentHeight); page:onResize()
    self:layoutSlotTiles()
    if self.itemExplorer then
        L.SetBounds(self.itemExplorer, 0, 0, self.width, self.height)
        self.itemExplorer:onResize()
    end
end
return Window
