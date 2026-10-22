require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/WorldKnowledge/PNC_WorldKnowledgeDebugModel"

PNC = PNC or {}
PNC.WorldKnowledgeDebugUI = PNC.WorldKnowledgeDebugUI or {}

local DebugUI = PNC.WorldKnowledgeDebugUI
local Model = PNC.WorldKnowledgeDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function text(key, fallback)
    local translation = PNC.Translation
    if translation and translation.GetKey then
        return translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function selected(list)
    local item = list and list:getItem()
    return item and item.item or nil
end

local function clearList(list)
    list:clear()
    if list.setYScroll then list:setYScroll(0) end
end

local function drawRow(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local color, muted = Theme.colors.text, Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(item.label, UIFont.Small,
        list:getWidth() - 14), 7, y + 4,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.detail, UIFont.Small,
        list:getWidth() - 14), 7, y + 23,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCWorldKnowledgeDebugWindow = PsychopatzWindow:derive(
    "ISPNCWorldKnowledgeDebugWindow")

function ISPNCWorldKnowledgeDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCWorldKnowledgeDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.actors = UI.CreateList(self, { itemHeight = 42, doDrawItem = drawRow })
    self.rows = UI.CreateList(self, { itemHeight = 42, doDrawItem = drawRow })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25, labelX = 8, labelY = 5, valueY = 5,
        valueX = 150, valueRightPadding = 7,
    })
    self.viewCombo = ISComboBox:new(0, 0, 150, 26, self,
        ISPNCWorldKnowledgeDebugWindow.onView)
    self.viewCombo:initialise(); self.viewCombo:instantiate()
    self:addChild(self.viewCombo)
    for _, view in ipairs({ "facts", "knowledge", "context", "why", "trace" }) do
        self.viewCombo:addOptionWithData(view, view)
    end
    self.viewCombo:selectData("facts")
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh", title = text("UI_PNC_WKG_Debug_Refresh", "REFRESH"),
        target = self, onclick = ISPNCWorldKnowledgeDebugWindow.onAction,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
    self:refreshActors()
end

function ISPNCWorldKnowledgeDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 10 })
    local gap = 8
    local actorWidth = math.max(170, math.floor(rect.width * 0.22))
    local detailWidth = math.max(260, math.floor(rect.width * 0.28))
    Layout.SetBounds(self.viewCombo, rect.x, rect.y, 150, 26)
    Layout.SetBounds(self.refreshButton, rect.x + 158, rect.y, 100, 26)
    local top = rect.y + 34
    local height = rect.height - 34
    Layout.SetBounds(self.actors, rect.x, top, actorWidth, height)
    Layout.SetBounds(self.rows, rect.x + actorWidth + gap, top,
        rect.width - actorWidth - detailWidth - gap * 2, height)
    Layout.SetBounds(self.details, rect.x + rect.width - detailWidth, top,
        detailWidth, height)
    self.layout = {
        actors = { x = rect.x, y = top, width = actorWidth, height = height },
        rows = { x = rect.x + actorWidth + gap, y = top,
            width = rect.width - actorWidth - detailWidth - gap * 2,
            height = height },
        details = { x = rect.x + rect.width - detailWidth, y = top,
            width = detailWidth, height = height },
    }
end

function ISPNCWorldKnowledgeDebugWindow:requestSnapshot()
    local actor = selected(self.actors)
    local fact = selected(self.rows)
    self.actorID = actor and actor.actorID or self.actorID
    local factID = self.viewCombo:getOptionData(self.viewCombo.selected) == "why"
        and fact and fact.factID or nil
    self.factID = factID
    PNC.Client.RequestWorldKnowledgeDebug(self.actorID, factID, {
        factLimit = 64, actorLimit = 128, referenceLimit = 64,
        candidateLimit = 16, traceLimit = 64,
    })
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCWorldKnowledgeDebugWindow:refreshActors()
    local old = self.actorID
    clearList(self.actors)
    local roster = ClientState.debugRoster or {}
    local rows = Model.ActorItems(ClientState.worldKnowledgeDebug, roster)
    for _, item in ipairs(rows) do self.actors:addItem(item.label, item) end
    local selectedIndex
    for index, entry in ipairs(self.actors.items or {}) do
        if entry.item and entry.item.actorID == old then selectedIndex = index end
    end
    if selectedIndex then self.actors.selected = selectedIndex
    elseif #rows > 0 then self.actors.selected = 1; self.actorID = rows[1].actorID end
