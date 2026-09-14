require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_AnimationDebugPlayer"

PNC = PNC or {}
PNC.NPCPresentationDebugTabs = PNC.NPCPresentationDebugTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue
local DebugPlayer = PNC.AnimationDebugPlayer
local Catalog = PNC.AnimationDebugCatalog

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function conditionText(condition)
    local operator = "="
    if condition.kind == "GTR" then operator = ">" end
    if condition.kind == "LESS" then operator = "<" end
    if condition.kind == "STRNEQ" then operator = "!=" end
    return tostring(condition.name or "?") .. operator
        .. tostring(condition.value or "?")
end

local function selectorSummary(entry)
    local values = {}
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name and condition.name ~= "PNCActor" then
            values[#values + 1] = conditionText(condition)
        end
    end
    return table.concat(values, ", ")
end

local function searchText(entry)
    local values = {
        entry.state, entry.folder, entry.file, entry.node, entry.anim,
        entry.extends,
    }
    for _, condition in ipairs(entry.conditions or {}) do
        values[#values + 1] = condition.name
        values[#values + 1] = condition.kind
        values[#values + 1] = condition.value
    end
    for _, event in ipairs(entry.events or {}) do
        values[#values + 1] = event.name
        values[#values + 1] = event.parameter
    end
    return lower(table.concat(values, " "))
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
    local clip = tostring(entry.anim or "(no direct clip)")
    local selector = selectorSummary(entry)
    list:drawText(title, 8, y + 4,
        entry.playable and 0.92 or 0.62,
        entry.playable and 0.94 or 0.62,
        entry.playable and 1.00 or 0.62, 1, UIFont.Small)
    list:drawText(clip, 8, y + 21, 0.62, 0.82, 0.95, 1, UIFont.Small)
    if selector ~= "" then
        list:drawText(selector, 8, y + 38, 0.72, 0.72, 0.72, 1, UIFont.Small)
    end
    return y + list.itemheight
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

ISPNCNPCPresentationDebugAnimationTab = ISPanel:derive(
    "ISPNCNPCPresentationDebugAnimationTab")

function ISPNCNPCPresentationDebugAnimationTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCNPCPresentationDebugAnimationTab:createChildren()
    ISPanel.createChildren(self)
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 25,
        onTextChange = function() self:refreshCatalog() end,
    })
    self.stateFilter = ISComboBox:new(0, 0, 160, 25, self,
        ISPNCNPCPresentationDebugAnimationTab.onStateChanged)
    self.stateFilter:initialise()
    self.stateFilter:instantiate()
    self.stateFilter:addOption("All states")
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
    for index, state in ipairs(self.states) do
        if state == "bumped" then
            self.stateFilter.selected = index + 1
            break
        end
    end
    self:addChild(self.stateFilter)
    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawAnimationItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 26,
        valueXMax = 150,
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
        { "xml", "PLAY XML NODE", "selected" },
        { "pipeline", "PNC PIPELINE", "warning" },
        { "raw", "RAW CLIP", "quiet" },
        { "replay", "REPLAY", "quiet" },
        { "finish", "FINISH EVENT", "quiet" },
        { "stop", "STOP / RESTORE", "danger" },
        { "dump", "DUMP TRACE", "quiet" },
        { "scenes", "SCENE LAB", "selected" },
        { "hold", "HOLD FINAL: ON", "selected" },
        { "freeze", "FREEZE CURRENT FRAME", "warning" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(button)
                return ISPNCNPCPresentationDebugAnimationTab.onAction(self, button)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshCatalog()
end

function ISPNCNPCPresentationDebugAnimationTab:setContext(hub)
    self.hub = hub
    self:refreshCatalog()
end

function ISPNCNPCPresentationDebugAnimationTab:selectedState()
    local selected = tonumber(self.stateFilter and self.stateFilter.selected) or 1
    if selected <= 1 then return nil end
    return self.states[selected - 1]
end

function ISPNCNPCPresentationDebugAnimationTab:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCNPCPresentationDebugAnimationTab:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedEntry()
    local previousKey = previous
        and (previous.state .. "/" .. previous.file) or nil
    local query = lower(self.search and self.search:getText() or "")
    local state = self:selectedState()
    self.list:clear()
    for _, entry in ipairs(Catalog.entries or {}) do
        if (not state or entry.state == state)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            self.list:addItem(tostring(entry.node or entry.file), entry)
            if previousKey and previousKey == entry.state .. "/" .. entry.file then
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

function ISPNCNPCPresentationDebugAnimationTab:refreshDetails(force)
    if not self.details then return end
    local entry = self:getSelectedEntry()
    local key = entry and entry.state .. "/" .. entry.file or ""
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force and key == self.detailKey
        and now < (tonumber(self.nextRuntimeRefreshAt) or 0) then
        return
    end
    self.detailKey = key
    self.nextRuntimeRefreshAt = now + 150
    self.details:clear()
    if not entry then
        addDetail(self.details, "Selection", "No matching XML node", true)
        return
    end
    local runtime = DebugPlayer.Runtime()
    addDetail(self.details, "XML state", entry.state)
    addDetail(self.details, "Playback route", DebugPlayer.GetPlaybackRoute(entry))
    addDetail(self.details, "Node purpose", DebugPlayer.GetEntryNote(entry),
        entry.state == "attack" or entry.state == "attack-network")
    addDetail(self.details, "Folder", entry.folder)
    addDetail(self.details, "Node", entry.node)
    addDetail(self.details, "Clip", entry.anim or "(none)", not entry.playable)
    addDetail(self.details, "File", entry.path)
    addDetail(self.details, "Extends", entry.extends or "(none)")
    addDetail(self.details, "Playback",
        (entry.looped and "looped" or "one-shot") .. " @ " .. tostring(entry.speed))
    addDetail(self.details, "Events", tostring(#(entry.events or {}))
        .. "  transitions=" .. tostring(entry.transitionCount or 0))
    for index, condition in ipairs(entry.conditions or {}) do
        addDetail(self.details, "Condition " .. tostring(index),
            conditionText(condition), not condition.name)
    end
    for index, event in ipairs(entry.events or {}) do
        addDetail(self.details, "Event " .. tostring(index),
            tostring(event.name or "?") .. " @ " .. tostring(event.time or "?")
            .. (event.parameter and event.parameter ~= ""
                and " → " .. tostring(event.parameter) or ""))
    end
    addDetail(self.details, "Runtime topology", runtime.topology)
    addDetail(self.details, "Preview owner",
        runtime.active and tostring(runtime.npcId) .. " / " .. tostring(runtime.mode)
            or "inactive")
    addDetail(self.details, "ActionContext", runtime.actionState)
    addDetail(self.details, "Previous action", runtime.previousActionState)
    addDetail(self.details, "Advanced state", runtime.advancedState)
    addDetail(self.details, "Animation state", runtime.animationState)
    addDetail(self.details, "BumpType", runtime.bumpType)
    addDetail(self.details, "Track 0:0", runtime.track)
    addDetail(self.details, "Track time/weight",
        tostring(runtime.trackTime or "-") .. " / " .. tostring(runtime.trackWeight or "-"))
    addDetail(self.details, "Track frame @ 30 FPS",
        runtime.trackFrame ~= nil and tostring(runtime.trackFrame) or "-")
    addDetail(self.details, "Track source", runtime.trackSource or "-")
    addDetail(self.details, "Track duration", runtime.trackDuration or "-")
    addDetail(self.details, "Pose hold",
        runtime.poseHeld and "HELD" or (runtime.holdPose and "ARMED" or "OFF"),
        runtime.poseHeld)
    addDetail(self.details, "Last result",
        runtime.result and tostring(runtime.result.ok) .. " / "
            .. tostring(runtime.result.reason) or "-")
    addDetail(self.details, "Skipped selectors",
        #(runtime.skippedSelectors or {}) > 0
            and table.concat(runtime.skippedSelectors, ", ") or "none")
end

function ISPNCNPCPresentationDebugAnimationTab:onAction(button)
    local id = button and button.internal or ""
    local hub = self.hub
    if not hub then return end
    local entry = self:getSelectedEntry()
    if id == "xml" then hub:playXML(entry)
    elseif id == "pipeline" then hub:playPipeline(entry)
    elseif id == "raw" then hub:playRaw(entry)
    elseif id == "replay" then DebugPlayer.Replay()
    elseif id == "finish" then DebugPlayer.Finish()
    elseif id == "stop" then DebugPlayer.Stop("ui_stop")
    elseif id == "dump" then DebugPlayer.Dump()
    elseif id == "scenes" then hub:openScenes()
    elseif id == "hold" then
        DebugPlayer.SetHoldPose(not DebugPlayer.IsHoldPoseEnabled())
    elseif id == "freeze" then
        DebugPlayer.HoldCurrentFrame()
    end
    self:refreshDetails(true)
end

function ISPNCNPCPresentationDebugAnimationTab:refreshControls()
    local active = DebugPlayer.active ~= nil
    local runtime = DebugPlayer.Runtime()
    local entry = self:getSelectedEntry()
    local body = self.hub and self.hub:resolveBody() or nil
    local freezeSupported = active and runtime.trackSource == "AnimationPlayer.play"
    if self.xmlButton then self.xmlButton:setEnable(entry ~= nil and body ~= nil) end
    if self.pipelineButton then
        self.pipelineButton:setEnable(entry ~= nil and body ~= nil
            and DebugPlayer.CanPipeline(entry))
    end
    if self.rawButton then
        self.rawButton:setEnable(entry ~= nil and entry.playable == true and body ~= nil)
    end
    if self.replayButton then self.replayButton:setEnable(active) end
    if self.finishButton then self.finishButton:setEnable(active) end
    if self.stopButton then self.stopButton:setEnable(active) end
    setButtonState(self.holdButton,
        "HOLD FINAL: " .. (DebugPlayer.IsHoldPoseEnabled() and "ON" or "OFF"),
        DebugPlayer.IsHoldPoseEnabled() and "selected" or "quiet")
    setButtonState(self.freezeButton,
        runtime.poseHeld and "POSE HELD"
            or (freezeSupported and "FREEZE CURRENT FRAME"
                or "FREEZE: NATIVE TRACK ONLY"),
        runtime.poseHeld and "selected"
            or (freezeSupported and "warning" or "quiet"))
    if self.freezeButton then self.freezeButton:setEnable(freezeSupported) end
end

function ISPNCNPCPresentationDebugAnimationTab:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local top = 12
    local searchWidth = math.max(180, math.floor(width * 0.56))
    local filterX = margin + searchWidth + 8
    Layout.SetBounds(self.search, margin, top, searchWidth, 26)
    Layout.SetBounds(self.stateFilter, filterX, top,
        math.max(120, width - filterX - margin), 26)
    local buttonRows = math.ceil(#self.buttons / 4)
    local buttonsTop = height - buttonRows * 35 - margin
    local mainTop = top + 36
    local mainHeight = math.max(120, buttonsTop - mainTop - 10)
    local leftWidth = math.max(260, math.floor((width - margin * 3) * 0.56))
    Layout.SetBounds(self.list, margin, mainTop, leftWidth, mainHeight)
    Layout.SetBounds(self.details, margin * 2 + leftWidth, mainTop,
        math.max(180, width - leftWidth - margin * 3), mainHeight)
    local buttonWidth = math.max(92,
        math.floor((width - margin * 2 - 36) / 4))
    for index, button in ipairs(self.buttons) do
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        Layout.SetBounds(button, margin + column * (buttonWidth + 8),
            buttonsTop + row * 35, buttonWidth, 27)
    end
end

function ISPNCNPCPresentationDebugAnimationTab:prerender()
    self:refreshDetails(false)
    self:refreshControls()
    ISPanel.prerender(self)
end

function ISPNCNPCPresentationDebugAnimationTab:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ISPNCNPCPresentationDebugAnimationTab
