-- Dedicated 2-tab ConvoEngine Beat Debug UI:
--   Tab 1 (OVERVIEW): live beat engine telemetry, cached variables, and recent usage.
--   Tab 2 (BEAT TESTER): select nearby NPCs + Player into the cast, pick any
--   registered .convo beat + optional context overrides, and execute it live in-game.

require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/ConvoEngine/PNC_BeatDebugModel"

PNC = PNC or {}
PNC.BeatDebugUI = PNC.BeatDebugUI or {}

local DebugUI = PNC.BeatDebugUI
local Model = PNC.BeatDebugModel
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local ROLE_OPTIONS = { "(auto)", "colonist", "companion", "trader", "survivor", "looter", "bandit", "guard" }
local BOND_OPTIONS = { "(auto)", "stranger", "friend", "lover", "spouse", "parent", "child", "sibling", "family", "rival" }
local MOOD_OPTIONS = { "(auto)", "calm", "cheerful", "tired", "stressed", "unhappy", "hungry", "in_pain", "panicked" }
local TIME_OPTIONS = { "(auto)", "dawn", "day", "dusk", "night" }

local function selectedItem(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function clearList(list)
    if not list then return end
    list:clear()
    if list.setYScroll then list:setYScroll(0) end
end

local function drawTwoLineRow(list, y, entry, alternate)
    local item = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local color, muted = Theme.colors.text, Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(tostring(item.label or ""), UIFont.Small, list:getWidth() - 14),
        7, y + 3, color.r, color.g, color.b, color.a, UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(tostring(item.detail or ""), UIFont.Small, list:getWidth() - 14),
        7, y + 20, muted.r, muted.g, muted.b, muted.a, UIFont.Small
    )
    return y + list.itemheight
end

local function makeCombo(parent, values)
    local combo = ISComboBox:new(0, 0, 140, 24, parent, nil)
    combo:initialise()
    combo:instantiate()
    for i = 1, #values do
        combo:addOptionWithData(values[i], values[i])
    end
    combo:selectData("(auto)")
    parent:addChild(combo)
    return combo
end

ISPNCBeatDebugWindow = PsychopatzWindow:derive("ISPNCBeatDebugWindow")

function ISPNCBeatDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCBeatDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.activeTab = "overview"
    self.selectedActors = {}
    self.lastResult = nil

    -- Top tab bar
    self.tabOverviewBtn = UI.CreateButton(self, {
        id = "tab_overview", title = "OVERVIEW",
        target = self, onclick = function() self:setTab("overview") end,
        variant = "primary",
    })
    self.tabTesterBtn = UI.CreateButton(self, {
        id = "tab_tester", title = "BEAT TESTER",
        target = self, onclick = function() self:setTab("tester") end,
        variant = "quiet",
    })
    self.refreshBtn = UI.CreateButton(self, {
        id = "refresh", title = "REFRESH",
        target = self, onclick = function() self:refreshAll() end,
        variant = "quiet",
    })

    -- Tab 1: Overview widgets
    self.overviewKV = UI.CreateKeyValueList(self, {
        itemHeight = 24, labelX = 8, labelY = 4, valueY = 4,
        valueX = 185, valueRightPadding = 8,
    })
    self.recentList = UI.CreateList(self, { itemHeight = 38, doDrawItem = drawTwoLineRow })

    -- Tab 2: Tester widgets
    self.availableActorsList = UI.CreateList(self, { itemHeight = 38, doDrawItem = drawTwoLineRow })
    self.selectedActorsList = UI.CreateList(self, { itemHeight = 38, doDrawItem = drawTwoLineRow })
    self.addActorBtn = UI.CreateButton(self, {
        id = "add_actor", title = "+ ADD ACTOR",
        target = self, onclick = function() self:onAddActor() end,
        variant = "quiet",
    })
    self.removeActorBtn = UI.CreateButton(self, {
        id = "remove_actor", title = "- REMOVE",
        target = self, onclick = function() self:onRemoveActor() end,
        variant = "quiet",
    })
    self.clearActorsBtn = UI.CreateButton(self, {
        id = "clear_actors", title = "CLEAR",
        target = self, onclick = function() self:onClearActors() end,
        variant = "quiet",
    })

    self.beatSearchEntry = UI.CreateTextEntry(self, {
        x = 0, y = 0, width = 180, height = 24,
        tooltip = "Filter beat pool IDs...",
    })
    self.beatSearchEntry.onTextChange = function() self:refreshBeats() end
    self.beatsList = UI.CreateList(self, { itemHeight = 38, doDrawItem = drawTwoLineRow })

    self.roleCombo = makeCombo(self, ROLE_OPTIONS)
    self.bondCombo = makeCombo(self, BOND_OPTIONS)
    self.moodCombo = makeCombo(self, MOOD_OPTIONS)
    self.timeCombo = makeCombo(self, TIME_OPTIONS)
    self.executeBtn = UI.CreateButton(self, {
        id = "execute_beat", title = "EXECUTE BEAT",
        target = self, onclick = function() self:onExecuteBeat() end,
        variant = "primary",
    })
    self.traceKV = UI.CreateKeyValueList(self, {
        itemHeight = 24, labelX = 8, labelY = 4, valueY = 4,
        valueX = 120, valueRightPadding = 8,
    })

    self:applyTabVisibility()
    self:requestResponsiveLayout(true)
    self:refreshAll()
