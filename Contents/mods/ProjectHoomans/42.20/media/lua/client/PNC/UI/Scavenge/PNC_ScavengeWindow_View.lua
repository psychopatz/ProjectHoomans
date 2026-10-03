local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local UI = Internal.UI
local Layout = Internal.Layout
local Theme = Internal.Theme
local tr = Internal.tr
local drawStatusRow = Internal.drawStatusRow

local ISPNCScavengeSection = ISPanel:derive("ISPNCScavengeSection")

function ISPNCScavengeSection:prerender()
    ISPanel.prerender(self)
    local suffix = self.owner and self.owner.sectionSuffix
        and self.owner:sectionSuffix(self.kind) or ""
    UI.DrawSectionTitle(self, self.title, 8, 5,
        math.max(1, self:getWidth() - 16), suffix)
end

function ISPNCScavengeSection:new(owner, kind, title)
    local o = ISPanel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.owner = owner
    o.kind = kind
    o.title = title
    o.backgroundColor = Theme.Color("surface")
    o.borderColor = Theme.Color("border")
    return o
end

local function makeButton(owner, id, title, x, width)
    local button = ISButton:new(x, 0, width, 26, title, owner,
        ISPNCScavengeWindow.onAction)
    button.internal = id
    button:initialise()
    button:instantiate()
    button.psychopatzBaseWidth = width
    owner:addChild(button)
    return button
end

function ISPNCScavengeWindow:createChildren()
    UI.Window.createChildren(self)
    self.searchEntry = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 200,
        height = 26,
        onTextChange = function() self:rebuildManifest() end,
    })

    self.containerButton = makeButton(self, "containers", tr(
        "UI_PNC_Scavenge_Containers", "Containers"), 0, 118)
    self.floorButton = makeButton(self, "floorItems", tr(
        "UI_PNC_Scavenge_Floor", "Floor"), 0, 100)
    self.corpseButton = makeButton(self, "corpses", tr(
        "UI_PNC_Scavenge_Corpses", "Corpses"), 0, 105)
    self.searchButton = UI.CreateToggleButton(self, {
        id = "search",
        offTitle = tr("UI_PNC_Scavenge_Start", "Start Search"),
        onTitle = tr("UI_PNC_Scavenge_Stop", "Stop Search"),
        target = self,
        onclick = ISPNCScavengeWindow.onAction,
        offVariant = "primary",
        onVariant = "danger",
        width = 112,
    })

    self.manifestPanel = ISPNCScavengeSection:new(self, "manifest",
        tr("UI_PNC_Scavenge_Manifest", "LOOT MANIFEST"))
    self.manifestPanel:initialise()
    self.manifestPanel:instantiate()
    self:addChild(self.manifestPanel)

    self.manifestList = ISPNCInventoryList:new(0, 0, 100, 100,
        self, "scavenge")
    self.manifestList:initialise()
    self.manifestList:instantiate()
    self.manifestList.selectOnly = true
    self.manifestPanel:addChild(self.manifestList)

    self.statusPanel = ISPNCScavengeSection:new(self, "activity",
        tr("UI_PNC_Scavenge_ActivityLog", "ACTIVITY LOG"))
    self.statusPanel:initialise()
    self.statusPanel:instantiate()
    self:addChild(self.statusPanel)
    self.statusList = ISScrollingListBox:new(0, 0, 100, 100)
    self.statusList:initialise()
    self.statusList:instantiate()
    self.statusList.itemheight = 24
    self.statusList.doDrawItem = drawStatusRow
    self.statusList.drawBorder = true
    self.statusList.backgroundColor = { r = 0, g = 0, b = 0, a = 0.62 }
    self.statusPanel:addChild(self.statusList)

    self.takeButton = makeButton(self, "take_selected", tr(
        "UI_PNC_Scavenge_TakeSelected", "Take Selected"), 0, 130)
    self.takeAllButton = makeButton(self, "take_all", tr(
        "UI_PNC_Scavenge_TakeAll", "Take All Found"), 0, 126)
    self.autoButton = makeButton(self, "take_auto", tr(
        "UI_PNC_Scavenge_TakeAuto", "Take Auto Grab"), 0, 132)
    self.disbandButton = makeButton(self, "disband", tr(
        "UI_PNC_Scavenge_Disband", "Disband & Follow"), 0, 145)
    self.debugButton = makeButton(self, "debug_dump", tr(
        "UI_PNC_Scavenge_DumpDiagnostics", "Dump Diagnostics"), 0, 120)
    self.closeButton = makeButton(self, "close", tr(
        "UI_PNC_Close", "Close"), 0, 78)
    self:updateToggleTitles()
    self:requestResponsiveLayout(true)
