local Zoom = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringPreviewZoom"

local Explorer = ISPNCNPCAuthoringItemExplorer
local UI = PsychopatzCore.UI
local L = UI.Layout
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end

function Explorer:buildVariantButton()
    self.variantButton = UI.CreateButton(self, {
        title = tr("UI_PNC_Authoring_ChangeVariant", "Change"),
        target = self, variant = "warning", onclick = Explorer.openVariantDialog,
    })
    self.variantButton.tooltip = tr("UI_PNC_Authoring_Variants", "Item variants")
    self.variantButton:setVisible(false)
end

function Explorer:refreshVariantButton(item)
    self.variantGroups = item and self.options.variants and self.options.variants(item) or {}
    local supported = #self.variantGroups > 0 and self.options.changeVariant ~= nil
    self.variantButton:setVisible(supported)
    PNC.NPCAuthoringFields.EnableButton(self.variantButton, supported)
    if self.variantDialog and (not supported or self.variantDialog.item ~= item) then
        self:closeVariantDialog()
    end
end

function Explorer:closeVariantDialog(accepted)
    local dialog = self.variantDialog
    if not dialog then return end
    self.variantDialog = nil
    dialog:setVisible(false)
    dialog:removeFromUIManager()
    if dialog.finish then dialog.finish(accepted == true) end
end

function Explorer:openVariantDialog()
    local item = self:currentSelection()
    if not item or not self.variantButton:getIsVisible() or self.variantDialog then return end
    self.search:unfocus()

    local h, gap = math.max(28, self.fontHeight + 10), 8
    local hasPortrait = UI.PortraitPanel and self.options.preview
    local width = math.min(hasPortrait and 710 or 420, self.width - 2 * gap)
    local portraitWidth = hasPortrait and math.floor(width * .43) or 0
    local controlsWidth = width - portraitWidth - gap * (hasPortrait and 3 or 2)
    local height = math.max(hasPortrait and 400 or 0, (#self.variantGroups + 2) * (h + gap) + gap)
    local dialog = ISPanel:new(0, 0, width, height)
    dialog.backgroundColor = { r = .055, g = .065, b = .075, a = 1 }
    dialog.borderColor = { r = .35, g = .40, b = .45, a = 1 }
    dialog:initialise()
    dialog:instantiate()
    function dialog:update()
        if not self.owner:isReallyVisible() then self.owner:closeVariantDialog() end
    end
    dialog.owner = self
    dialog.item = item
    dialog.finish = self.options.beginVariantEdit and self.options.beginVariantEdit(item)
    if hasPortrait then
        local x = width - portraitWidth - gap
        local portraitHeight = height - 3 * gap - h
        local portrait = UI.PortraitPanel:new(x, gap, portraitWidth, portraitHeight,
            { zoom = -3, animSetName = false, stateName = 'idle', animate = true })
        portrait:initialise()
        portrait:instantiate()
        dialog:addChild(portrait)
        dialog.portrait = portrait
        if portrait.setPortraitBounds then
            portrait:setPortraitBounds(x, gap, portraitWidth, portraitHeight)
        end
        portrait:setViewRegion('body')
        portrait:setViewRegion(self.preview and self.preview:getViewRegion() or 'body', false, true)
        Zoom.Layout(Zoom.Build(dialog, portrait), x, height - h - gap, portraitWidth, h, gap, true)
    end
    local function showVariant()
        if not dialog.portrait then return end
        local spec = self.options.preview(item, 1)
        if spec and self.options.projectPreview then spec = self.options.projectPreview(spec) end
        dialog.portrait:setVisible(spec ~= nil)
        if spec then
            dialog.portrait:setTarget(nil, spec, true)
            if dialog.portrait.modelView then dialog.portrait.modelView.animateWhilePaused = true end
        end
    end
    local title = tr("UI_PNC_Authoring_Variants", "Item variants")
    local heading = L.Ellipsize(title .. " - " .. item.label, UIFont.Small, controlsWidth)
    local label = ISLabel:new(gap, gap, h, heading, .9, .95, .95, 1, UIFont.Small, true)
    label:initialise()
    dialog:addChild(label)

    local list = UI.CreateList(dialog, { itemHeight = h })
    dialog.list = list
    L.SetBounds(list, gap, h + 2 * gap, controlsWidth, height - 2 * h - 4 * gap)
    list.doDrawItem = function(control, y, entry)
        local row = entry.item
        if row.option and row.group.selected == row.index then
            control:drawSelection(0, y, control.width, h)
        end
        local inset = row.option and 14 or 7
        local text = L.Ellipsize(entry.text, UIFont.Small, math.max(1, control.width - inset - 18))
        local shade = row.option and .94 or .70
        control:drawText(text, inset, y + 5, shade, shade, shade, 1, UIFont.Small)
        return y + h
    end
    for _, group in ipairs(self.variantGroups) do
        list:addItem(tr(group.key, group.label), {})
        for index, option in ipairs(group.options) do
            local name = option.key and tr(option.key, option.label) or option.label
            list:addItem(name, { group = group, index = index, option = option })
        end
    end
    list:setOnMouseDownFunction(self, function(target, row)
        if not row.option or target:currentSelection() ~= item or row.group.selected == row.index then return end
        target.options.changeVariant(item, row.group.field, row.option.value)
        row.group.selected = row.index
        showVariant()
    end)
    dialog.cancel = UI.CreateButton(dialog, {
        title = tr("UI_PNC_Authoring_Cancel", "Cancel"), target = self,
        variant = "quiet", onclick = function(target)
            target:closeVariantDialog()
            target:refreshDetails()
        end,
    })
    dialog.apply = UI.CreateButton(dialog, {
        title = tr("UI_PNC_Authoring_ApplyVariant", "Apply variant"), target = self,
        variant = "primary", onclick = function(target)
            local selected = target:currentSelection() == item
            target:closeVariantDialog(selected)
            target:refreshDetails()
            if selected then target:confirmSelection() end
        end,
    })
    local y = height - h - gap
    local buttonWidth = (controlsWidth - gap) / 2
    L.SetBounds(dialog.cancel, gap, y, buttonWidth, h)
    L.SetBounds(dialog.apply, buttonWidth + 2 * gap, y, buttonWidth, h)

    -- Mount only the finished card. A failed construction can never leave
    -- an input-blocking foreground layer in the item browser.
    showVariant()
    self.variantDialog = dialog
    self:positionVariantDialog()
    dialog:setAlwaysOnTop(true)
    dialog:addToUIManager()
    dialog:bringToTop()
end

function Explorer:positionVariantDialog()
    local dialog = self.variantDialog
    if not dialog then return end
    local x = self.getAbsoluteX and self:getAbsoluteX() or self.x
    local y = self.getAbsoluteY and self:getAbsoluteY() or self.y
    dialog:setX(math.floor(x + (self.width - dialog.width) / 2))
    dialog:setY(math.floor(y + (self.height - dialog.height) / 2))
end

return Explorer
