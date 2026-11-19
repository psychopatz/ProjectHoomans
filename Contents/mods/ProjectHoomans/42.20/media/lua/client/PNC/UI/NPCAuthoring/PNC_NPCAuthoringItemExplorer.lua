require 'ISUI/ISPanel'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog'
ISPNCNPCAuthoringItemExplorer = ISPanel:derive('ISPNCNPCAuthoringItemExplorer')
local Explorer = ISPNCNPCAuthoringItemExplorer
local UI, Catalog = PsychopatzCore.UI, PNC.NPCAuthoringCatalog
local L = UI.Layout
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end
local function button(parent, title, callback)
    return UI.CreateButton(parent, { title = title, target = parent, onclick = callback, variant = 'quiet' })
end
local function font(list)
    list.pncSmallFont = true
    if list.setFont then list:setFont(UIFont.Small, 6) end
end
local function category(id)
    local key = 'IGUI_ItemCat_' .. tostring(id)
    local value = getText(key)
    return value ~= key and value or tostring(id)
end
function Explorer:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    setmetatable(o, self); self.__index = self
    o.offset, o.pageSize = 0, 48
    o.options = nil -- idle until Show supplies a browsing session
    o.backgroundColor = { r = 0.055, g = 0.065, b = 0.075, a = 1 }
    return o
