require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_PlayerAnimationDebug"
require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

PNC = PNC or {}
PNC.PlayerAnimationDebugUI = PNC.PlayerAnimationDebugUI or {}

local WindowAPI = PNC.PlayerAnimationDebugUI
local Debug = PNC.PlayerAnimationDebug
local Catalog = PNC.PlayerAnimationDebugCatalog
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then return value end
    return fallback
end

local TEXT = {
    title = resolveText(
        getText and PNC.Translation.GetKey("UI_PNC_PlayerAnimation_Title",
            "PLAYER ANIMATION LAB"),
        "UI_PNC_PlayerAnimation_Title", "PLAYER ANIMATION LAB"),
    play = tr("UI_PNC_PlayerAnimation_Play", "PLAY"),
    replay = tr("UI_PNC_PlayerAnimation_Replay", "REPLAY"),
    stop = tr("UI_PNC_PlayerAnimation_Stop", "STOP / RESTORE"),
    dump = tr("UI_PNC_PlayerAnimation_Dump", "DUMP TRACE"),
    loop = tr("UI_PNC_PlayerAnimation_Loop", "LOOP"),
    allStates = tr("UI_PNC_PlayerAnimation_AllStates", "All player animations"),
    search = tr("UI_PNC_PlayerAnimation_Search", "SEARCH PLAYER ANIMATIONS"),
    noClip = tr("UI_PNC_PlayerAnimation_NoClip", "(no player clip)"),
    rawMode = tr("UI_PNC_PlayerAnimation_RawMode",
        "Native player action/emote context; XML state is selected through the supported player API."),
    noPlayer = tr("UI_PNC_PlayerAnimation_NoPlayer", "NO LOCAL PLAYER"),
    noSelection = tr("UI_PNC_PlayerAnimation_NoSelection", "NO ACTION SELECTED"),
    noMatching = tr("UI_PNC_PlayerAnimation_NoMatching", "No matching player animations"),
    selection = tr("UI_PNC_PlayerAnimation_Selection", "Selection"),
    state = tr("UI_PNC_PlayerAnimation_State", "Player action"),
    action = tr("UI_PNC_PlayerAnimation_Action", "Action context"),
    emote = tr("UI_PNC_PlayerAnimation_Emote", "Emote key"),
    clip = tr("UI_PNC_PlayerAnimation_Clip", "Player clip"),
    source = tr("UI_PNC_PlayerAnimation_Source", "Action source"),
    file = tr("UI_PNC_PlayerAnimation_File", "File"),
    playback = tr("UI_PNC_PlayerAnimation_Playback", "Playback"),
    time = tr("UI_PNC_PlayerAnimation_TrackTime", "Action time"),
    result = tr("UI_PNC_PlayerAnimation_Result", "Last result"),
    player = tr("UI_PNC_PlayerAnimation_Player", "Player"),
    looped = tr("UI_PNC_PlayerAnimation_Looped", "looped"),
    oneShot = tr("UI_PNC_PlayerAnimation_OneShot", "one-shot"),
    loopRequest = tr("UI_PNC_PlayerAnimation_LoopRequest", "Loop request"),
    on = tr("UI_PNC_PlayerAnimation_On", "ON"),
    off = tr("UI_PNC_PlayerAnimation_Off", "OFF"),
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function searchText(entry)
    return lower(table.concat({
        entry.state, entry.folder, entry.file, entry.node, entry.anim,
        entry.extends, entry.action, entry.emote,
    }, " "))
end

local function drawAnimationItem(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.52, 0.78)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local title = "[" .. tostring(entry.state or "?") .. "] "
        .. tostring(entry.node or entry.file or "?")
    local clip = tostring(entry.anim or TEXT.noClip)
    local file = tostring(entry.folder or "") .. "/" .. tostring(entry.file or "")
    list:drawText(Layout.Ellipsize(title, UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(clip, UIFont.Small,
        list:getWidth() - 14), 8, y + 21,
        0.62, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(file, UIFont.Small,
        list:getWidth() - 14), 8, y + 38,
        0.70, 0.72, 0.74, 1, UIFont.Small)
    return y + list.itemheight
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

ISPNCPlayerAnimationDebugWindow = PsychopatzWindow:derive(
    "ISPNCPlayerAnimationDebugWindow")

function ISPNCPlayerAnimationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCPlayerAnimationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        tooltip = TEXT.search,
        onTextChange = function() self:refreshCatalog() end,
    })

    self.stateFilter = ISComboBox:new(0, 0, 160, 26, self,
        ISPNCPlayerAnimationDebugWindow.onStateChanged)
    self.stateFilter:initialise()
    self.stateFilter:instantiate()
    self.stateFilter:addOption(TEXT.allStates)
    self.states = {}
    for state in pairs(Catalog.stateCounts or {}) do
        self.states[#self.states + 1] = state
    end
    table.sort(self.states)
    for _, state in ipairs(self.states) do
        self.stateFilter:addOption(state .. " ("
            .. tostring(Catalog.stateCounts[state]) .. ")")
    end
    self.stateFilter.selected = 1
    self:addChild(self.stateFilter)

    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawAnimationItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 26,
        valueXMax = 152,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        labelColor = { r = 0.62, g = 0.72, b = 0.80, a = 1 },
        valueColor = { r = 0.92, g = 0.92, b = 0.92, a = 1 },
        warningColor = { r = 1.0, g = 0.56, b = 0.30, a = 1 },
        alternateColor = { r = 0.16, g = 0.18, b = 0.20, a = 1 },
        alternateAlpha = 0.12,
        drawSelection = false,
    })

    self.buttons = {}
    local definitions = {
        { "play", TEXT.play, "selected" },
        { "replay", TEXT.replay, "quiet" },
        { "stop", TEXT.stop, "danger" },
        { "dump", TEXT.dump, "quiet" },
        { "loop", TEXT.loop, "quiet" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return ISPNCPlayerAnimationDebugWindow.onAction(self, clicked)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshCatalog()
    self:requestResponsiveLayout(true)
end

function ISPNCPlayerAnimationDebugWindow:selectedState()
    local selected = tonumber(self.stateFilter and self.stateFilter.selected) or 1
    if selected <= 1 then return nil end
    return self.states[selected - 1]
end

function ISPNCPlayerAnimationDebugWindow:onStateChanged()
    self:refreshCatalog()
end

function ISPNCPlayerAnimationDebugWindow:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCPlayerAnimationDebugWindow:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedEntry()
    local previousKey = previous
        and (tostring(previous.state) .. "/" .. tostring(previous.file)
            .. "/" .. tostring(previous.node)) or nil
    local query = lower(self.search and self.search:getText() or "")
    local state = self:selectedState()
    self.list:clear()
    for _, entry in ipairs(Catalog.entries or {}) do
        if entry.playable == true
            and (not state or entry.state == state)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            self.list:addItem(tostring(entry.node or entry.file), entry)
            local key = tostring(entry.state) .. "/" .. tostring(entry.file)
                .. "/" .. tostring(entry.node)
            if previousKey and previousKey == key then
                self.list.selected = #self.list.items
            end
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails(true)
end

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
    if entry.mode == "emote" then
        addDetail(self.details, TEXT.emote, entry.emote or "-")
    else
        addDetail(self.details, TEXT.action, entry.action or "-")
    end
    addDetail(self.details, TEXT.clip, entry.anim or TEXT.noClip)
    addDetail(self.details, TEXT.file, entry.path or entry.file)
    addDetail(self.details, TEXT.playback,
        (entry.looped and TEXT.looped or TEXT.oneShot) .. " @ "
            .. tostring(entry.speed or 1.0))
    addDetail(self.details, TEXT.loopRequest,
        runtime.loopRequested and TEXT.on or TEXT.off)
    addDetail(self.details, TEXT.source, runtime.actionSource or "-")
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
    if self.playButton then
        self.playButton:setEnable(entry ~= nil and runtime.playerReady == true)
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
    local top = 58
    local filterX = margin + math.max(180, math.floor(width * 0.56)) + 8
    Layout.SetBounds(self.search, margin, top,
        math.max(180, filterX - margin - 8), 26)
    Layout.SetBounds(self.stateFilter, filterX, top,
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

function ISPNCPlayerAnimationDebugWindow:prerender()
    Debug.Maintain()
    self:refreshDetails(false)
    self:refreshControls()
    PsychopatzWindow.prerender(self)
end

function ISPNCPlayerAnimationDebugWindow:render()
    PsychopatzWindow.render(self)
    local runtime = Debug.Runtime()
    local top = self:titleBarHeight() + 7
    self:drawText(TEXT.rawMode, 12, top,
        0.72, 0.78, 0.84, 1, UIFont.Small)
    self:drawTextRight(runtime.playerName or TEXT.noPlayer,
        self:getWidth() - 12, top,
        runtime.playerReady and 0.65 or 1.0,
        runtime.playerReady and 0.90 or 0.45,
        runtime.playerReady and 0.72 or 0.30,
        1, UIFont.Small)
end

function ISPNCPlayerAnimationDebugWindow:close()
    Debug.Stop("window_closed")
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function ISPNCPlayerAnimationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WindowAPI.Open()
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCPlayerAnimationDebugWindow, {
            title = TEXT.title,
            resizable = true,
            responsiveSpec = {
                width = 1080,
                height = 720,
                minWidth = 740,
                minHeight = 520,
                maxWidth = 1500,
                maxHeight = 980,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestResponsiveLayout(true)
    return window
end

function WindowAPI.Toggle()
    if WindowAPI.instance and WindowAPI.instance:getIsVisible() then
        WindowAPI.instance:close()
        return nil
    end
    return WindowAPI.Open()
end

local function onResetLua()
    if WindowAPI.instance then WindowAPI.instance:close() end
    Debug.Stop("lua_reset")
end

if Events and Events.OnResetLua and Events.OnResetLua.Add
    and not WindowAPI._resetHook
then
    Events.OnResetLua.Add(onResetLua)
    WindowAPI._resetHook = true
end

return WindowAPI
