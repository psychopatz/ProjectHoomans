require 'ISUI/ISPanel'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog'
ISPNCNPCAuthoringItemExplorer = ISPanel:derive('ISPNCNPCAuthoringItemExplorer')
local Explorer = ISPNCNPCAuthoringItemExplorer
local UI, Catalog = PsychopatzCore.UI, PNC.NPCAuthoringCatalog
local L = UI.Layout
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end
local function button(parent, text, action)
    return UI.CreateButton(parent, { title = text, target = parent, onclick = action, variant = 'quiet' })
end
function Explorer:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    setmetatable(o, self); self.__index = self
    o.offset, o.pageSize, o.compatibleOnly = 0, 48, true
    o.backgroundColor = { r = 0.055, g = 0.065, b = 0.075, a = 1 }
    return o
end
function Explorer:createChildren()
    ISPanel.createChildren(self)
    self.heading = ISLabel:new(0, 0, 24, tr('UI_PNC_Authoring_ItemExplorer', 'Item Explorer'), 1, 1, 1, 1, UIFont.Small, true)
    self.heading:initialise(); self:addChild(self.heading)
    self.search = UI.CreateTextEntry(self, { maxTextLength = 100,
        onTextChange = function() self.offset = 0; self:refreshResults() end })
    self.sources, self.categories = UI.CreateList(self, {}), UI.CreateList(self, {})
    self.sources:setOnMouseDownFunction(self, function(target, row) target.source = row.value; target.offset = 0; target:refreshResults() end)
    self.categories:setOnMouseDownFunction(self, function(target, row) target.category = row.value; target.offset = 0; target:refreshResults() end)
    self.compatible = button(self, tr('UI_PNC_Authoring_Compatible', 'Compatible only'), function(target)
        target.compatibleOnly = not target.compatibleOnly; target.offset = 0; target:refreshResults()
    end)
    self.refreshButton = button(self, tr('UI_PNC_Authoring_Refresh', 'Refresh items'), function(target)
        Catalog.Invalidate(); target.source, target.category, target.offset = nil, nil, 0
        target:refreshFilters(); target:refreshResults()
    end)
    self.grid = ISPNCUniqueNPCAppearanceScrollPanel:new(0, 0, 1, 1)
    self.grid:initialise(); self.grid:instantiate(); self:addChild(self.grid)
    self.tiles = {}
    for index = 1, self.pageSize do
        local tile = UI.CreateButton(self.grid, { title = '', target = self, onclick = function(target, clicked) target.selectedItem = clicked.item; target:refreshDetails() end, variant = 'quiet' })
        tile.render = function(control)
            ISButton.render(control)
            local item = control.item
            if not item then return end
            local texture = item.script and item.script:getNormalTexture()
            if texture then control:drawTextureScaledAspect(texture, 10, 5, control.width - 20, control.height - 30, 1, 1, 1, 1) end
            control:drawTextCentre(L.Ellipsize(item.label, UIFont.Small, math.max(1, control.width - 8)),
                control.width / 2, control.height - (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) - 4, 0.9, 0.94, 0.94, 1, UIFont.Small)
        end
        self.tiles[index] = tile
    end
    self.details = UI.CreateKeyValueList(self, {})
    self.quantityLabel = ISLabel:new(0, 0, 24, tr('UI_PNC_Authoring_Quantity', 'Quantity / Destination'), 0.8, 0.85, 0.85, 1, UIFont.Small, true)
    self.quantityLabel:initialise(); self:addChild(self.quantityLabel)
    self.quantity = UI.CreateTextEntry(self, { onlyNumbers = true, maxTextLength = 2, text = '1' })
    self.destination = PNC.NPCAuthoringFields.Choice(self, self)
    self.destination:addOptionWithData(tr('UI_PNC_Authoring_Pockets', 'Pockets'), 'root')
    self.destination:addOptionWithData(tr('UI_PNC_Authoring_Bag', 'Bag (when available)'), 'bag')
    self.destination:selectData('root')
    self.confirm = button(self, tr('UI_PNC_Authoring_Equip', 'Equip / Add'), function(target)
        if not target.selectedItem or not target.onChoose then return end
        local quantity = tonumber(target.quantity:getText())
        if not quantity or quantity < 1 or quantity > 99 or quantity ~= math.floor(quantity) then
            target.headingText = tr('UI_PNC_Authoring_QuantityInvalid', 'Enter a quantity from 1 to 99'); target:onResize(); return
        end
        local option = target.destination.options[target.destination.selected]
        local ok, reason = target.onChoose(target.selectedItem, quantity, option and option.data)
        if ok ~= false then target:Hide() elseif reason then target.headingText = reason; target:onResize() end
    end)
    self.closeButton = button(self, tr('UI_PNC_StartingCompanion_Close', 'Close'), function(target) target:Hide() end)
    self.previous = button(self, '<', function(target) target.offset = math.max(0, target.offset - target.pageSize); target:refreshResults() end)
    self.nextButton = button(self, '>', function(target) if target.offset + target.pageSize < target.total then target.offset = target.offset + target.pageSize; target:refreshResults() end end)
    self.counter = ISLabel:new(0, 0, 24, '', 0.8, 0.85, 0.85, 1, UIFont.Small, true)
    self.counter:initialise(); self:addChild(self.counter)
