-- Body-part navigation and equipment tiles; editing stays in the loadout model.
local Window, UI = ISPNCNPCAuthoringEditor, PsychopatzCore.UI
local I, L = Window.Internal, UI.Layout
local Slots, Fields = PNC.NPCAuthoringSlots, PNC.NPCAuthoringFields
local BodyMap = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringBodyMap'
local ImageResolver = require 'PsychopatzCore/UI/Components/PsychopatzImageResolver'
function Window:selectLoadoutPart(id, region)
    self.loadoutPart = id
    self.loadoutViewRegion = region or id
    self.slotContent:setYScroll(0); self.pages.loadout:setYScroll(0)
    self:refreshLoadoutPage(); self:requestResponsiveLayout()
    if self.syncPortraitView then self:syncPortraitView(false, id == nil) end
end

function Window:deselectLoadoutPart()
    if not self.loadoutPart or self.tabPanel:getActiveView() ~= self.pages.loadout then return false end
    if self.itemExplorer and self.itemExplorer:getIsVisible() then return false end
    self:selectLoadoutPart(nil)
    return true
end

function Window:onMouseUp(x, y)
    if self:deselectLoadoutPart() then return true end
    if ISPanel.onMouseUp then return ISPanel.onMouseUp(self, x, y) end
end