end

function ISPNCWorldKnowledgeDebugWindow:refreshRows()
    local snapshot = ClientState.worldKnowledgeDebug or {}
    local view = self.viewCombo:getOptionData(self.viewCombo.selected) or "facts"
    clearList(self.rows)
    for _, item in ipairs(Model.Rows(snapshot, view)) do
        self.rows:addItem(item.label, item)
    end
    if #(self.rows.items or {}) > 0 and not self.rows:getItem() then
        self.rows.selected = 1
    end
    self:refreshDetails()
end

function ISPNCWorldKnowledgeDebugWindow:refreshDetails()
    local snapshot = ClientState.worldKnowledgeDebug or {}
    local view = self.viewCombo:getOptionData(self.viewCombo.selected) or "facts"
    clearList(self.details)
    for _, item in ipairs(Model.DetailRows(snapshot, selected(self.rows), view)) do
        self.details:addItem(item.label, item)
    end
    if ClientState.worldKnowledgeDebugReason then
        self.details:addItem("Status", {
            label = "Status", value = ClientState.worldKnowledgeDebugReason,
        })
    end
end

function ISPNCWorldKnowledgeDebugWindow:onView()
    local view = self.viewCombo:getOptionData(self.viewCombo.selected)
    if view == "why" then
        local item = selected(self.rows)
        self.factID = item and item.factID or nil
        if self.factID then self:requestSnapshot() end
    else
        self.factID = nil
        self:refreshRows()
    end
end

function ISPNCWorldKnowledgeDebugWindow:onAction(button)
    if button.internal == "refresh" then
        PNC.Client.RequestDebugRoster(false)
        self:requestSnapshot()
    end
end

function ISPNCWorldKnowledgeDebugWindow:prerender()
    local received = ClientState.lastWorldKnowledgeDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then
        self.lastReceiveAt = received
        self:refreshActors()
        self:refreshRows()
    end
    local rosterReceived = ClientState.lastDebugRosterReceiveAt or 0
    if rosterReceived > (self.lastRosterReceiveAt or 0) then
        self.lastRosterReceiveAt = rosterReceived
        self:refreshActors()
    end
    local actor = selected(self.actors)
    if actor and actor.actorID ~= self.actorID then
        self.actorID = actor.actorID
        self.factID = nil
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCWorldKnowledgeDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self, text("UI_PNC_WKG_Debug_Actors", "ACTORS"),
            self.actors:getX(), self.actors:getY() - 20, self.actors:getWidth())
        UI.DrawSectionTitle(self, text("UI_PNC_WKG_Debug_Rows", "INSPECTION"),
            self.rows:getX(), self.rows:getY() - 20, self.rows:getWidth())
        UI.DrawSectionTitle(self, text("UI_PNC_WKG_Debug_Details", "DETAILS"),
            self.details:getX(), self.details:getY() - 20,
            self.details:getWidth())
    end
end

function ISPNCWorldKnowledgeDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCWorldKnowledgeDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    return object
end

function DebugUI.ReceiveSnapshot(snapshot)
    if DebugUI.instance and snapshot then
        DebugUI.instance:refreshActors()
        DebugUI.instance:refreshRows()
    end
end

function DebugUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then return nil end
    if not DebugUI.instance then
        DebugUI.instance = UI.NewWindow(ISPNCWorldKnowledgeDebugWindow, {
            title = text("UI_PNC_WKG_Debug_Title", "WORLD KNOWLEDGE INSPECTOR"),
            resizable = true,
            responsiveSpec = { width = 1180, height = 720,
                minWidth = 800, minHeight = 500,
                maxWidth = 1600, maxHeight = 1000 },
        })
        DebugUI.instance:initialise(); DebugUI.instance:instantiate()
    end
    local window = DebugUI.instance
    window:addToUIManager(); window:setVisible(true); window:bringToTop()
    PNC.Client.RequestDebugRoster(false)
    window:refreshActors(); window:requestSnapshot()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close(); return false
    end
    return DebugUI.Open() ~= nil
end

return DebugUI
