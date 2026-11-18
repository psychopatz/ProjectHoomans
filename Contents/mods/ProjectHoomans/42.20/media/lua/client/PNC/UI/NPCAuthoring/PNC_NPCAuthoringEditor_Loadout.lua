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
    self.outfitBrowse.tooltip = tr('UI_PNC_Authoring_LoadoutEditHelp', 'Changes update this NPC in the editor immediately. Save NPC preset keeps a reusable copy of all tabs, including this loadout.')
    self.outfitValue = I.addLabel(page, '')
    self.slotContent = ISPNCUniqueNPCAppearanceScrollPanel:new(0, 0, 1, 1)
    self.slotContent:initialise(); self.slotContent:instantiate(); page:addChild(self.slotContent)
    self.slotTiles = {}
    self:buildLoadoutNavigation()
    self.itemExplorer = ISPNCNPCAuthoringItemExplorer:new(0, 0, 1, 1)
    self.itemExplorer:initialise(); self.itemExplorer:instantiate(); self:addChild(self.itemExplorer)
    local function modalLayout()
        self:requestResponsiveLayout()
        if self.parentEditor and self.parentEditor.onResponsiveLayout then self.parentEditor:onResponsiveLayout() end
    end
    self.itemExplorer.onDismiss, self.itemExplorer.onShown = modalLayout, modalLayout
    self.itemExplorer:setVisible(false)
