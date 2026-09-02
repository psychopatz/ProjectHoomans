require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_AudioDebugModel"

PNC = PNC or {}
PNC.AudioDebugUI = PNC.AudioDebugUI or {}

local AudioUI = PNC.AudioDebugUI
local Model = PNC.AudioDebug
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then
        return value
    end
    return fallback
end

local TEXT = {
    title = resolveText(getText and getText("UI_PNC_AudioDebug_Title"),
        "UI_PNC_AudioDebug_Title", "AUDIO DEBUG"),
    dialogues = resolveText(getText and getText("UI_PNC_AudioDebug_Dialogues"),
        "UI_PNC_AudioDebug_Dialogues", "Dialogues"),
    sfx = resolveText(getText and getText("UI_PNC_AudioDebug_SFX"),
        "UI_PNC_AudioDebug_SFX", "SFX"),
    style = resolveText(getText and getText("UI_PNC_AudioDebug_Style"),
        "UI_PNC_AudioDebug_Style", "VOICE STYLE"),
    voiceType = resolveText(getText and getText("UI_PNC_AudioDebug_VoiceType"),
        "UI_PNC_AudioDebug_VoiceType", "VOICE TYPE"),
    pitch = resolveText(getText and getText("UI_PNC_AudioDebug_Pitch"),
        "UI_PNC_AudioDebug_Pitch", "PITCH"),
    searchVoice = resolveText(getText and getText("UI_PNC_AudioDebug_SearchVoice"),
        "UI_PNC_AudioDebug_SearchVoice", "SEARCH VOICE"),
    searchSFX = resolveText(getText and getText("UI_PNC_AudioDebug_SearchSFX"),
        "UI_PNC_AudioDebug_SearchSFX", "SEARCH SFX"),
    category = resolveText(getText and getText("UI_PNC_AudioDebug_Category"),
        "UI_PNC_AudioDebug_Category", "CATEGORY"),
    play = resolveText(getText and getText("UI_PNC_AudioDebug_Play"),
        "UI_PNC_AudioDebug_Play", "PLAY"),
    stop = resolveText(getText and getText("UI_PNC_AudioDebug_Stop"),
        "UI_PNC_AudioDebug_Stop", "STOP"),
    reset = resolveText(getText and getText("UI_PNC_AudioDebug_Reset"),
        "UI_PNC_AudioDebug_Reset", "RESET"),
    refresh = resolveText(getText and getText("UI_PNC_AudioDebug_Refresh"),
        "UI_PNC_AudioDebug_Refresh", "REFRESH"),
    localPlayer = resolveText(getText and getText("UI_PNC_AudioDebug_LocalPlayer"),
        "UI_PNC_AudioDebug_LocalPlayer", "LOCAL PLAYER"),
    noPlayer = resolveText(getText and getText("UI_PNC_AudioDebug_NoPlayer"),
        "UI_PNC_AudioDebug_NoPlayer", "NO LOCAL PLAYER"),
    noSelection = resolveText(getText and getText("UI_PNC_AudioDebug_NoSelection"),
        "UI_PNC_AudioDebug_NoSelection", "NO AUDIO SELECTED"),
    playFailed = resolveText(getText and getText("UI_PNC_AudioDebug_PlayFailed"),
        "UI_PNC_AudioDebug_PlayFailed", "PLAY FAILED"),
    stopped = resolveText(getText and getText("UI_PNC_AudioDebug_Stopped"),
        "UI_PNC_AudioDebug_Stopped", "STOPPED"),
    resetDone = resolveText(getText and getText("UI_PNC_AudioDebug_ResetDone"),
        "UI_PNC_AudioDebug_ResetDone", "RESET TO PLAYER"),
}

local function makeLabel(parent, value, colorName)
    local color = Theme.colors[colorName or "text"] or Theme.colors.text
    local label = ISLabel:new(0, 0, 20, tostring(value or ""),
        color.r, color.g, color.b, color.a, UIFont.Small, true)
    label:initialise()
    label.psychopatzThemeColorName = colorName or "text"
    parent:addChild(label)
    return label
end

local function setLabel(label, value)
    UI.SetLabelText(label, value)
end