end

function ISPNCBeatDebugWindow:setTab(tab)
    self.activeTab = (tab == "tester") and "tester" or "overview"
    self:applyTabVisibility()
    self:refreshAll()
end

function ISPNCBeatDebugWindow:applyTabVisibility()
    local isOverview = self.activeTab == "overview"
    local isTester = not isOverview
    local overviewWidgets = { self.overviewKV, self.recentList }
    local testerWidgets = {
        self.availableActorsList, self.selectedActorsList,
        self.addActorBtn, self.removeActorBtn, self.clearActorsBtn,
        self.beatSearchEntry, self.beatsList,
        self.roleCombo, self.bondCombo, self.moodCombo, self.timeCombo,
        self.executeBtn, self.traceKV,
    }
    for _, w in ipairs(overviewWidgets) do
        if w and w.setVisible then w:setVisible(isOverview) end
    end
    for _, w in ipairs(testerWidgets) do
        if w and w.setVisible then w:setVisible(isTester) end
    end
end

function ISPNCBeatDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 10 })
    local gap = 8
    Layout.SetBounds(self.tabOverviewBtn, rect.x, rect.y, 120, 26)
    Layout.SetBounds(self.tabTesterBtn, rect.x + 126, rect.y, 130, 26)
    Layout.SetBounds(self.refreshBtn, rect.x + rect.width - 96, rect.y, 96, 26)

    local bodyY = rect.y + 34
    local bodyH = math.max(180, rect.height - 34)

    -- Tab 1 layout
    local leftW = math.floor(rect.width * 0.44)
    Layout.SetBounds(self.overviewKV, rect.x, bodyY, leftW, bodyH)
    Layout.SetBounds(self.recentList, rect.x + leftW + gap, bodyY, rect.width - leftW - gap, bodyH)

    -- Tab 2 layout (3 columns: Actors | Beats | Overrides & Trace)
    local col1W = math.max(210, math.floor(rect.width * 0.28))
    local col3W = math.max(230, math.floor(rect.width * 0.30))
    local col2W = math.max(200, rect.width - col1W - col3W - gap * 2)
    local col2X = rect.x + col1W + gap
    local col3X = col2X + col2W + gap

    local halfActorH = math.floor((bodyH - 36) / 2)
    Layout.SetBounds(self.availableActorsList, rect.x, bodyY, col1W, halfActorH)
    local btnRowY = bodyY + halfActorH + 4
    local thirdW = math.floor((col1W - 8) / 3)
    Layout.SetBounds(self.addActorBtn, rect.x, btnRowY, thirdW + 10, 26)
    Layout.SetBounds(self.removeActorBtn, rect.x + thirdW + 14, btnRowY, thirdW - 5, 26)
    Layout.SetBounds(self.clearActorsBtn, rect.x + (thirdW * 2) + 13, btnRowY, col1W - (thirdW * 2) - 13, 26)
    Layout.SetBounds(self.selectedActorsList, rect.x, btnRowY + 32, col1W, bodyH - halfActorH - 36)

    Layout.SetBounds(self.beatSearchEntry, col2X, bodyY, col2W, 24)
    Layout.SetBounds(self.beatsList, col2X, bodyY + 30, col2W, bodyH - 30)

    Layout.SetBounds(self.roleCombo, col3X, bodyY, col3W, 24)
    Layout.SetBounds(self.bondCombo, col3X, bodyY + 30, col3W, 24)
    Layout.SetBounds(self.moodCombo, col3X, bodyY + 60, col3W, 24)
    Layout.SetBounds(self.timeCombo, col3X, bodyY + 90, col3W, 24)
    Layout.SetBounds(self.executeBtn, col3X, bodyY + 122, col3W, 30)
    Layout.SetBounds(self.traceKV, col3X, bodyY + 160, col3W, math.max(80, bodyH - 160))
end

function ISPNCBeatDebugWindow:refreshOverview()
    local kv, recent = Model.BuildOverview()
    clearList(self.overviewKV)
    for _, row in ipairs(kv) do
        self.overviewKV:addItem(row.label, row)
    end
    clearList(self.recentList)
    for _, row in ipairs(recent) do
        self.recentList:addItem(row.label, row)
    end
end

function ISPNCBeatDebugWindow:refreshActors()
    local actors = Model.CollectAvailableActors()
    clearList(self.availableActorsList)
    for _, a in ipairs(actors) do
        self.availableActorsList:addItem(a.label, a)
    end
    self:refreshSelectedActors()
end

function ISPNCBeatDebugWindow:refreshSelectedActors()
    clearList(self.selectedActorsList)
    for i, a in ipairs(self.selectedActors) do
        local slot = (i == 1 and "SPEAKER") or (i == 2 and "ADDRESSEE") or ("BYSTANDER #" .. tostring(i - 2))
        self.selectedActorsList:addItem(a.name, {
            id = a.id,
            label = tostring(i) .. ". " .. tostring(a.name or a.id),
            detail = slot .. " (" .. tostring(a.npcType or "npc") .. ")",
            actor = a,
        })
    end
