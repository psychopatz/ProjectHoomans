require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog"
local Window = ISPNCNPCAuthoringEditor
local I = Window.Internal
local UI, Layout, tr = I.UI, I.Layout, I.tr
local Edits, Catalog = PNC.NPCAuthoringLoadout, PNC.NPCAuthoringCatalog

local function drawItem(list, y, entry, alternate)
    local row = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local script = row.script or row.type and ScriptManager.instance:FindItem(row.type)
    local texture = script and script:getNormalTexture()
    local size = math.max(16, list.itemheight - 10)
    list:drawRectBorder(5, y + 4, size, size, 0.8, 0.4, 0.48, 0.5)
    if texture then list:drawTextureScaledAspect(texture, 7, y + 6, size - 4, size - 4, 1, 1, 1, 1) end
    local value = row.label or row.type or ""
    if row.value then value = value .. " — " .. row.value end
    list:drawText(Layout.Ellipsize(value, UIFont.Small,
        math.max(1, list.width - size - 30)), size + 14, y + 10, 0.9, 0.92, 0.94, 1, UIFont.Small)
    return y + list.itemheight
end

function Window:buildLoadoutPage()
    local page = self.pages.loadout
    -- Outfit is one control shared with the appearance implementation.
    for _, control in ipairs({ self.appearanceTab.outfitLabel, self.appearanceTab.outfitCombo }) do
        self.appearanceTab.content:removeChild(control)
        page:addChild(control)
    end
    for _, row in ipairs(self.coreRows) do
        if row.id == "equipmentMode" then
            self.formView:removeChild(row.labelControl)
            self.formView:removeChild(row.entry)
            page:addChild(row.labelControl)
            page:addChild(row.entry)
            self.loadoutModeRow = row
        end
    end
    self.loadoutGroup = I.newCombo(page, function(target) target:refreshLoadoutPage() end, self)
    I.addOptions(self.loadoutGroup, {
        { id = "worn", label = tr("UI_PNC_Authoring_Clothing", "Clothing slots") },
        { id = "held", label = tr("UI_PNC_Authoring_Hands", "Hands and attachments") },
        { id = "carry", label = tr("UI_PNC_Authoring_Carried", "Carried items and bags") },
    })
    self.loadoutSlots = UI.CreateList(page, { itemHeight = 42, doDrawItem = drawItem })
    self.loadoutSlots:setOnMouseDownFunction(self, function(target, slot)
        target.loadoutSlot = slot
        target:searchLoadoutItems()
    end)
    self.loadoutSearch = UI.CreateTextEntry(page, {
        maxTextLength = 80, onTextChange = function() self:searchLoadoutItems() end,
    })
    self.loadoutQuantity = UI.CreateTextEntry(page, { onlyNumbers = true, maxTextLength = 2 })
    self.loadoutQuantity:setText("1")
    self.loadoutDestination = I.newCombo(page, nil)
    I.addOptions(self.loadoutDestination, {
        { id = "root", label = tr("UI_PNC_Authoring_Pockets", "Pockets") },
        { id = "bag", label = tr("UI_PNC_Authoring_Bag", "Bag (when available)") },
    })
    self.loadoutQuantityLabel = I.addLabel(page, tr("UI_PNC_Authoring_Quantity", "Quantity / Destination"))
    self.loadoutSearchLabel = I.addLabel(page, tr("UI_PNC_Authoring_SearchItems", "Search compatible items"))
    self.loadoutResults = UI.CreateList(page, { itemHeight = 36, doDrawItem = drawItem })
    self.loadoutEquip = UI.CreateButton(page, {
        id = "equip", title = tr("UI_PNC_Authoring_Equip", "Equip / Add"), target = self,
        onclick = function(target) target:editLoadout(false) end, variant = "primary",
    })
    self.loadoutClear = UI.CreateButton(page, {
        id = "clear", title = tr("UI_PNC_Authoring_ClearSlot", "Clear slot / Remove"), target = self,
        onclick = function(target) target:editLoadout(true) end, variant = "quiet",
    })
end

function Window:searchLoadoutItems()
    if not self.loadoutResults then return end
    local slot = self.loadoutSlot
    local allowed
    if slot and slot.kind == "worn" then
        allowed = {}
        for _, option in ipairs(Catalog.Clothing(slot.id)) do
            allowed[option.id] = true
        end
    end
    self.loadoutResults:clear()
    if not slot then return end
    local matches, more = Catalog.Search(I.fieldText(self.loadoutSearch), allowed)
    for _, item in ipairs(matches) do self.loadoutResults:addItem(item.label, item) end
    self.loadoutResults.selected = #matches > 0 and 1 or 0
    self.loadoutSearchLabel:setName(tr(more and "UI_PNC_Authoring_SearchMore"
        or "UI_PNC_Authoring_SearchItems", more and "First 200 matches — refine search"
        or "Search compatible items"))