end
function Explorer:Show(options)
    self.allowed, self.onChoose = options.allowed, options.onChoose
    self.customItems = options.items
    self.titleText = options.title or tr('UI_PNC_Authoring_ItemExplorer', 'Item Explorer')
    self.headingText = self.titleText
    self.heading:setName(self.titleText)
    self.source, self.category, self.offset, self.selectedItem = nil, nil, 0, nil
    self.compatibleOnly = true
    self.search:setText('')
    self:refreshFilters(); self:refreshResults()
    self:setVisible(true); self:bringToTop(); self:onResize()
    self.search:focus()
end
function Explorer:Hide()
    self.search:unfocus()
    self:setVisible(false)
    if self.onDismiss then self.onDismiss() end
end
function Explorer:refreshFilters()
    for field, list in pairs({ source = self.sources, category = self.categories }) do
        list:clear()
        list:addItem(tr(field == 'source' and 'UI_PNC_Authoring_AllMods' or 'UI_PNC_Authoring_AllCategories',
            field == 'source' and 'All mods / modules' or 'All categories'), {})
        if not self.customItems then
            for _, value in ipairs(Catalog.Filters(field)) do list:addItem(value, { value = value }) end
        end
        list.selected = 1
    end
end
function Explorer:refreshResults()
    if not self.tiles then return end
    local rows, total = Catalog.Query({ query = self.search:getText(), source = self.source, category = self.category,
        allowed = self.allowed, compatibleOnly = self.compatibleOnly, offset = self.offset, limit = self.pageSize, items = self.customItems })
    self.total = total
    if #rows == 0 and total > 0 and self.offset > 0 then self.offset = 0; return self:refreshResults() end
    self.visibleRows = rows
    for index, tile in ipairs(self.tiles) do
        tile.item = rows[index]; tile:setVisible(rows[index] ~= nil)
        tile.tooltip = rows[index] and rows[index].label
    end
    self.previous:setEnable(self.offset > 0)
    self.nextButton:setEnable(self.offset + self.pageSize < total)
    self.counter:setName(tostring(total == 0 and 0 or self.offset + 1) .. '–' .. tostring(self.offset + #rows) .. ' / ' .. total)
    self.compatible.backgroundColor = self.compatibleOnly and { r = 0.10, g = 0.32, b = 0.23, a = 1 } or { r = 0.08, g = 0.10, b = 0.12, a = 1 }
    self:refreshDetails(); self:onResize()
end
function Explorer:refreshDetails()
    self.details:clear()
    local item = self.selectedItem
    if item then
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemName', 'Item'), item.label)
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemSource', 'Mod / module'), item.source or '')
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemCategory', 'Category'), item.category or '')
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_ItemID', 'Item ID'), item.id)
    end
    local compatible = not self.allowed or item and self.allowed[item.id]
    if item then
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_Compatibility', 'Slot compatibility'),
            tr(compatible and 'UI_PNC_Authoring_FitsSlot' or 'UI_PNC_Authoring_DoesNotFit',
                compatible and 'Fits the selected slot' or 'Does not fit the selected slot'))
    end
    self.confirm:setEnable(item ~= nil and compatible == true)
end
function Explorer:onResize()
    if not self.tiles then return end
    local g, h = 8, math.max(28, (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) + 10)
    local width, height = math.max(1, self.width - g * 2), self.height
    self.heading.tooltip = self.headingText
    self.heading:setName(L.Ellipsize(self.headingText or self.titleText or '', UIFont.Small, math.max(1, width - 110)))
    self.sources.itemheight, self.categories.itemheight, self.details.itemheight = h + 6, h + 6, h + 6
    L.SetBounds(self.heading, g, g, width - 110, h)
    L.SetBounds(self.closeButton, self.width - 100 - g, g, 100, h)
    L.SetBounds(self.search, g, h + g * 2, math.max(1, width - 240), h)
    L.SetBounds(self.compatible, self.width - 232 - g, h + g * 2, 112, h)
    L.SetBounds(self.refreshButton, self.width - 112 - g, h + g * 2, 112, h)
    local top = h * 2 + g * 3
    local filterWidth = math.min(150, math.floor(width * 0.18))
    local detailWidth = width >= 760 and 220 or 0
    local contentWidth = math.max(1, width - filterWidth - g - (detailWidth > 0 and detailWidth + g or 0))
    local detailHeight = detailWidth > 0 and 0 or h * 2
    local gridHeight = math.max(h * 3, height - top - h * 4 - g * 7 - detailHeight)
    L.SetBounds(self.sources, g, top, filterWidth, math.max(1, gridHeight * 0.48))
    L.SetBounds(self.categories, g, top + gridHeight * 0.5, filterWidth, math.max(1, gridHeight * 0.5))
    local x = g + filterWidth + g
    local columns = math.max(1, math.floor(contentWidth / 100))
    local rows = math.ceil(#(self.visibleRows or {}) / columns)
    local tileWidth, tileHeight = contentWidth / columns, math.max(84, h * 2 + 34)
    L.SetBounds(self.grid, x, top, contentWidth, gridHeight)
    self.grid.contentHeight = rows * tileHeight
    self.grid.maxScroll = math.max(0, self.grid.contentHeight - gridHeight)
    self.grid:setScrollHeight(self.grid.contentHeight)
    self.grid:setYScroll(math.max(-self.grid.maxScroll, math.min(0, self.grid:getYScroll())))
    self.grid:onResize()
    for index, tile in ipairs(self.tiles) do L.SetBounds(tile, (index - 1) % columns * tileWidth,
        math.floor((index - 1) / columns) * tileHeight, tileWidth - 4, tileHeight - 4) end
    if detailWidth > 0 then L.SetBounds(self.details, x + contentWidth + g, top, detailWidth, gridHeight)
    else L.SetBounds(self.details, x, top + gridHeight + g, contentWidth, detailHeight) end
    local y = top + gridHeight + detailHeight + g * 2
    L.SetBounds(self.previous, x, y, 40, h); L.SetBounds(self.counter, x + 48, y, math.max(1, contentWidth - 96), h)
    L.SetBounds(self.nextButton, x + contentWidth - 40, y, 40, h)
    y = y + h + g
    L.SetBounds(self.quantityLabel, x, y, contentWidth, h)
    y = y + h
    L.SetBounds(self.quantity, x, y, math.max(1, contentWidth * 0.2 - g), h)
    L.SetBounds(self.destination, x + contentWidth * 0.2, y, contentWidth * 0.8, h); self.destination:onResize()
    L.SetBounds(self.confirm, x, y + h + g, contentWidth, h)
end
return Explorer