end

function ISPNCBeatDebugWindow:refreshBeats()
    local query = self.beatSearchEntry and self.beatSearchEntry:getText() or ""
    local beats = Model.ListBeats(query)
    clearList(self.beatsList)
    for _, b in ipairs(beats) do
        self.beatsList:addItem(b.label, b)
    end
end

function ISPNCBeatDebugWindow:refreshTrace()
    clearList(self.traceKV)
    local r = self.lastResult
    if not r then
        self.traceKV:addItem("Status", { label = "Status", value = "Select actors + beat, click EXECUTE" })
        return
    end
    self.traceKV:addItem("OK", { label = "Result", value = r.ok and "EXECUTED" or ("FAILED: " .. tostring(r.reason)) })
    if r.poolID then self.traceKV:addItem("Beat", { label = "Beat Pool", value = tostring(r.poolID) }) end
    if r.variantID then self.traceKV:addItem("Variant", { label = "Variant", value = tostring(r.variantID) }) end
    if r.speakerName then self.traceKV:addItem("Speaker", { label = "Speaker", value = tostring(r.speakerName) }) end
    if r.channel then self.traceKV:addItem("Channel", { label = "Pipeline", value = tostring(r.channel) }) end
    if r.turnCount then self.traceKV:addItem("Turns", { label = "Turns", value = tostring(r.turnCount) }) end
    if r.offersCount then self.traceKV:addItem("Offers", { label = "Offers", value = tostring(r.offersCount) }) end
    if r.text then self.traceKV:addItem("Line", { label = "Realized", value = tostring(r.text) }) end
end

function ISPNCBeatDebugWindow:refreshAll()
    self:refreshOverview()
    self:refreshActors()
    self:refreshBeats()
    self:refreshTrace()
end

function ISPNCBeatDebugWindow:onAddActor()
    local actor = selectedItem(self.availableActorsList)
    if not actor then return end
    for _, existing in ipairs(self.selectedActors) do
        if tostring(existing.id) == tostring(actor.id) then return end
    end
    self.selectedActors[#self.selectedActors + 1] = actor
    self:refreshSelectedActors()
end

function ISPNCBeatDebugWindow:onRemoveActor()
    local row = selectedItem(self.selectedActorsList)
    if not row then return end
    for i = #self.selectedActors, 1, -1 do
        if tostring(self.selectedActors[i].id) == tostring(row.id) then
            table.remove(self.selectedActors, i)
            break
        end
    end
    self:refreshSelectedActors()
end

function ISPNCBeatDebugWindow:onClearActors()
    self.selectedActors = {}
    self:refreshSelectedActors()
end

function ISPNCBeatDebugWindow:onExecuteBeat()
    local beat = selectedItem(self.beatsList)
    local overrides = {
        actorRole = self.roleCombo and self.roleCombo:getOptionData(self.roleCombo.selected) or nil,
        relBond = self.bondCombo and self.bondCombo:getOptionData(self.bondCombo.selected) or nil,
        moodPrimary = self.moodCombo and self.moodCombo:getOptionData(self.moodCombo.selected) or nil,
        timeBand = self.timeCombo and self.timeCombo:getOptionData(self.timeCombo.selected) or nil,
    }
    if overrides.moodPrimary == "in_pain" then overrides.moodInPain = true end
    if overrides.moodPrimary == "panicked" then overrides.moodPanicked = true end
    self.lastResult = Model.ExecuteBeat(self.selectedActors, beat and beat.id or "", overrides)
    self:refreshTrace()
    self:refreshOverview()
end

function ISPNCBeatDebugWindow:close()
    PsychopatzWindow.close(self)
    if DebugUI.instance == self then DebugUI.instance = nil end
end

function ISPNCBeatDebugWindow:new(x, y, width, height)
    local o = PsychopatzWindow:new(x, y, width, height, {
        title = "ConvoEngine Beat Lab",
        minimumWidth = 760,
        minimumHeight = 460,
    })
    setmetatable(o, self)
    self.__index = self
    return o
end

function DebugUI.Open()
    if DebugUI.instance then
        DebugUI.instance:setVisible(true)
        DebugUI.instance:bringToTop()
        DebugUI.instance:refreshAll()
        return DebugUI.instance
    end
    local sw = getCore and getCore():getScreenWidth() or 1280
    local sh = getCore and getCore():getScreenHeight() or 720
    local w = math.min(960, math.max(760, sw - 120))
    local h = math.min(620, math.max(460, sh - 120))
    local win = ISPNCBeatDebugWindow:new(math.floor((sw - w) / 2), math.floor((sh - h) / 2), w, h)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    DebugUI.instance = win
    return win
end

function DebugUI.Close()
    if DebugUI.instance then DebugUI.instance:close() end
end

function DebugUI.Toggle()
    if DebugUI.instance then
        DebugUI.Close()
        return nil
    end
    return DebugUI.Open()
end

return DebugUI
