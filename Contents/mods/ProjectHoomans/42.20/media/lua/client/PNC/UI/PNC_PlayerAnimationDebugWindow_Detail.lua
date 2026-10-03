-- Selected animation details, debug actions, and responsive layout.
local WindowAPI = PNC.PlayerAnimationDebugUI
local Internal = WindowAPI.Internal
local TEXT = Internal.TEXT
local Debug = Internal.Debug
local Layout = Internal.Layout
local addDetail = Internal.addDetail
local setButtonState = Internal.setButtonState

function ISPNCPlayerAnimationDebugWindow:refreshDetails(force)
    if not self.details then return end
    local entry = self:getSelectedEntry()
    local key = entry and tostring(entry.state) .. "/" .. tostring(entry.file)
        .. "/" .. tostring(entry.node) or ""
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force and key == self.detailKey
        and now < (tonumber(self.nextRuntimeRefreshAt) or 0)
    then
        return
    end
    self.detailKey = key
    self.nextRuntimeRefreshAt = now + 150
    self.details:clear()
    local runtime = Debug.Runtime()
    if not entry then
        addDetail(self.details, TEXT.selection,
            self.visibleCount == 0 and TEXT.noMatching or TEXT.noSelection, true)
        addDetail(self.details, TEXT.rawMode, "")
        return
    end

    addDetail(self.details, TEXT.player, runtime.playerName or TEXT.noPlayer,
        runtime.playerReady ~= true)
    addDetail(self.details, TEXT.state, entry.state)
    addDetail(self.details, TEXT.source, entry.source or "-")
    addDetail(self.details, TEXT.sourceState, entry.sourceState or "-")
    addDetail(self.details, TEXT.route, entry.route or "-")
    local previewMode = entry.fullBody == true and TEXT.fullBody
        or (entry.mode == "emote" and TEXT.nativeEmote or TEXT.actionBridge)
    addDetail(self.details, TEXT.previewMode, previewMode)
    addDetail(self.details, TEXT.compatibility,
        entry.playable == true and (entry.compatibility or "-")
            or (entry.unsupportedReason or entry.compatibility or "-"),
        entry.playable ~= true)
    if entry.mode == "emote" then
        addDetail(self.details, TEXT.emote, entry.emote or "-")
    else
        addDetail(self.details, TEXT.action, entry.action or "-")
    end
    addDetail(self.details, TEXT.clip, entry.anim or TEXT.noClip)
    addDetail(self.details, TEXT.file, entry.originalPath or entry.path
        or entry.file)
    if entry.bridgePath then
        addDetail(self.details, TEXT.bridge, entry.bridgePath)
    end
    addDetail(self.details, TEXT.playback,
        (entry.looped and TEXT.looped or TEXT.oneShot) .. " @ "
            .. tostring(entry.speed or 1.0))
    addDetail(self.details, TEXT.loopRequest,
        runtime.loopRequested and TEXT.on or TEXT.off)
    addDetail(self.details, TEXT.time,
        tostring(runtime.actionTime or "-") .. " / "
            .. tostring(runtime.actionDuration or "-"))
    addDetail(self.details, TEXT.result,
        runtime.result and tostring(runtime.result.ok) .. " / "
            .. tostring(runtime.result.reason) or "-")
end

function ISPNCPlayerAnimationDebugWindow:onAction(button)
    local id = button and button.internal or ""
    local entry = self:getSelectedEntry()
    if id == "play" then Debug.Play(entry)
    elseif id == "replay" then Debug.Replay()
    elseif id == "stop" then Debug.Stop("ui_stop")
    elseif id == "dump" then Debug.Dump()
    elseif id == "loop" then Debug.ToggleLoop()
    end
    self:refreshDetails(true)
end

function ISPNCPlayerAnimationDebugWindow:refreshControls()
    local runtime = Debug.Runtime()
    local entry = self:getSelectedEntry()
    local active = runtime.active
    if self.playerTabButton then
        setButtonState(self.playerTabButton, TEXT.playerTab,
            self.activeSource == "player" and "selected" or "quiet")
    end
    if self.zombieTabButton then
        setButtonState(self.zombieTabButton, TEXT.zombieTab,
            self.activeSource == "zombie" and "selected" or "quiet")
    end
    if self.playButton then
        self.playButton:setEnable(entry ~= nil and entry.playable == true
            and runtime.playerReady == true)
    end
    if self.replayButton then self.replayButton:setEnable(active) end
    if self.stopButton then self.stopButton:setEnable(active) end
    if self.loopButton then
        local enabled = Debug.IsLoopEnabled and Debug.IsLoopEnabled() == true
        setButtonState(self.loopButton,
            TEXT.loop .. ": " .. (enabled and TEXT.on or TEXT.off),
            enabled and "selected" or "quiet")
        self.loopButton:setEnable(entry ~= nil or active)
    end
end

function ISPNCPlayerAnimationDebugWindow:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local tabsTop = self:titleBarHeight() + 26
    local top = tabsTop + 34
    local filterX = margin + math.max(180, math.floor(width * 0.56)) + 8
    local tabWidth = math.max(90, math.floor((width - margin * 2 - 8) * 0.18))
    Layout.SetBounds(self.playerTabButton, margin, tabsTop, tabWidth, 27)
    Layout.SetBounds(self.zombieTabButton, margin + tabWidth + 8, tabsTop,
        tabWidth, 27)
    Layout.SetBounds(self.search, margin, top,
        math.max(180, filterX - margin - 8), 26)
    Layout.SetBounds(self.categoryFilter, filterX, top,
        math.max(120, width - filterX - margin), 26)

    local buttonRows = math.ceil(#self.buttons / 4)
    local buttonsTop = height - buttonRows * 35 - margin
    local mainTop = top + 36
    local mainHeight = math.max(120, buttonsTop - mainTop - 10)
    local leftWidth = math.max(260,
        math.floor((width - margin * 3) * 0.56))
    Layout.SetBounds(self.list, margin, mainTop, leftWidth, mainHeight)
    Layout.SetBounds(self.details, margin * 2 + leftWidth, mainTop,
        math.max(180, width - leftWidth - margin * 3), mainHeight)

    local buttonWidth = math.max(110,
        math.floor((width - margin * 2 - 36) / 4))
    for index, button in ipairs(self.buttons) do
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        Layout.SetBounds(button, margin + column * (buttonWidth + 8),
            buttonsTop + row * 35, buttonWidth, 27)
    end
end


return WindowAPI
