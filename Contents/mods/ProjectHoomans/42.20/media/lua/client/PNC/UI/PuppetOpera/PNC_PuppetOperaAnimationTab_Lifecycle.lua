-- Widget construction and context lifecycle for the animation catalog tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local UI = Internal.UI
local tr = Internal.tr
local drawCatalogItem = Internal.drawCatalogItem
local Class = ISPNCPuppetOperaAnimationTab

function Class:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function Class:createChildren()
    ISPanel.createChildren(self)
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        onTextChange = function()
            self:updateQuery()
            self:refreshCatalog()
        end,
    })
    self.filter = ISComboBox:new(0, 0, 190, 26, self,
        ISPNCPuppetOperaAnimationTab.onFilterChanged)
    self.filter:initialise()
    self.filter:instantiate()
    self:addChild(self.filter)

    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawCatalogItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        valueXMax = 108,
        ellipsize = true,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.assignButton = UI.CreateButton(self, {
        id = "assign",
        title = tr("UI_PNC_PuppetOpera_AssignSelectedBeat",
            "Assign to selected beat"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "selected",
    })
    self.previewButton = UI.CreateButton(self, {
        id = "preview",
        title = tr("UI_PNC_PuppetOpera_Preview", "Preview selected"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.stopPreviewButton = UI.CreateButton(self, {
        id = "stop_preview",
        title = tr("UI_PNC_PuppetOpera_StopPreview", "Stop preview"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "danger",
    })
    self.loopPreviewButton = UI.CreateButton(self, {
        id = "loop_preview",
        title = tr("UI_PNC_PuppetOpera_LoopPreview", "Loop preview: OFF"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.catalogName = "player"
    self.targets = {}
    self.ownerWindow = nil
    self:rebuildFilter()
end

function Class:setContext(window, catalogName)
    self.ownerWindow = window
    self.catalogName = catalogName or self.catalogName
    self:rebuildFilter()
    self:refreshCatalog()
end

return Class