function Window:buildLoadoutNavigation()
    self.loadoutParts = {}
    self.bodyMap = BodyMap:new(0, 0, 123, 302, function(id, region)
        if id then self:selectLoadoutPart(id, region) else self:deselectLoadoutPart() end
    end)
    local function onBackgroundClick() return self:deselectLoadoutPart() end
    self.pages.loadout.onMouseUp = onBackgroundClick
    self.slotContent.onMouseUp = onBackgroundClick
    self.portraitPanel.onMouseUp = onBackgroundClick
    self.bodyMap:initialise(); self.bodyMap:instantiate(); self.pages.loadout:addChild(self.bodyMap)
    self.loadoutSelectionLabel = I.addLabel(self.pages.loadout, '')
    self.loadoutLegend = I.addLabel(self.pages.loadout, I.tr('UI_PNC_Authoring_BodyMapLegend', 'Green: equipped. Click a body part.'))
    self.loadoutLegend.tooltip = I.tr('UI_PNC_Authoring_BodyMapHelp', 'Select a body region to edit its clothing. Green regions have equipped items. Bags, carried supplies and weapons use the shortcuts below.')
    for _, group in ipairs(Slots.Groups()) do
        if group.id == 'back' or group.id == 'carry' or group.id == 'held' or group.id == 'other' then
            local control = UI.CreateButton(self.pages.loadout, { title = I.tr('UI_PNC_Authoring_Group_' .. group.key, group.label),
                target = self, variant = 'quiet', onclick = function(target)
                    target:selectLoadoutPart(group.id)
                end })
            control.part = group
            if group.id == 'back' then
                control.navImage = ImageResolver.ResolveItemTexture('Base.Bag_Schoolbag')
                control.secondaryIcon = ImageResolver.ResolveItemTexture('Base.Bag_FannyPackFront')
            elseif group.id == 'held' then
                control.navImage = ImageResolver.ResolveItemTexture('Base.Axe')
                control.secondaryIcon = ImageResolver.ResolveItemTexture('Base.DoubleBarrelShotgun')
            elseif group.id == 'carry' then control.navImage = getTexture and getTexture('media/ui/Sidebar/64/Inventory_On_64.png') end
            control.render = function(c)
                ISButton.render(c)
                local fontHeight = getTextManager():getFontHeight(UIFont.Small)
                local iconHeight = math.max(1, c.height - fontHeight - 8)
                local iconWidth = c.secondaryIcon and (c.width - 12) / 2 or c.width - 12
                if c.navImage then c:drawTextureScaledAspect(c.navImage, 6, 3, iconWidth, iconHeight, 1, 1, 1, 1) end
                if c.secondaryIcon then
                    c:drawTextureScaledAspect(c.secondaryIcon, 6 + (c.navImage and iconWidth or 0), 3,
                        iconWidth, iconHeight, 1, 1, 1, 1)
                end
                c:drawTextCentre(L.Ellipsize(c.caption or '', UIFont.Small, math.max(1, c.width - 8)), c.width / 2,
                    c.height - fontHeight - 4, .9, .95, .95, 1, UIFont.Small)
            end
            self.loadoutParts[#self.loadoutParts + 1] = control
        end
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
    if self.loadoutPart == 'other' and not counts.other then
        self.loadoutPart, self.loadoutViewRegion = nil, nil
    end
    self.bodyMap:SetState(self.draft and self.draft.isFemale == true, counts, self.loadoutPart, self.slotRows)
    local selected
    for _, group in ipairs(Slots.Groups()) do if group.id == self.loadoutPart then selected = group end end
    self.loadoutSelectionLabel:setName(selected and I.tr('UI_PNC_Authoring_Group_' .. selected.key, selected.label) or '')
    for _, button in ipairs(self.loadoutParts) do
        local group, count = button.part, counts[button.part.id]
        local title = I.tr('UI_PNC_Authoring_Group_' .. group.key, group.label)
        local key = ({ back = 'BagsShortcut', carry = 'InventoryShortcut', held = 'WeaponsShortcut', other = 'OtherShortcut' })[group.id]
        button.caption = I.tr('UI_PNC_Authoring_' .. key, group.label) .. ' (' .. tostring(count and count.equipped or 0) .. ')'
        button:setTitle(''); button.tooltip = title
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
        local visible = self.loadoutPart ~= nil and row.group == self.loadoutPart and self.loadoutPart ~= 'carry'
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
    self.outfitValue:setVisible(not carry)
    local generation = not carry and self.presentationMode ~= 'companion'
    self.loadoutModeRow.labelControl:setVisible(generation); self.loadoutModeRow.entry:setVisible(generation)
    if not carry then
        L.SetBounds(self.outfitValue, gap, y, w, rowHeight)
        self.outfitValue:setName(L.Ellipsize(self.outfitCaption or '', UIFont.Small, w))
        self.outfitValue.tooltip = self.outfitCaption
        y = y + rowHeight + gap
    end
    if generation then
        self.loadoutModeRow.labelControl:setName(I.tr('UI_PNC_Authoring_GeneratedWeapons', 'Generated weapon fallback'))
        self.loadoutModeRow.entry.tooltip = I.tr('UI_PNC_Authoring_GeneratedWeaponsHelp', 'Used for generated NPCs without an explicit weapon. Choose exact weapons from the Weapons shortcut.')
        L.SetBounds(self.loadoutModeRow.labelControl, gap, y, w, rowHeight); y = y + rowHeight
        local columns = w >= L.Pixels(500, self.uiScale) and 4 or 2
        self.loadoutModeRow.entry.columns = columns
        local choiceHeight = rowHeight * (columns == 4 and 1 or 2) + (columns == 4 and 0 or 4)
        L.SetBounds(self.loadoutModeRow.entry, gap, y, math.min(w, L.Pixels(650, self.uiScale)), choiceHeight)
        self.loadoutModeRow.entry:onResize(); y = y + choiceHeight + gap
    end
    local navWidth = math.min(L.Pixels(175, self.uiScale), math.max(85, w * .27))
    local mapHeight = navWidth * 302 / 123
    L.SetBounds(self.bodyMap, gap, y, navWidth, mapHeight)
    L.SetBounds(self.loadoutLegend, gap, y + mapHeight + gap, navWidth, rowHeight)
    self.loadoutLegend:setName(L.Ellipsize(I.tr('UI_PNC_Authoring_BodyMapLegend', 'Green: equipped. Click a body part.'), UIFont.Small, navWidth))
    local shortcutY, order = y + mapHeight + gap + rowHeight, 0
    local shortcutHeight = math.max(60, rowHeight * 2)
    for _, control in ipairs(self.loadoutParts) do
        if control.pncPartVisible then
            L.SetBounds(control, gap + order % 2 * (navWidth + gap) / 2, shortcutY + math.floor(order / 2) * (shortcutHeight + gap), (navWidth - gap) / 2, shortcutHeight)
            order = order + 1
        end
    end
    local mainX, mainWidth = gap + navWidth + gap, math.max(1, w - navWidth - gap)
    L.SetBounds(self.loadoutSelectionLabel, mainX, y, mainWidth, rowHeight)
    local mainY = y + rowHeight + gap
    local h = math.max(rowHeight * 3, height - mainY - gap, shortcutY + math.ceil(order / 2) * (shortcutHeight + gap) - mainY)
    self.slotContent:setVisible(not carry); self.carriedPanel:setVisible(carry)
    L.SetBounds(self.slotContent, mainX, mainY, mainWidth, h)
    local inventoryHeight = self:layoutCarriedInventory(mainX, mainY, mainWidth, h, rowHeight, gap)
    if carry then h = inventoryHeight end
    local page = self.pages.loadout
    page.contentHeight, page.maxScroll = mainY + h + gap, math.max(0, mainY + h + gap - height)
    page:setScrollHeight(page.contentHeight); page:onResize()
    page:setYScroll(math.max(-page.maxScroll, math.min(0, page:getYScroll())))
    self:layoutSlotTiles()
    if self.itemExplorer then L.SetBounds(self.itemExplorer, 0, 0, self.width, self.height); self.itemExplorer:onResize() end
end
return Window