end

function ISPNCScavengeWindow:onResponsiveLayout()
    if not self.manifestList then return end
    local rect = self:getContentRect({ top = 12, bottom = 12 })
    local scale = self.uiScale or Layout.Scale()
    local function px(value) return Layout.Pixels(value, scale) end
    local gap, controlHeight = px(7), px(26)
    local controlsY = rect.y + px(28)
    local containerWidth, floorWidth = px(118), px(100)
    local corpseWidth, searchWidth = px(105), px(112)
    Layout.SetBounds(self.containerButton, rect.x, controlsY,
        containerWidth, controlHeight)
    Layout.SetBounds(self.floorButton, rect.x + containerWidth + gap,
        controlsY, floorWidth, controlHeight)
    Layout.SetBounds(self.corpseButton,
        rect.x + containerWidth + floorWidth + gap * 2,
        controlsY, corpseWidth, controlHeight)
    local filtersWidth = containerWidth + floorWidth + corpseWidth + gap * 3
    local compact = rect.width < px(790)
    local searchY = compact and controlsY + controlHeight + gap or controlsY
    local searchX = compact and rect.x or rect.x + filtersWidth
    local entryWidth = compact and rect.width - searchWidth - gap
        or rect.width - filtersWidth - searchWidth
    Layout.SetBounds(self.searchEntry, searchX, searchY,
        math.max(px(100), entryWidth), controlHeight)
    Layout.SetBounds(self.searchButton, rect.x + rect.width - searchWidth,
        searchY, searchWidth, controlHeight)
    local manifestY = searchY + controlHeight + px(10)
    local sectionHeaderHeight = px(28)
    local statusRatio = self.debugEnabled and 0.44 or 0.30
    local statusHeight = math.max(px(120),
        math.min(px(self.debugEnabled and 330 or 240),
            math.floor(rect.height * statusRatio)))
    local buttonsY = rect.y + rect.height - controlHeight
    local statusY = buttonsY - statusHeight - gap
    local manifestHeight = math.max(px(120), statusY - manifestY - gap)
    Layout.SetBounds(self.manifestPanel, rect.x, manifestY, rect.width,
        manifestHeight)
    Layout.SetBounds(self.manifestList, 1, sectionHeaderHeight,
        math.max(1, rect.width - 2),
        math.max(1, manifestHeight - sectionHeaderHeight - 1))
    Layout.SetBounds(self.statusPanel, rect.x, statusY, rect.width,
        statusHeight)
    Layout.SetBounds(self.statusList, 1, sectionHeaderHeight,
        math.max(1, rect.width - 2),
        math.max(1, statusHeight - sectionHeaderHeight - 1))
    local x = rect.x
    for _, button in ipairs({ self.takeButton, self.takeAllButton,
        self.autoButton, self.disbandButton })
    do
        local width = px(button.psychopatzBaseWidth or button.width)
        Layout.SetBounds(button, x, buttonsY, width, controlHeight)
        x = x + width + gap
    end
    local closeWidth, debugWidth = px(78), px(132)
    Layout.SetBounds(self.closeButton, rect.x + rect.width - closeWidth,
        buttonsY, closeWidth, controlHeight)
    local debugVisible = rect.width >= px(760) and PNC.Client
        and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
    self.debugButton:setVisible(debugVisible)
    Layout.SetBounds(self.debugButton,
        rect.x + rect.width - closeWidth - debugWidth - gap,
        buttonsY, debugWidth, controlHeight)
    self.layout = { rect = rect, controlsY = controlsY,
        manifestY = manifestY, statusY = statusY }
end