end
function Explorer:createChildren()
    ISPanel.createChildren(self)
    self.heading = ISLabel:new(0, 0, 24, '', 1, 1, 1, 1, UIFont.Small, true)
    self.heading:initialise(); self:addChild(self.heading)
    self.hint = ISLabel:new(0, 0, 24, '', .8, .85, .85, 1, UIFont.Small, true)
    self.hint:initialise(); self:addChild(self.hint)
    self.search = UI.CreateTextEntry(self, { maxTextLength = 100,
        onTextChange = function() self.offset = 0; self:refreshResults() end })
    self.search.tooltip = tr('UI_PNC_Authoring_Search', 'Search by name or ID')
    self.sources, self.categories = UI.CreateList(self, {}), UI.CreateList(self, {})
    for _, list in ipairs({ self.sources, self.categories }) do
        font(list)
        list.doDrawItem = function(control, y, entry)
            local h = entry.height or control.itemheight
            if control.drawSelection and control.selected == entry.index then control:drawSelection(0, y, control.width, h) end
            control:drawText(L.Ellipsize(entry.text, UIFont.Small, math.max(1, control.width - 24)), 6, y + 6, .9, .93, .94, 1, UIFont.Small)
            return y + h
        end
        local onMouseMove = list.onMouseMove
        list.onMouseMove = function(control, x, y)
            if onMouseMove then onMouseMove(control, x, y) end
            local index = control.rowAt and control:rowAt(x, y)
            local entry = index and control.items[index]
            control.tooltip = entry and entry.text or nil
        end
    end
    self.sources:setOnMouseDownFunction(self, function(target, row) target.source, target.category, target.offset = row.value, nil, 0; target:refreshResults() end)
    self.categories:setOnMouseDownFunction(self, function(target, row) target.category = row.value; target.offset = 0; target:refreshResults() end)
    self.refreshButton = button(self, tr('UI_PNC_Authoring_Refresh', 'Refresh items'), function(target)
        Catalog.Invalidate(); target.source, target.category, target.offset = nil, nil, 0
        target.selectedID = nil
        if target.options.reloadAllowed then target.allowed = target.options.reloadAllowed() end
        if target.options.onRefresh then target.options.onRefresh(target.allowed) end
        target:refreshResults()
    end)
    self.grid = ISPNCUniqueNPCAppearanceScrollPanel:new(0, 0, 1, 1)
    self.grid:initialise(); self.grid:instantiate(); self:addChild(self.grid)
    self.tiles = {}
    for index = 1, self.pageSize do
        local tile = UI.CreateButton(self.grid, { title = '', target = self, onclick = function(target, clicked)
            if not target:getIsVisible() or not clicked.item then return end
            target.selectedID = clicked.item.id; target:refreshDetails(); target:refreshSelection()
        end, variant = 'quiet' })
        tile.onMouseDoubleClick = function(control)
            if not self:getIsVisible() or not control.item then return true end
            self.selectedID = control.item.id; self:refreshDetails(); self:refreshSelection()
            self:confirmSelection()
            return true
        end
        tile.render = function(control)
            ISButton.render(control)
            local item = control.item
            if not item then return end
            local row = self.customItems ~= nil
            local texture = Catalog.Texture(item)
            if texture then control:drawTextureScaledAspect(texture, 8, 5, control.width - 16, control.height - 30, 1, 1, 1, 1) end
            local label = L.Ellipsize(item.label, UIFont.Small, math.max(1, control.width - 16))
            if row then control:drawText(label, 8, 7, .9, .94, .94, 1, UIFont.Small)
            else control:drawTextCentre(label, control.width / 2, control.height - self.fontHeight - 4, .9, .94, .94, 1, UIFont.Small) end
        end
        self.tiles[index] = tile
    end
    self.details = UI.CreateKeyValueList(self, {}); font(self.details)
    if UI.PortraitPanel then
        self.preview = UI.PortraitPanel:new(0, 0, 1, 1, { zoom = -3, animSetName = false, stateName = 'idle', animate = true })
        self.preview:initialise(); self.preview:instantiate(); self:addChild(self.preview); self.preview:setVisible(false)
    end
    self:buildExplorerPortraitControls()
    self:buildVariantButton()
    self.quantityLabel = ISLabel:new(0, 0, 24, tr('UI_PNC_Authoring_Quantity', 'Quantity / Destination'), .8, .85, .85, 1, UIFont.Small, true)
    self.quantityLabel:initialise(); self:addChild(self.quantityLabel)
    self.quantity = UI.CreateTextEntry(self, { onlyNumbers = true, maxTextLength = 2, text = '1' })
    self.destination = PNC.NPCAuthoringFields.Choice(self, self)
    self.destination:addOptionWithData(tr('UI_PNC_Authoring_Pockets', 'Pockets'), 'root')
    self.destination:addOptionWithData(tr('UI_PNC_Authoring_Bag', 'Bag (when available)'), 'bag'); self.destination:selectData('root')
    self.confirm = button(self, '', function(target) target:confirmSelection() end)
    self.deleteButton = button(self, tr('UI_PNC_Authoring_Delete', 'Delete saved record'), function(target)
        local item = target:currentSelection()
        if not item or not target.options.onDelete then return end
        if target.deleteArmedID ~= item.id then
            target.deleteArmedID = item.id
            target.deleteButton:setTitle(tr('UI_PNC_Authoring_ConfirmDelete', 'Confirm delete'))
            target:setHint(tr('UI_PNC_Authoring_DeleteHint', 'Click Confirm delete to erase this saved record.'))
            return
        end
        local ok, reason = target.options.onDelete(item)
        target.deleteArmedID = nil
        if not ok then target:setHint(tostring(reason)); return end
        target.customItems = target.options.reloadItems and target.options.reloadItems() or {}
        target.selectedID = nil
        target:refreshResults()
        target:setHint(tr('UI_PNC_Authoring_Deleted', 'Saved record deleted'))
    end)
    self.closeButton = button(self, tr('UI_PNC_StartingCompanion_Close', 'Close'), function(target) target:Hide() end)
    self.contextActionButton = button(self, '', function(target)
        local action = target.options and target.options.contextAction
        if action and action.onClick then action.onClick() end
    end)
    self.contextActionButton:setVisible(false)
    self.previous = button(self, '<', function(target) target.offset = math.max(0, target.offset - target.pageSize); target:refreshResults() end)
    self.nextButton = button(self, '>', function(target) if target.offset + target.pageSize < target.total then target.offset = target.offset + target.pageSize; target:refreshResults() end end)
    self.counter = ISLabel:new(0, 0, 24, '', .8, .85, .85, 1, UIFont.Small, true)
    self.counter:initialise(); self:addChild(self.counter)
