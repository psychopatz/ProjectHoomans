-- Sound-effect catalog tab and playback controls.
local AudioUI = PNC.AudioDebugUI
local Internal = AudioUI.Internal
local TEXT = Internal.TEXT
local Model = Internal.Model
local UI = Internal.UI
local Layout = Internal.Layout
local makeLabel = Internal.makeLabel
local setLabel = Internal.setLabel
local makeCombo = Internal.makeCombo
local selectedItem = Internal.selectedItem
local drawSFXItem = Internal.drawSFXItem

ISPNCAudioDebugSFXTab = ISPanel:derive("ISPNCAudioDebugSFXTab")

function ISPNCAudioDebugSFXTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCAudioDebugSFXTab:createChildren()
    ISPanel.createChildren(self)
    self.categories = Model.GetSFXCategories()

    self.categoryLabel = makeLabel(self, TEXT.category, "textMuted")
    self.categoryBox = makeCombo(self, self,
        ISPNCAudioDebugSFXTab.onCategoryChanged)
    for _, category in ipairs(self.categories) do
        self.categoryBox:addOptionWithData(category, category)
    end
    self.categoryBox.selected = 1

    self.searchLabel = makeLabel(self, TEXT.searchSFX, "textMuted")
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 260,
        height = 26,
    })
    self.search.onTextChangeFunction = function()
        self:refreshList()
    end

    self.status = makeLabel(self, "", "textMuted")
    self.list = UI.CreateList(self, {
        itemHeight = 42,
        doDrawItem = drawSFXItem,
    })
    self.playButton = UI.CreateButton(self, {
        id = "play",
        title = TEXT.play,
        target = self,
        onclick = ISPNCAudioDebugSFXTab.onAction,
        variant = "primary",
    })
    self.stopButton = UI.CreateButton(self, {
        id = "stop",
        title = TEXT.stop,
        target = self,
        onclick = ISPNCAudioDebugSFXTab.onAction,
        variant = "danger",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = TEXT.refresh,
        target = self,
        onclick = ISPNCAudioDebugSFXTab.onAction,
        variant = "quiet",
    })
    self.buttons = { self.playButton, self.stopButton, self.refreshButton }
    self:refreshList()
end

function ISPNCAudioDebugSFXTab:getCategory()
    local index = tonumber(self.categoryBox and self.categoryBox.selected) or 1
    return self.categories[index] or "ALL"
end

function ISPNCAudioDebugSFXTab:refreshList()
    if not self.list then return end
    local previous = selectedItem(self.list)
    local previousName = previous and previous.name or nil
    local query = self.search and self.search:getText() or ""
    local entries = Model.GetSFXEntries(self:getCategory(), query)
    self.list:clear()
    for _, sound in ipairs(entries) do
        self.list:addItem(sound.name, sound)
        if previousName and previousName == sound.name then
            self.list.selected = #self.list.items
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    setLabel(self.status, string.format("%d SFX | %s",
        #entries, self:getCategory()))
end

function ISPNCAudioDebugSFXTab:onCategoryChanged()
    self:refreshList()
end

function ISPNCAudioDebugSFXTab:onAction(button)
    local id = button and button.internal or ""
    local entry = selectedItem(self.list)
    if id == "play" then
        if not entry then
            setLabel(self.status, TEXT.noSelection)
            return
        end
        local ok, reason = Model.PlaySFX(entry.name, Model.GetCurrentPlayer())
        if ok then
            setLabel(self.status, string.format("PLAYING %s", entry.name))
        else
            setLabel(self.status, TEXT.playFailed
                .. " | " .. tostring(reason or "unknown"))
        end
    elseif id == "stop" then
        Model.StopSFX()
        setLabel(self.status, TEXT.stopped)
    elseif id == "refresh" then
        Model.RefreshSFXCatalog()
        self.categories = Model.GetSFXCategories()
        self.categoryBox:clear()
        for _, category in ipairs(self.categories) do
            self.categoryBox:addOptionWithData(category, category)
        end
        self.categoryBox.selected = 1
        self:refreshList()
    end
end

function ISPNCAudioDebugSFXTab:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local gap = 8
    local categoryWidth = math.max(180, math.floor(width * 0.34))
    local searchX = margin + categoryWidth + gap
    local searchWidth = math.max(160, width - searchX - margin)
    Layout.SetBounds(self.categoryLabel, margin, 8, categoryWidth, 18)
    Layout.SetBounds(self.categoryBox, margin, 26, categoryWidth, 26)
    Layout.SetBounds(self.searchLabel, searchX, 8, searchWidth, 18)
    Layout.SetBounds(self.search, searchX, 26, searchWidth, 26)

    local buttonTop = math.max(0, height - 31)
    local statusTop = math.max(58, buttonTop - 26)
    local listTop = 64
    Layout.SetBounds(self.list, margin, listTop, width - margin * 2,
        math.max(60, statusTop - listTop - 6))
    Layout.SetBounds(self.status, margin, statusTop, width - margin * 2, 20)
    local buttonWidth = math.max(90, math.floor((width - margin * 2 - gap * 2) / 3))
    local x = margin
    for _, button in ipairs(self.buttons) do
        Layout.SetBounds(button, x, buttonTop, buttonWidth, 27)
        x = x + buttonWidth + gap
    end
end

function ISPNCAudioDebugSFXTab:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end


return AudioUI
