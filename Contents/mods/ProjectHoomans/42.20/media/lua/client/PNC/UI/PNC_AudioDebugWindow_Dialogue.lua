-- Dialogue debug tab and voice playback controls.
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
local drawVoiceItem = Internal.drawVoiceItem


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


return AudioUI