end
function Explorer:Show(options)
    self:closeVariantDialog()
    self.options = options
    self.allowed, self.onChoose, self.customItems = options.allowed, options.onChoose, options.items
    self.mode = options.mode or 'item'
    self.titleText = options.title or tr('UI_PNC_Authoring_ItemExplorer', 'Item Explorer')
    self.source, self.category, self.offset, self.selectedID, self.selectedItem = nil, nil, 0, options.initialID, nil
    self.deleteArmedID = nil
    self.confirming = false
    self.previewItemID, self.previewIndex = nil, 1
    if self.preview then self.preview:setViewRegion('body', true) end
    self.quantity:setText(tostring(options.initialQuantity or 1)); self.destination:selectData(options.initialDestination or 'root')
    self.confirm:setTitle(options.applyLabel or tr(self.mode == 'outfit' and 'UI_PNC_Authoring_ApplyOutfit' or 'UI_PNC_Authoring_Equip', self.mode == 'outfit' and 'Apply outfit' or 'Equip / Add'))
    self.confirm.tooltip = options.applyTooltip
    local action = options.contextAction
    self.contextActionButton:setTitle(action and action.title or '')
    self.contextActionButton.tooltip = action and action.tooltip or nil
    self.contextActionButton:setVisible(action ~= nil)
    local query = options.initialQuery or ''
    self.search:setText(query)
    if options.initialID then
        local _, _, position = Catalog.Query({
            query = query, allowed = self.allowed, items = self.customItems,
            initialID = options.initialID, limit = 1,
        })
        self.selectedID = options.initialID
        self.offset = position and math.floor((position - 1) / self.pageSize) * self.pageSize or 0
    end
    self:refreshResults()
    self:setVisible(true); self:bringToTop(); self:onResize(); self.search:focus()
    if self.onShown then self.onShown() end
end
function Explorer:confirmSelection()
    if not self:getIsVisible() or self.confirming or self.variantDialog then return false end
    local item = self:currentSelection()
    if not item or not self.onChoose or (self.options.previewRequired ~= false and self.previewReason) or self.allowed and not self.allowed[item.id] then return false end
    local quantity = self.mode == 'carry' and tonumber(self.quantity:getText()) or 1
    if not quantity or quantity < 1 or quantity > 99 or quantity ~= math.floor(quantity) then
        self:setHint(tr('UI_PNC_Authoring_QuantityInvalid', 'Enter a quantity from 1 to 99')); return false
    end
    local option = self.destination.options[self.destination.selected]
    self.confirming = true
    local ok, reason = self.onChoose(item, quantity, self.mode == 'carry' and option and option.data or nil)
    self.confirming = false
    if ok ~= false then self:Hide(); return true end
    self:setHint(reason or tr('UI_PNC_Authoring_UnavailableItem', 'This item is unavailable'))
    return false
end
function Explorer:Hide()
    self:closeVariantDialog()
    self.search:unfocus(); self:setVisible(false)
    if self.preview then self.preview:setVisible(false); self.preview.targetKey = nil end
    if self.onDismiss then self.onDismiss() end
end
local function fillFilter(list, label, values, selected, display)
    list:clear()
    list:addItem(label, {})
    list.selected = 1
    for index, value in ipairs(values) do
        list:addItem(display and display(value) or value, { value = value })
        if value == selected then list.selected = index + 1 end
    end
    if list.selected > 1 then return selected end
end

function Explorer:refreshFilters(query)
    if self.customItems then return end
    local sources, categories = Catalog.Filters(self.allowed, query, self.source)
    local source = fillFilter(self.sources, tr('UI_PNC_Authoring_AllMods', 'All mods / modules'), sources, self.source)
    if source ~= self.source then
        self.source, self.category, self.offset = source, nil, 0
        local _, allCategories = Catalog.Filters(self.allowed, query, source)
        categories = allCategories
    end
    local selected = fillFilter(self.categories, tr('UI_PNC_Authoring_AllCategories', 'All categories'), categories, self.category, category)
    if selected ~= self.category then self.category, self.offset = selected, 0 end
end
function Explorer:currentSelection()
    for _, item in ipairs(self.visibleRows or {}) do if item.id == self.selectedID then return item end end
end
function Explorer:setHint(value)
    self.hintText = value; self:onResize()
end
function Explorer:refreshSelection()
    for _, tile in ipairs(self.tiles) do
        tile.backgroundColor = tile.item and tile.item.id == self.selectedID
            and { r = .10, g = .32, b = .23, a = 1 } or { r = .07, g = .09, b = .11, a = 1 }
    end