end

function Window:refreshLoadoutPage()
    if not self.loadoutSlots then return end
    local previous = self.loadoutSlot
    local group = I.comboData(self.loadoutGroup) or "worn"
    local rows = {}
    local function add(row) rows[#rows + 1] = row end
    local draft = self.draft
    if not draft then self.loadoutSlots:clear(); self.loadoutSlot = nil; return end
    local appearance = PNC.Identity.Appearance.Normalize(draft.appearance)
    local record = self.previewDraft and self.previewDraft.runtimeRecord
    local effective = record and record.inventory and record.inventory.items or {}
    if group == "worn" then
        for _, location in ipairs(PNC.UniqueNPCAppearanceUI.Internal.locations()) do
            local options = Catalog.Clothing(location)
            if #options > 0 then
                local policy = appearance.slots[location] or {}
                local short = string.match(location, "([^:]+)$") or location
                local label = getText("UI_ClothingType_" .. short)
                if label == "UI_ClothingType_" .. short then label = short end
                local wornType = policy.type
                local shortID = string.match(location, "([^:]+)$") or location
                for _, item in pairs(effective) do
                    local worn = item.wornSlot and (string.match(item.wornSlot, "([^:]+)$") or item.wornSlot)
                    if worn == shortID then wornType = item.type end
                end
                for _, item in ipairs(draft.startingItems or {}) do
                    if item.wornSlot == location then wornType = item.type end
                end
                add({ kind = "worn", id = location, label = label, type = wornType,
                    value = wornType or tr(policy.mode == "none" and "UI_PNC_UniqueNPCEditor_None"
                        or "UI_PNC_UniqueNPCEditor_Random", policy.mode == "none" and "None" or "Random") })
            end
        end
    elseif group == "held" then
        for _, id in ipairs({ "primary", "secondary" }) do
            local row = { kind = "held", id = id, label = tr(id == "primary"
                and "UI_PNC_Authoring_Primary" or "UI_PNC_Authoring_Secondary",
                id == "primary" and "Primary hand" or "Secondary hand") }
            for _, item in pairs(effective) do
                if item.equipSlot == id then row.type = item.type end
            end
            for _, item in ipairs(draft.startingItems or {}) do
                if item.equipSlot == id then row.type = item.type end
            end
            row.value = row.type or tr("UI_PNC_UniqueNPCEditor_None", "None")
            add(row)
        end
        add({ kind = "attach", id = "auto", label = tr("UI_PNC_Authoring_Attach", "Add attachment") })
        for index, item in ipairs(draft.startingItems or {}) do
            if item.attachedSlot then add({ kind = "item", id = item.key or "item:" .. index, index = index,
                label = item.attachedSlot, type = item.type }) end
        end
    else
        add({ kind = "carry", id = "new", label = tr("UI_PNC_Authoring_AddItem", "Add carried item or bag") })
        for index, item in ipairs(draft.startingItems or {}) do
            if not item.equipSlot and not item.attachedSlot then
                add({ kind = "item", id = item.key or "item:" .. index, index = index, label = "×" .. tostring(item.stack or 1), type = item.type })
            end
        end
    end
    self.loadoutSlots:clear()
    self.loadoutSlot = nil
    for index, row in ipairs(rows) do
        self.loadoutSlots:addItem(row.label, row)
        if previous and previous.kind == row.kind and previous.id == row.id then
            self.loadoutSlot = row
            self.loadoutSlots.selected = index
        end
    end
    if not self.loadoutSlot then self.loadoutSlot = rows[1]; self.loadoutSlots.selected = 1 end
    self:searchLoadoutItems()
end

function Window:editLoadout(clear)
    local slot = self.loadoutSlot
    if not slot or not self.draft then return end
    local fieldID = slot.kind == "worn" and "appearance" or "startingItems"
    if self:fieldCapability(fieldID).editable == false then return end
    local entry = self.loadoutResults:getItem()
    local spec, reason
    local targetSlot = slot
    if not clear then
        if not entry then return end
        local native = PNC.Equipment.CreateItem(entry.item.id)
        if type(native) == "table" and native[1] then native = native[1] end
        if not native then return end
        spec, reason = PNC.Inventory.CaptureNativeItem(native)
        if not spec then self:setStatus(tostring(reason)); return end
        local quantity = tonumber(I.fieldText(self.loadoutQuantity))
        if not quantity or quantity < 1 or quantity > 99 then
            self:setStatus(tr("UI_PNC_Authoring_QuantityInvalid", "Enter a quantity from 1 to 99")); return
        end
        spec.stack = slot.kind == "carry" and math.floor(quantity) or 1
        spec.preferredContainer = I.comboData(self.loadoutDestination) == "bag" and "bag" or nil
        if spec.maxWeight then spec.stack = 1 end
        if slot.kind == "attach" then
            local occupied = {}
            for _, item in ipairs(self.draft.startingItems or {}) do
                if item.attachedSlot then occupied[item.attachedSlot] = true end
            end
            local location = PNC.Equipment.ResolveAttachedLocation(native, nil, occupied)
            if not location then self:setStatus(tr("UI_PNC_Authoring_Incompatible", "No compatible free slot")); return end
            targetSlot = { kind = "attached", id = location }
        end
        if slot.kind == "held" then
            for _, item in ipairs(self.draft.startingItems or {}) do
                if item.equipSlot and item.equipSlot ~= slot.id then
                    local other = PNC.Equipment.CreateItem(item.type)
                    if type(other) == "table" and other[1] then other = other[1] end
                    if native:isTwoHandWeapon() or other and other:isTwoHandWeapon() then
                        self:setStatus(tr("UI_PNC_Authoring_TwoHands", "Clear the other hand before equipping a two-handed item")); return
                    end
                end
            end
        end
    elseif slot.kind == "carry" or slot.kind == "attach" then return end
    local ok
    ok, reason = Edits.SetSlot(self.draft, targetSlot, spec)
    if not ok then
        self:setStatus(tr(reason == "clothing_conflict" and "UI_PNC_Authoring_ClothingConflict"
            or "UI_PNC_Authoring_ItemLimit", reason == "clothing_conflict"
            and "Clothing conflicts with another slot" or "The loadout contains too many items"))
        return
    end
    self:syncControls()
    self:refreshPreview(false)
    self:refreshLoadoutPage()
end

function Window:layoutLoadoutPage(width, height, rowHeight, gap)
    local page = self.pages.loadout
    self.loadoutSlots.itemheight = rowHeight + Layout.Pixels(14, self.uiScale)
    self.loadoutResults.itemheight = rowHeight + Layout.Pixels(8, self.uiScale)
    local w, y = math.max(1, width - gap * 2 - 16), gap
    local function row(control, h)
        Layout.SetBounds(control, gap, y, w, h or rowHeight)
        y = y + (h or rowHeight) + gap
    end
    row(self.appearanceTab.outfitLabel)
    row(self.appearanceTab.outfitCombo)
    self.loadoutModeRow.labelControl:setVisible(true)
    self.loadoutModeRow.entry:setVisible(true)
    row(self.loadoutModeRow.labelControl)
    row(self.loadoutModeRow.entry)
    row(self.loadoutGroup)
    local wide = w >= Layout.Pixels(500, self.uiScale)
    if wide then
        local left = math.floor((w - gap) * 0.48)
        local right = w - left - gap
        local areaHeight = math.max(rowHeight * 5, height - y - rowHeight * 3 - gap * 5)
        Layout.SetBounds(self.loadoutSlots, gap, y, left, areaHeight)
        Layout.SetBounds(self.loadoutSearchLabel, gap + left + gap, y, right, rowHeight)
        Layout.SetBounds(self.loadoutSearch, gap + left + gap, y + rowHeight + gap, right, rowHeight)
        Layout.SetBounds(self.loadoutResults, gap + left + gap, y + rowHeight * 2 + gap * 2,
            right, areaHeight - rowHeight * 2 - gap * 2)
        y = y + areaHeight + gap
    else
        row(self.loadoutSlots, rowHeight * 4)
        row(self.loadoutSearchLabel)
        row(self.loadoutSearch)
        row(self.loadoutResults, rowHeight * 4)
    end
    row(self.loadoutQuantityLabel)
    local quantityWidth = math.max(1, math.floor((w - gap) * 0.25))
    Layout.SetBounds(self.loadoutQuantity, gap, y, quantityWidth, rowHeight)
    Layout.SetBounds(self.loadoutDestination, gap + quantityWidth + gap, y, w - quantityWidth - gap, rowHeight)
    y = y + rowHeight + gap
    local half = math.max(1, math.floor((w - gap) / 2))
    Layout.SetBounds(self.loadoutEquip, gap, y, half, rowHeight)
    Layout.SetBounds(self.loadoutClear, gap + half + gap, y, w - half - gap, rowHeight)
    y = y + rowHeight + gap
    page.contentHeight = math.max(height, y)
    page:setScrollHeight(page.contentHeight)
    page.maxScroll = math.max(0, page.contentHeight - height)
    page:setYScroll(math.max(-page.maxScroll, math.min(0, page:getYScroll())))
    page:onResize()
end

return Window
