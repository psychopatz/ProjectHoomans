require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"
require "ISUI/ISScrollingListBox"
require "PNC/Debug/PNC_AnimationDebugPlayer"

PNC = PNC or {}
PNC.AnimationDebugWindow = PNC.AnimationDebugWindow or {}

local WindowAPI = PNC.AnimationDebugWindow
local DebugPlayer = PNC.AnimationDebugPlayer
local Catalog = PNC.AnimationDebugCatalog
local UI = PsychopatzCore.UI

ISPNCAnimationDebugWindow =
    PsychopatzWindow:derive("ISPNCAnimationDebugWindow")

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function conditionText(condition)
    local operator = "="
    if condition.kind == "GTR" then operator = ">" end
    if condition.kind == "LESS" then operator = "<" end
    if condition.kind == "STRNEQ" then operator = "!=" end
    return tostring(condition.name or "?")
        .. operator
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
        entry.state,
        entry.folder,
        entry.file,
        entry.node,
        entry.anim,
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
        list:drawRect(
            0,
            y,
            list:getWidth(),
            list.itemheight,
            0.35,
            0.20,
            0.52,
            0.78
        )
    elseif alternate then
        list:drawRect(
            0,
            y,
            list:getWidth(),
            list.itemheight,
            0.12,
            0.16,
            0.18,
            0.20
        )
    end
    local title = "[" .. tostring(entry.state or "?") .. "] "
        .. tostring(entry.node or entry.file or "?")
    local clip = tostring(entry.anim or "(no direct clip)")
    local selector = selectorSummary(entry)
    list:drawText(
        title,
        8,
        y + 4,
        entry.playable and 0.92 or 0.62,
        entry.playable and 0.94 or 0.62,
        entry.playable and 1.00 or 0.62,
        1,
        UIFont.Small
    )
    list:drawText(
        clip,
        8,
        y + 21,
        0.62,
        0.82,
        0.95,
        1,
        UIFont.Small
    )
    if selector ~= "" then
        list:drawText(
            selector,
            8,
            y + 38,
            0.72,
            0.72,
            0.72,
            1,
            UIFont.Small
        )
    end
    return y + list.itemheight
end