end
function Explorer:refreshResults()
    if not self.tiles or not self.options then return end
    local query = self.search:getText()
    self:refreshFilters(query)
    local rows, total = Catalog.Query({ query = query, source = self.source, category = self.category,
        allowed = self.allowed, offset = self.offset, limit = self.pageSize, items = self.customItems })
    self.total, self.visibleRows = total, rows
    if #rows == 0 and total > 0 and self.offset > 0 then self.offset = 0; return self:refreshResults() end
    if not self:currentSelection() then self.selectedID = nil end
    for index, tile in ipairs(self.tiles) do tile.item = rows[index]; tile:setVisible(rows[index] ~= nil); tile.tooltip = rows[index] and rows[index].label end
    PNC.NPCAuthoringFields.EnableButton(self.previous, self.offset > 0); PNC.NPCAuthoringFields.EnableButton(self.nextButton, self.offset + self.pageSize < total)
    self.counter:setName(tostring(total == 0 and 0 or self.offset + 1) .. '-' .. tostring(self.offset + #rows) .. ' / ' .. total)
    self:refreshSelection(); self:refreshDetails(); self:onResize()
end
function Explorer:refreshDetails()
    local item = self:currentSelection()
    self.selectedItem = item
    if not item or self.deleteArmedID ~= item.id then self.deleteArmedID = nil end
    if self.deleteButton then
        self.deleteButton:setVisible(self.options.onDelete ~= nil)
        self.deleteButton:setTitle(tr(self.deleteArmedID and 'UI_PNC_Authoring_ConfirmDelete' or 'UI_PNC_Authoring_Delete', self.deleteArmedID and 'Confirm delete' or 'Delete saved record'))
        PNC.NPCAuthoringFields.EnableButton(self.deleteButton, item ~= nil)
    end
    self.details:clear()
    if item then
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemName', 'Item'), item.label)
        if item.source and item.source ~= '' then UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemSource', 'Mod / module'), item.source) end
        if item.category and item.category ~= '' then UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemCategory', 'Category'), category(item.category)) end
        for _, detail in ipairs(self.options.describe and self.options.describe(item) or {}) do UI.AddKeyValue(self.details, detail.label, detail.value) end
        if not self.customItems then UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemID', 'Item ID'), item.id) end
    end
    self:refreshVariantButton(item)
    self:refreshExplorerPortrait(item)
    local blockingReason = self.options.previewRequired ~= false and self.previewReason
    local compatible = not blockingReason and (not self.allowed or item and self.allowed[item.id] == true)
    PNC.NPCAuthoringFields.EnableButton(self.confirm, item ~= nil and compatible == true)
    self.hintText = blockingReason or tr(not item and (#(self.visibleRows or {}) == 0 and 'UI_PNC_Authoring_NoMatches' or 'UI_PNC_Authoring_SelectResult') or not compatible and 'UI_PNC_Authoring_DoesNotFit' or 'UI_PNC_Authoring_ReviewSelection',
        not item and (#(self.visibleRows or {}) == 0 and 'No matching results' or 'Select a result to review it') or not compatible and 'Does not fit the selected slot' or 'Review the selection, then apply')
    self:onResize()
end
function Explorer:onResize()
    -- Native size setters can resize this hidden child while the host is
    -- constructing itself, before Show has supplied any browsing options.
    if not self.tiles or not self.options then return end
    local g = 8
    self.fontHeight = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16
    local h, width = math.max(28, self.fontHeight + 10), math.max(1, self.width - g * 2)
    local filters = not self.customItems
    local filterWidth = filters and math.min(230, math.max(140, width * .19)) or 0
    local side = (width >= 850 or self.options.preview and width >= 550) and math.min(340, width * .28) or 0
    local x = g + (filters and filterWidth + g or 0)
    local contentWidth = math.max(1, width - (filters and filterWidth + g or 0) - (side > 0 and side + g or 0))
    self.heading:setName(L.Ellipsize(self.titleText or '', UIFont.Small, math.max(1, width - 110))); self.heading.tooltip = self.titleText
    L.SetBounds(self.heading, g, g, width - 110, h); L.SetBounds(self.closeButton, self.width - 100 - g, g, 100, h)
    local contextHeight = self.options.contextAction and h + g or 0
    L.SetBounds(self.contextActionButton, g, h + g * 2, width, h)
    local filterActions = filters and 128 or 0
    L.SetBounds(self.search, g, h + g * 2 + contextHeight, width - filterActions, h)
    self.refreshButton:setVisible(filters)
    L.SetBounds(self.refreshButton, self.width - 120 - g, h + g * 2 + contextHeight, 120, h)
    local carry = self.mode == 'carry'
    self.quantityLabel:setVisible(carry); self.quantity:setVisible(carry); self.destination:setVisible(carry)
    local top = h * 2 + g * 3 + contextHeight
    local bottom = carry and h * 5 + g * 7 or h * 3 + g * 5
    local hasVariants = self.variantButton:getIsVisible()
    local changeHeight = h + 4
    if side == 0 and hasVariants then bottom = bottom + changeHeight + g end
    local gridHeight = math.max(h * 2, self.height - top - bottom)
    self.sources:setVisible(filters); self.categories:setVisible(filters)
    L.SetBounds(self.sources, g, top, filterWidth, math.max(1, gridHeight * .48))
    L.SetBounds(self.categories, g, top + gridHeight * .5, filterWidth, math.max(1, gridHeight * .5))
    local columns = self.customItems and math.max(1, math.floor(contentWidth / 270)) or math.max(1, math.floor(contentWidth / 120))
    local rows = math.ceil(#(self.visibleRows or {}) / columns)
    local tileWidth, tileHeight = contentWidth / columns, self.customItems and h + 12 or math.max(90, h * 2 + 30)
    L.SetBounds(self.grid, x, top, contentWidth, gridHeight)
    self.grid.contentHeight = rows * tileHeight; self.grid.maxScroll = math.max(0, self.grid.contentHeight - gridHeight)
    self.grid:setScrollHeight(self.grid.contentHeight); self.grid:setYScroll(math.max(-self.grid.maxScroll, math.min(0, self.grid:getYScroll()))); self.grid:onResize()
    for index, tile in ipairs(self.tiles) do L.SetBounds(tile, (index - 1) % columns * tileWidth, math.floor((index - 1) / columns) * tileHeight, tileWidth - 5, tileHeight - 5) end
    self.details:setVisible(side > 0)
    local detailY, detailHeight = self:layoutExplorerPortrait(x + contentWidth + g, top, side, gridHeight, h, g)
    if side > 0 and hasVariants then
        local changeWidth = math.min(210, side)
        local changeX = x + contentWidth + g + (side - changeWidth) / 2
        L.SetBounds(self.variantButton, changeX, detailY, changeWidth, changeHeight)
        detailY, detailHeight = detailY + changeHeight + g, detailHeight - changeHeight - g
    end
    L.SetBounds(self.details, x + contentWidth + g, detailY, side, math.max(1, detailHeight))
    local y = top + gridHeight + g
    self:positionVariantDialog()
    L.SetBounds(self.previous, x, y, 40, h); L.SetBounds(self.counter, x + 48, y, math.max(1, contentWidth - 96), h); L.SetBounds(self.nextButton, x + contentWidth - 40, y, 40, h)
    y = y + h + g
    self.hint:setName(L.Ellipsize(self.hintText or '', UIFont.Small, contentWidth)); self.hint.tooltip = self.hintText
    local selected = self:currentSelection()
    if selected then self.hint.tooltip = self.hint.tooltip .. "\n" .. selected.label .. "\n" .. tostring(selected.source or "") .. "\n" .. tostring(selected.id) end
    L.SetBounds(self.hint, x, y, contentWidth, h); y = y + h + g
    if side == 0 and hasVariants then
        local changeWidth = math.min(210, contentWidth)
        L.SetBounds(self.variantButton, x + (contentWidth - changeWidth) / 2, y, changeWidth, changeHeight)
        y = y + changeHeight + g
    end
    if carry then
        L.SetBounds(self.quantityLabel, x, y, contentWidth, h); y = y + h
        L.SetBounds(self.quantity, x, y, math.max(1, contentWidth * .15 - g), h)
        L.SetBounds(self.destination, x + contentWidth * .15, y, contentWidth * .85, h); self.destination:onResize(); y = y + h + g
    end
    local actionWidth = math.max(1, math.min(self.options.onDelete and (contentWidth - g) / 2 or contentWidth, 340))
    local totalActionWidth = self.options.onDelete and actionWidth * 2 + g or actionWidth
    local actionX = x + math.max(0, (contentWidth - totalActionWidth) / 2)
    L.SetBounds(self.confirm, actionX, y, actionWidth, h)
    L.SetBounds(self.deleteButton, actionX + actionWidth + g, y, actionWidth, h)
    PNC.NPCAuthoringFields.NativeMetrics(self)
end
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringExplorerPortrait'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringVariantDialog'
return Explorer