end
function Window:browseOutfits()
    if not self.draft or self:pullForm() == false then return end
    if self:fieldCapability("appearance").editable == false then return end
    local items, previews = {}, {}
    for _, option in ipairs(self.appearanceTab.outfitCombo.options or {}) do
        if option.data ~= "__current" and (PNC.NPCAuthoringFields.CanRandomize(self) or option.data ~= "random") then
            items[#items + 1] = { id = option.data, label = option.text, search = string.lower(option.text) }
        end
    end
    local function inspect(item)
        if previews[item.id] then return previews[item.id].spec end
        local candidate = PNC.NPCAuthoring.Registry.Copy(self.draft)
        candidate.runtimeRecord = nil
        local appearance = PNC.Identity.Appearance.Normalize(candidate.appearance)
        local named = string.sub(item.id, 1, 6) == "named:"
        appearance.outfit = named and { mode = "item", id = string.sub(item.id, 7) } or { mode = item.id }
        appearance.slots = {}
        if named then
            local slots = Edits.CaptureOutfit(appearance.outfit.id, candidate.isFemale)
            if not slots then return nil end
            appearance.slots = slots
        end
        Edits.SetOutfit(candidate, appearance)
        local preview = I.Model.BuildPreviewDraft(candidate)
        local record = I.Model.EnsureRuntimeRecord(preview, true)
        local spec = record and I.Model.BuildPortraitSpec(preview)
        previews[item.id] = { appearance = appearance, spec = spec }
        return spec
    end
    self.itemExplorer:Show({ mode = "outfit", title = tr('UI_PNC_Authoring_BrowseOutfits', 'Browse outfits'), items = items,
        preview = inspect, applyTooltip = self.outfitBrowse.tooltip, onChoose = function(item)
            if not previews[item.id] then inspect(item) end
            local choice = previews[item.id]
            if not choice then return false, tr('UI_PNC_Authoring_UnavailableOutfit', 'This outfit is unavailable') end
            local candidate = PNC.NPCAuthoring.Registry.Copy(self.draft)
            Edits.SetOutfit(candidate, choice.appearance)
            local valid, reason = I.Model.BuildBlueprint(candidate)
            if not valid then return false, tostring(reason) end
            self.draft = candidate
            self.appearanceTab.draft = self.draft
            self.appearanceTab:markChanged()
            return true
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
    elseif slot.weapon then
        allowed = Catalog.Weapons()
    end
    local carried = slot.group == 'carry' and slot.kind == 'item'
    local preview, choose, refresh = self:loadoutPickerCallbacks(slot, allowed)
    self.itemExplorer:Show({ mode = carried and 'carry' or slot.kind, title = slot.label, allowed = allowed,
        viewRegion = slot.group == self.loadoutPart and (self.loadoutViewRegion or slot.group) or slot.group,
        preview = (slot.kind == 'worn' or slot.kind == 'held' or slot.kind == 'attach') and preview or nil,
        onRefresh = refresh,
        applyLabel = tr(carried and 'UI_PNC_Authoring_UpdateCarried' or slot.kind == 'carry' and 'UI_PNC_Authoring_AddCarried' or 'UI_PNC_Authoring_EquipItem',
            carried and 'Update carried item' or slot.kind == 'carry' and 'Add carried item' or 'Equip item'),
        applyTooltip = tr('UI_PNC_Authoring_LoadoutEditHelp', 'Changes update this NPC in the editor immediately. Save NPC preset keeps a reusable copy of all tabs, including this loadout.'),
        initialID = carried and slot.type or nil, initialQuery = carried and slot.type or nil,
        initialQuantity = carried and slot.quantity or nil, initialDestination = carried and slot.destination or nil,
        reloadAllowed = slot.weapon and function() return Catalog.Weapons() end or slot.kind == 'worn' and function()
            local refreshed = {}; for _, item in ipairs(Catalog.Clothing(slot.id)) do refreshed[item.id] = true end; return refreshed
        end or nil,
        onChoose = choose })
    self:requestResponsiveLayout()
end
function Window:buildLoadoutCandidate(slot, fullType, quantity, destination, selection)
    if not self.draft then return false end
    local capability = self:fieldCapability(slot.kind == 'worn' and 'appearance' or 'startingItems')
    if capability.editable == false then return false, capability.sourceLabel end
    local spec, native, reason
    local targetSlot = slot
    if fullType then
        if selection then native = selection.native else native, reason = Catalog.Create(fullType) end
        if not native then return false, tr('UI_PNC_Authoring_UnavailableItem', 'This item is unavailable') end
        if selection then spec = PNC.NPCAuthoring.Registry.Copy(selection.spec)
        else spec, reason = PNC.Inventory.CaptureNativeItem(native) end
        if not spec then return false, tostring(reason) end
        spec.stack = (slot.kind == 'carry' or slot.group == 'carry') and quantity or 1
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
    return candidate
end
function Window:applyLoadout(slot, fullType, quantity, destination, selection)
    local candidate, reason = self:buildLoadoutCandidate(slot, fullType, quantity, destination, selection)
    if not candidate then return false, reason end
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
            tile.clear = button(self.slotContent, self, 'x', function(target, clicked)
                local ok, reason = target:applyLoadout(clicked.slot)
                if not ok and reason then target:setStatus(reason) end
            end)
            tile.clear.tooltip = tr('UI_PNC_Authoring_Clear', 'Clear slot / Remove')
            self.slotTiles[index] = tile
        end
        tile.slot, tile.clear.slot = slot, slot
        local entry = slot.type and Catalog.Find(slot.type)
        tile.tooltip = slot.label .. '\n' .. (entry and entry.label or slot.type and (tr('UI_PNC_Authoring_UnavailableItem', 'This item is unavailable') .. ': ' .. slot.type) or tr('UI_PNC_Authoring_EmptySlot', 'Empty / generated slot'))
        tile:setVisible(true)
        tile.clear:setVisible(slot.kind ~= 'carry' and slot.kind ~= 'attach')
    end
    for index = #rows + 1, #self.slotTiles do self.slotTiles[index]:setVisible(false); self.slotTiles[index].clear:setVisible(false) end
    self:refreshLoadoutNavigation()
    self:layoutSlotTiles()
    local outfit = self.draft and self.draft.appearance and self.draft.appearance.outfit
    local outfitID = outfit and outfit.mode == 'item' and 'named:' .. tostring(outfit.id) or outfit and outfit.mode or 'random'
    local label = ''
    for _, option in ipairs(self.appearanceTab.outfitCombo.options or {}) do if option.data == outfitID then label = option.text end end
    if not PNC.NPCAuthoringFields.CanRandomize(self) or outfitID == 'none' then
        local count = 0
        for _, row in ipairs(rows) do if row.kind == 'worn' and row.type then count = count + 1 end end
        label = tr('UI_PNC_Authoring_EquippedClothing', 'Equipped clothing slots') .. ': ' .. count
    end
    self.outfitCaption = label
    self.outfitValue:setName(label)
end
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCarriedInventory'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadoutView'
require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadoutPreview'
return Window