local function makeCombo(parent, target, callback)
    local combo = ISComboBox:new(0, 0, 1, 26, target, callback)
    combo:initialise()
    combo:instantiate()
    parent:addChild(combo)
    return combo
end

local function selectedItem(list)
    local row = list and list:getItem() or nil
    return row and row.item or nil
end

local function drawVoiceItem(list, y, row, alternate)
    local event = row.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == row.index, alternate)
    local title = tostring(event.suffix or "")
    local detail = tostring(event.category or "Voice")
    if event.semanticID then
        detail = detail .. " | " .. tostring(event.semanticID)
    end
    list:drawText(Layout.Ellipsize(title, UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(detail, UIFont.Small,
        list:getWidth() - 14), 8, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawSFXItem(list, y, row, alternate)
    local sound = row.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == row.index, alternate)
    list:drawText(Layout.Ellipsize(tostring(sound.name or ""), UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(tostring(sound.category or ""),
        UIFont.Small, list:getWidth() - 14), 8, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCAudioDebugDialoguesTab = ISPanel:derive("ISPNCAudioDebugDialoguesTab")

function ISPNCAudioDebugDialoguesTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCAudioDebugDialoguesTab:createChildren()
    ISPanel.createChildren(self)
    self.styles = Model.GetVoiceStyles()
    self.events = Model.GetVoiceEvents()

    self.styleLabel = makeLabel(self, TEXT.style, "textMuted")
    self.styleBox = makeCombo(self, self,
        ISPNCAudioDebugDialoguesTab.onStyleChanged)
    for _, style in ipairs(self.styles) do
        self.styleBox:addOptionWithData(tostring(style.name), style)
    end

    self.typeLabel = makeLabel(self, TEXT.voiceType, "textMuted")
    self.typeBox = makeCombo(self, self,
        ISPNCAudioDebugDialoguesTab.onTypeChanged)
    for voiceType = Model.MIN_VOICE_TYPE, Model.MAX_VOICE_TYPE do
        self.typeBox:addOptionWithData(tostring(voiceType), voiceType)
    end

    self.pitchLabel = makeLabel(self, TEXT.pitch, "textMuted")
    local state = Model.GetPlayerVoiceState()
    self.pitch = UI.CreateSlider(self, {
        min = Model.MIN_PITCH,
        max = Model.MAX_PITCH,
        step = 1,
        value = state.pitch,
        target = self,
        onChange = function(owner)
            if owner and owner.updatePitchLabel then
                owner:updatePitchLabel()
            end
        end,
    })
    self.pitchValue = makeLabel(self, "0", "accent")

    self.searchLabel = makeLabel(self, TEXT.searchVoice, "textMuted")
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 200,
        height = 26,
    })
    self.search.onTextChangeFunction = function()
        self:refreshList()
    end

    self.targetLabel = makeLabel(self, "", "textMuted")
    self.status = makeLabel(self, "", "textMuted")
    self.list = UI.CreateList(self, {
        itemHeight = 42,
        doDrawItem = drawVoiceItem,
    })

    self.playButton = UI.CreateButton(self, {
        id = "play",
        title = TEXT.play,
        target = self,
        onclick = ISPNCAudioDebugDialoguesTab.onAction,
        variant = "primary",
    })
    self.stopButton = UI.CreateButton(self, {
        id = "stop",
        title = TEXT.stop,
        target = self,
        onclick = ISPNCAudioDebugDialoguesTab.onAction,
        variant = "danger",
    })
    self.resetButton = UI.CreateButton(self, {
        id = "reset",
        title = TEXT.reset,
        target = self,
        onclick = ISPNCAudioDebugDialoguesTab.onAction,
        variant = "quiet",
    })
    self.buttons = { self.playButton, self.stopButton, self.resetButton }

    local styleIndex = math.max(1, math.min(#self.styles,
        tonumber(state.styleIndex) or 1))
    self.styleBox.selected = styleIndex
    self.typeBox.selected = math.max(1, math.min(4,
        (tonumber(state.voiceType) or 0) + 1))
    self:updatePitchLabel()
    self:refreshTargetLabel()
    self:refreshList()
end

function ISPNCAudioDebugDialoguesTab:getStyle()
    local index = tonumber(self.styleBox and self.styleBox.selected) or 1
    return self.styles[index]
end

function ISPNCAudioDebugDialoguesTab:getVoiceType()
    local value = self.typeBox and self.typeBox:getSelectedData()
    return math.floor(tonumber(value) or Model.MIN_VOICE_TYPE)
end

function ISPNCAudioDebugDialoguesTab:getPitch()
    return self.pitch and self.pitch:getValue() or 0
end

function ISPNCAudioDebugDialoguesTab:getProfile()
    return Model.BuildVoiceProfile(self:getStyle(), self:getVoiceType(),
        self:getPitch())
end

function ISPNCAudioDebugDialoguesTab:getSelectedEvent()
    return selectedItem(self.list)
end

function ISPNCAudioDebugDialoguesTab:updatePitchLabel()
    if self.pitchValue then
        setLabel(self.pitchValue, string.format("%+.0f", self:getPitch()))
    end
end

function ISPNCAudioDebugDialoguesTab:refreshTargetLabel()
    local player = Model.GetCurrentPlayer()
    local name = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    if name == "" then name = TEXT.localPlayer end
    local profile = self:getProfile()
    setLabel(self.targetLabel, string.format("%s | %s | TYPE %d | PITCH %+.0f",
        name, profile.prefix, profile.voiceType, profile.pitch))
end

function ISPNCAudioDebugDialoguesTab:refreshList()
    if not self.list then return end
    local previous = self:getSelectedEvent()
    local previousSuffix = previous and previous.suffix or nil
    local query = string.lower(tostring(self.search:getText() or ""))
    self.list:clear()
    for _, event in ipairs(self.events) do
        local haystack = string.lower(tostring(event.suffix or "")
            .. " " .. tostring(event.category or "")
            .. " " .. tostring(event.semanticID or ""))
        if query == "" or string.find(haystack, query, 1, true) then
            self.list:addItem(event.suffix, event)
            if previousSuffix and previousSuffix == event.suffix then
                self.list.selected = #self.list.items
            end
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
end

function ISPNCAudioDebugDialoguesTab:onStyleChanged()
    local style = self:getStyle()
    if style and self.typeBox then
        self.typeBox.selected = math.max(1, math.min(4,
            (tonumber(style.voiceType) or 0) + 1))
    end
    self:refreshTargetLabel()
end

function ISPNCAudioDebugDialoguesTab:onTypeChanged()
    self:refreshTargetLabel()
end

function ISPNCAudioDebugDialoguesTab:onAction(button)
    local id = button and button.internal or ""
    local player = Model.GetCurrentPlayer()
    if id == "play" then
        local event = self:getSelectedEvent()
        if not player then
            setLabel(self.status, TEXT.noPlayer)
            return
        end
        if not event then
            setLabel(self.status, TEXT.noSelection)
            return
        end
        local handle, reason = Model.PlayDialogue(player, event,
            self:getProfile())
        if handle and handle ~= 0 then
            setLabel(self.status, string.format("PLAYING %s", event.suffix))
        else
            setLabel(self.status, TEXT.playFailed
                .. " | " .. tostring(reason or "unknown"))
        end
    elseif id == "stop" then
        Model.StopDialogue(player)
        setLabel(self.status, TEXT.stopped)
    elseif id == "reset" then
        local state = Model.GetPlayerVoiceState(player)
        local styleIndex = math.max(1, math.min(#self.styles,
            tonumber(state.styleIndex) or 1))
        self.styleBox.selected = styleIndex
        self.typeBox.selected = math.max(1, math.min(4,
            (tonumber(state.voiceType) or 0) + 1))
        self.pitch:setValue(state.pitch, true)
        self:updatePitchLabel()
        self:refreshTargetLabel()
        setLabel(self.status, TEXT.resetDone)
    end
end

function ISPNCAudioDebugDialoguesTab:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local gap = 8
    local labelY = 8
    local controlY = 26
    local styleWidth = math.max(180, math.floor(width * 0.34))
    local typeX = margin + styleWidth + gap
    local typeWidth = 96
    local pitchX = typeX + typeWidth + gap
    local pitchValueWidth = 46
    local pitchWidth = math.max(120, width - pitchX - margin - pitchValueWidth - gap)

    Layout.SetBounds(self.styleLabel, margin, labelY, styleWidth, 18)
    Layout.SetBounds(self.styleBox, margin, controlY, styleWidth, 26)
    Layout.SetBounds(self.typeLabel, typeX, labelY, typeWidth, 18)
    Layout.SetBounds(self.typeBox, typeX, controlY, typeWidth, 26)
    Layout.SetBounds(self.pitchLabel, pitchX, labelY, pitchWidth, 18)
    Layout.SetBounds(self.pitch, pitchX, controlY, pitchWidth, 26)
    Layout.SetBounds(self.pitchValue, pitchX + pitchWidth + gap,
        controlY, pitchValueWidth, 26)

    Layout.SetBounds(self.searchLabel, margin, 58, 120, 18)
    local targetX = margin + 128
    local targetWidth = math.max(120, width - targetX - margin)
    Layout.SetBounds(self.search, targetX, 54, math.min(230, targetWidth), 26)
    Layout.SetBounds(self.targetLabel, targetX + math.min(230, targetWidth) + gap,
        54, math.max(1, width - targetX - math.min(230, targetWidth) - margin - gap), 26)

    local buttonTop = math.max(0, height - 31)
    local statusTop = math.max(82, buttonTop - 26)
    local listTop = 94
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

function ISPNCAudioDebugDialoguesTab:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

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

ISPNCAudioDebugWindow = PsychopatzWindow:derive("ISPNCAudioDebugWindow")

function ISPNCAudioDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAudioDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tabPanel = ISTabPanel:new(0, self:titleBarHeight(), self.width,
        self.height - self:titleBarHeight() - self:resizeWidgetHeight())
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.dialoguesTab = ISPNCAudioDebugDialoguesTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.dialoguesTab:initialise()
    self.dialoguesTab:instantiate()
    self.tabPanel:addView(TEXT.dialogues, self.dialoguesTab)

    self.sfxTab = ISPNCAudioDebugSFXTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.sfxTab:initialise()
    self.sfxTab:instantiate()
    self.tabPanel:addView(TEXT.sfx, self.sfxTab)
    self:onResponsiveLayout()
end

function ISPNCAudioDebugWindow:onResponsiveLayout()
    if not self.tabPanel then return end
    local titleHeight = self:titleBarHeight()
    local resizeHeight = self:resizeWidgetHeight()
    local top = titleHeight + 8
    local panelHeight = math.max(1, self.height - top - resizeHeight - 8)
    local panelWidth = math.max(1, self.width - 20)
    Layout.SetBounds(self.tabPanel, 10, top, panelWidth, panelHeight)
    local viewHeight = math.max(1, panelHeight - self.tabPanel.tabHeight)
    for _, view in ipairs({ self.dialoguesTab, self.sfxTab }) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight,
            panelWidth, viewHeight)
        view:onResponsiveLayout()
    end
end

function ISPNCAudioDebugWindow:close()
    Model.StopAll(Model.GetCurrentPlayer())
    self:setVisible(false)
    self:removeFromUIManager()
    AudioUI.instance = nil
end

function ISPNCAudioDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function AudioUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = AudioUI.instance
    if not window then
        window = UI.NewWindow(ISPNCAudioDebugWindow, {
            title = TEXT.title,
            persistenceKey = "pnc.audioDebug",
            responsiveSpec = {
                width = 900,
                height = 620,
                minWidth = 620,
                minHeight = 440,
                maxWidth = 1400,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        AudioUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestResponsiveLayout(true)
    return window
end

function AudioUI.Toggle()
    if AudioUI.instance and AudioUI.instance:getIsVisible() then
        AudioUI.instance:close()
        return false
    end
    return AudioUI.Open() ~= nil
end

function AudioUI.Reset()
    if AudioUI.instance then
        Model.StopAll(Model.GetCurrentPlayer())
        if AudioUI.instance.removeFromUIManager then
            AudioUI.instance:removeFromUIManager()
        end
    end
    AudioUI.instance = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(AudioUI.Reset)
end

return AudioUI