local function drawDetailItem(list, y, row, alternate)
    local item = row.item
    if alternate then
        list:drawRect(
            0,
            y,
            list:getWidth(),
            list.itemheight,
            0.12,
            0.16,
            0.18,
            0.20
        )
    end
    list:drawText(
        tostring(item.label or ""),
        8,
        y + 6,
        0.62,
        0.72,
        0.80,
        1,
        UIFont.Small
    )
    list:drawText(
        tostring(item.value or ""),
        math.min(150, math.floor(list:getWidth() * 0.34)),
        y + 6,
        item.warning and 1.0 or 0.92,
        item.warning and 0.56 or 0.92,
        item.warning and 0.30 or 0.92,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

local function newList(window, itemHeight, draw)
    local list = ISScrollingListBox:new(0, 0, 100, 100)
    list:initialise()
    list:instantiate()
    list.itemheight = itemHeight
    list.doDrawItem = draw
    list.drawBorder = true
    window:addChild(list)
    return list
end

local function addDetail(list, label, value, warning)
    local display = value
    if display == nil or display == "" then display = "-" end
    list:addItem(tostring(label), {
        label = tostring(label),
        value = tostring(display),
        warning = warning == true,
    })
end

function ISPNCAnimationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAnimationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    self.search = ISTextEntryBox:new("", 0, 0, 100, 25)
    self.search:initialise()
    self.search:instantiate()
    if self.search.setClearButton then
        self.search:setClearButton(true)
    end
    self.search.onTextChange = function()
        self:refreshCatalog()
    end
    self:addChild(self.search)

    self.stateFilter = ISComboBox:new(
        0,
        0,
        160,
        25,
        self,
        ISPNCAnimationDebugWindow.onStateChanged
    )
    self.stateFilter:initialise()
    self.stateFilter:instantiate()
    self.stateFilter:addOption("All states")
    self.states = {}
    for state in pairs(Catalog.stateCounts or {}) do
        self.states[#self.states + 1] = state
    end
    table.sort(self.states)
    for _, state in ipairs(self.states) do
        self.stateFilter:addOption(
            state .. " (" .. tostring(Catalog.stateCounts[state]) .. ")"
        )
    end
    self.stateFilter.selected = 1
    for index, state in ipairs(self.states) do
        if state == "bumped" then
            -- "attack" is the vanilla zombie bite graph and its PNC nodes are
            -- intentionally idle guards. Start on the real NPC action state.
            self.stateFilter.selected = index + 1
            break
        end
    end
    self:addChild(self.stateFilter)

    self.list = newList(self, 56, drawAnimationItem)
    self.details = newList(self, 26, drawDetailItem)

    self.buttons = {}
    local definitions = {
        { "xml", "Play XML Node", "onPlayXML", "selected" },
        { "pipeline", "PNC Pipeline", "onPlayPipeline", "warning" },
        { "raw", "Raw Clip", "onPlayRaw", "quiet" },
        { "replay", "Replay", "onReplay", "quiet" },
        { "finish", "Finish Event", "onFinish", "quiet" },
        { "stop", "Stop / Restore", "onStop", "danger" },
        { "dump", "Dump Trace", "onDump", "quiet" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = ISPNCAnimationDebugWindow[definition[3]],
            variant = definition[4],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshCatalog()
    self:requestResponsiveLayout(true)
end

function ISPNCAnimationDebugWindow:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local contentTop = 58
    local searchWidth = math.max(180, math.floor(width * 0.55))
    local filterX = margin + searchWidth + 8
    local filterWidth = math.max(120, width - filterX - margin)
    self.search:setX(margin)
    self.search:setY(contentTop)
    self.search:setWidth(searchWidth)
    self.search:setHeight(26)
    self.stateFilter:setX(filterX)
    self.stateFilter:setY(contentTop)
    self.stateFilter:setWidth(filterWidth)
    self.stateFilter:setHeight(26)

    local buttonsTop = height - 78
    local mainTop = contentTop + 36
    local mainHeight = math.max(120, buttonsTop - mainTop - 10)
    local leftWidth = math.max(
        260,
        math.floor((width - margin * 3) * 0.56)
    )
    self.list:setX(margin)
    self.list:setY(mainTop)
    self.list:setWidth(leftWidth)
    self.list:setHeight(mainHeight)
    self.details:setX(margin * 2 + leftWidth)
    self.details:setY(mainTop)
    self.details:setWidth(
        math.max(180, width - leftWidth - margin * 3)
    )
    self.details:setHeight(mainHeight)

    local x = margin
    local rowY = buttonsTop
    local buttonWidth = math.max(
        92,
        math.floor((width - margin * 2 - 36) / 4)
    )
    for index, button in ipairs(self.buttons) do
        if index == 5 then
            rowY = rowY + 32
            x = margin
        end
        button:setX(x)
        button:setY(rowY)
        button:setWidth(buttonWidth)
        button:setHeight(27)
        x = x + buttonWidth + 8
    end
end

function ISPNCAnimationDebugWindow:setTarget(contextEntry)
    contextEntry = contextEntry or {}
    if DebugPlayer.IsPreviewing(self.npcId) then
        DebugPlayer.Stop("target_changed")
    end
    self.npcId = tostring(contextEntry.id or "")
    self.npcName = tostring(
        contextEntry.name
            or contextEntry.record and contextEntry.record.name
            or self.npcId
    )
    self.body = DebugPlayer.ResolveBody(
        self.npcId,
        contextEntry.zombie
    )
    self.record = contextEntry.record
        or contextEntry.snapshot
        or {
            id = self.npcId,
            name = self.npcName,
            runtime = { debug = true },
        }
    local title = "NPC Animation Player — " .. self.npcName
    if self.setTitle then self:setTitle(title) else self.title = title end
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onStateChanged()
    self:refreshCatalog()
end

function ISPNCAnimationDebugWindow:selectedState()
    local selected = tonumber(self.stateFilter.selected) or 1
    if selected <= 1 then return nil end
    return self.states[selected - 1]
end

function ISPNCAnimationDebugWindow:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCAnimationDebugWindow:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedEntry()
    local previousKey = previous
        and (previous.state .. "/" .. previous.file)
        or nil
    local query = lower(self.search and self.search:getText() or "")
    local state = self:selectedState()
    self.list:clear()
    for _, entry in ipairs(Catalog.entries or {}) do
        if (not state or entry.state == state)
            and (
                query == ""
                or string.find(searchText(entry), query, 1, true)
            )
        then
            self.list:addItem(
                tostring(entry.node or entry.file),
                entry
            )
            if previousKey
                and previousKey == entry.state .. "/" .. entry.file
            then
                self.list.selected = #self.list.items
            end
        end
    end
    if #self.list.items > 0
        and (tonumber(self.list.selected) or 0) < 1
    then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:refreshDetails(force)
    if not self.details then return end
    local entry = self:getSelectedEntry()
    local key = entry
        and entry.state .. "/" .. entry.file
        or ""
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force
        and key == self.detailKey
        and now < (tonumber(self.nextRuntimeRefreshAt) or 0)
    then
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
    addDetail(
        self.details,
        "Playback route",
        DebugPlayer.GetPlaybackRoute(entry)
    )
    addDetail(
        self.details,
        "Node purpose",
        DebugPlayer.GetEntryNote(entry),
        entry.state == "attack"
            or entry.state == "attack-network"
    )
    addDetail(self.details, "Folder", entry.folder)
    addDetail(self.details, "Node", entry.node)
    addDetail(self.details, "Clip", entry.anim or "(none)", not entry.playable)
    addDetail(self.details, "File", entry.path)
    addDetail(self.details, "Extends", entry.extends or "(none)")
    addDetail(
        self.details,
        "Playback",
        (entry.looped and "looped" or "one-shot")
            .. " @ " .. tostring(entry.speed)
    )
    addDetail(
        self.details,
        "Events",
        tostring(#(entry.events or {}))
            .. "  transitions=" .. tostring(entry.transitionCount or 0)
    )
    for index, condition in ipairs(entry.conditions or {}) do
        addDetail(
            self.details,
            "Condition " .. tostring(index),
            conditionText(condition),
            not condition.name
        )
    end
    for index, event in ipairs(entry.events or {}) do
        addDetail(
            self.details,
            "Event " .. tostring(index),
            tostring(event.name or "?")
                .. " @ " .. tostring(event.time or "?")
                .. (
                    event.parameter and event.parameter ~= ""
                    and " → " .. tostring(event.parameter)
                    or ""
                )
        )
    end
    addDetail(self.details, "Runtime topology", runtime.topology)
    addDetail(
        self.details,
        "Preview owner",
        runtime.active
            and tostring(runtime.npcId) .. " / " .. tostring(runtime.mode)
            or "inactive"
    )
    addDetail(self.details, "ActionContext", runtime.actionState)
    addDetail(self.details, "Previous action", runtime.previousActionState)
    addDetail(self.details, "Advanced state", runtime.advancedState)
    addDetail(self.details, "Animation state", runtime.animationState)
    addDetail(self.details, "BumpType", runtime.bumpType)
    addDetail(self.details, "Track 0:0", runtime.track)
    addDetail(
        self.details,
        "Track time/weight",
        tostring(runtime.trackTime or "-")
            .. " / " .. tostring(runtime.trackWeight or "-")
    )
    addDetail(
        self.details,
        "Last result",
        runtime.result
            and (
                tostring(runtime.result.ok)
                    .. " / " .. tostring(runtime.result.reason)
            )
            or "-"
    )
    addDetail(
        self.details,
        "Skipped selectors",
        #(runtime.skippedSelectors or {}) > 0
            and table.concat(runtime.skippedSelectors, ", ")
            or "none"
    )
end

function ISPNCAnimationDebugWindow:resolveBody()
    self.body = DebugPlayer.ResolveBody(self.npcId, self.body)
    return self.body
end

function ISPNCAnimationDebugWindow:onPlayXML()
    DebugPlayer.PlayXML(
        self:getSelectedEntry(),
        self.npcId,
        self:resolveBody(),
        self.record
    )
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onPlayPipeline()
    DebugPlayer.PlayPipeline(
        self:getSelectedEntry(),
        self.npcId,
        self:resolveBody(),
        self.record
    )
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onPlayRaw()
    DebugPlayer.PlayRaw(
        self:getSelectedEntry(),
        self.npcId,
        self:resolveBody(),
        self.record
    )
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onReplay()
    DebugPlayer.Replay()
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onFinish()
    DebugPlayer.Finish()
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onStop()
    DebugPlayer.Stop("ui_stop")
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:onDump()
    DebugPlayer.Dump()
    self:refreshDetails(true)
end

function ISPNCAnimationDebugWindow:prerender()
    if DebugPlayer.active then
        DebugPlayer.Observe(
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        )
    end
    self:refreshDetails(false)
    local entry = self:getSelectedEntry()
    local body = self:resolveBody()
    if self.xmlButton then
        self.xmlButton:setEnable(entry ~= nil and body ~= nil)
    end
    if self.pipelineButton then
        self.pipelineButton:setEnable(
            entry ~= nil
                and body ~= nil
                and DebugPlayer.CanPipeline(entry)
        )
    end
    if self.rawButton then
        self.rawButton:setEnable(
            entry ~= nil and entry.playable == true and body ~= nil
        )
    end
    local active = DebugPlayer.active ~= nil
    self.replayButton:setEnable(active)
    self.finishButton:setEnable(active)
    self.stopButton:setEnable(active)
    PsychopatzWindow.prerender(self)
end

function ISPNCAnimationDebugWindow:render()
    PsychopatzWindow.render(self)
    local body = self:resolveBody()
    self:drawText(
        "Target: " .. tostring(self.npcName or self.npcId or "?")
            .. " [" .. tostring(self.npcId or "?") .. "]"
            .. (body and " — local body bound" or " — NO LOCAL BODY"),
        12,
        34,
        body and 0.65 or 1.0,
        body and 0.90 or 0.45,
        body and 0.72 or 0.30,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tostring(self.visibleCount or 0)
            .. " / " .. tostring(Catalog.generatedCount or 0)
            .. " XML nodes",
        self:getWidth() - 12,
        34,
        0.72,
        0.78,
        0.84,
        1,
        UIFont.Small
    )
end

function ISPNCAnimationDebugWindow:close()
    DebugPlayer.Stop("window_closed")
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function ISPNCAnimationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WindowAPI.Open(contextEntry)
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCAnimationDebugWindow, {
            title = "NPC Animation Player",
            resizable = true,
            responsiveSpec = {
                width = 1180,
                height = 760,
                minWidth = 760,
                minHeight = 560,
                maxWidth = 1500,
                maxHeight = 980,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    window:setTarget(contextEntry)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    return window
end

local function onResetLua()
    if WindowAPI.instance then WindowAPI.instance:close() end
    DebugPlayer.Stop("lua_reset")
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

return WindowAPI
