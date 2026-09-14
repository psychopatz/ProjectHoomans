require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/UniqueNPC/PNC_UniqueNPCDebugModel"

PNC = PNC or {}
PNC.UniqueNPCDebugUI = PNC.UniqueNPCDebugUI or {}

local DebugUI = PNC.UniqueNPCDebugUI
local Model = PNC.UniqueNPCDebugModel
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local ClientState = PNC.Network.ClientState

local FILTER_KEYS = {
    All = "UI_PNC_UniqueNPCDebug_Filter_All",
    Unspawned = "UI_PNC_UniqueNPCDebug_Filter_Unspawned",
    Reserved = "UI_PNC_UniqueNPCDebug_Filter_Reserved",
    Alive = "UI_PNC_UniqueNPCDebug_Filter_Alive",
    Dead = "UI_PNC_UniqueNPCDebug_Filter_Dead",
    Problems = "UI_PNC_UniqueNPCDebug_Filter_Problems",
}

local function tr(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= "" and value ~= key then return value end
    end
    return fallback or key
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function statusColor(status, problem)
    if problem then return Theme.colors.danger end
    if status == "alive" then return Theme.colors.success end
    if status == "dead" then return Theme.colors.danger end
    if status == "reserved" then return Theme.colors.warning end
    return Theme.colors.textMuted
end

local function drawEntry(list, y, listEntry, alternate)
    local item = listEntry.item or {}
    local color = statusColor(item.status, item.entry
        and (item.entry.integrity or item.entry.registrationError))
    local muted = Theme.colors.textMuted
    local selectedRow = list.selected == listEntry.index
    UI.DrawListSelection(list, y, list.itemheight, selectedRow, alternate)
    list:drawText(Layout.Ellipsize(item.label or item.id or "Unknown",
        UIFont.Small, list:getWidth() - 112), 9, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.detail or "", UIFont.Small,
        list:getWidth() - 18), 9, y + 25,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    UI.DrawBadge(list, Model.StatusText(item.entry),
        list:getWidth() - 10, y + 7, item.status == "dead" and "danger"
            or item.status == "alive" and "success"
            or item.status == "reserved" and "warning" or "quiet")
    return y + list.itemheight
end

ISPNCUniqueNPCDebugWindow = PsychopatzWindow:derive(
    "ISPNCUniqueNPCDebugWindow")

function ISPNCUniqueNPCDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCUniqueNPCDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.filterButtons = {}
    self.topControls = {}
    self.filters = { "All", "Unspawned", "Reserved", "Alive", "Dead", "Problems" }
    for _, filter in ipairs(self.filters) do
        local button = UI.CreateButton(self, {
            id = filter,
            title = tr(FILTER_KEYS[filter], filter),
            target = self,
            onclick = ISPNCUniqueNPCDebugWindow.onFilter,
            variant = filter == self.filter and "selected" or "quiet",
        })
        self.filterButtons[filter] = button
        self.topControls[#self.topControls + 1] = button
    end
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PNC_UniqueNPCDebug_Refresh", "REFRESH"),
        target = self,
        onclick = ISPNCUniqueNPCDebugWindow.onAction,
        variant = "quiet",
    })
    self.locateButton = UI.CreateButton(self, {
        id = "locate",
        title = tr("UI_PNC_UniqueNPCDebug_Locate", "LOCATE"),
        target = self,
        onclick = ISPNCUniqueNPCDebugWindow.onAction,
        variant = "selected",
    })
    self.spawnTestButton = UI.CreateButton(self, {
        id = "spawn_test",
        title = tr("UI_PNC_UniqueNPCDebug_SpawnTest", "SPAWN TEST"),
        target = self,
        onclick = ISPNCUniqueNPCDebugWindow.onAction,
        variant = "primary",
    })
    self.topControls[#self.topControls + 1] = self.refreshButton
    self.topControls[#self.topControls + 1] = self.locateButton
    self.topControls[#self.topControls + 1] = self.spawnTestButton
    self.list = UI.CreateList(self, {
        itemHeight = Layout.Pixels(45, self.uiScale),
        doDrawItem = drawEntry,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(210, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.38,
    })
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
    self:refreshSnapshot(true)
end

function ISPNCUniqueNPCDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 58, bottom = 12 })
    local top = Layout.Flow(self.topControls, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = self.uiScale, minWidth = 68 })
    local mainY = top.bottom + Layout.Pixels(20, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local listWidth = math.max(Layout.Pixels(280, self.uiScale),
        math.floor(rect.width * 0.40))
    local height = math.max(100, rect.y + rect.height - mainY)
    self.layout = {
        list = { x = rect.x, y = mainY, width = listWidth, height = height },
        details = { x = rect.x + listWidth + gap, y = mainY,
            width = rect.width - listWidth - gap, height = height },
    }
    Layout.SetBounds(self.list, self.layout.list.x, self.layout.list.y,
        self.layout.list.width, self.layout.list.height)
    Layout.SetBounds(self.details, self.layout.details.x, self.layout.details.y,
        self.layout.details.width, self.layout.details.height)
end

function ISPNCUniqueNPCDebugWindow:getSelected()
    return selected(self.list)
end

function ISPNCUniqueNPCDebugWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestUniqueNPCDebug then
        PNC.Client.RequestUniqueNPCDebug()
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCUniqueNPCDebugWindow:onFilter(button)
    self.filter = button and button.internal or "All"
    for filter, filterButton in pairs(self.filterButtons or {}) do
        UI.SetButtonVariant(filterButton,
            filter == self.filter and "selected" or "quiet")
    end
    self:refreshSnapshot(true)
end

function ISPNCUniqueNPCDebugWindow:refreshDetails()
    self.details:clear()
    local item = self:getSelected()
    if not item or not item.entry then
        local snapshot = ClientState.uniqueNPCDebug
        local hasDefinitions = snapshot
            and (#(snapshot.entries or {}) > 0
                or #(snapshot.registrationErrors or {}) > 0)
        local message
        if not snapshot then
            message = tr("UI_PNC_UniqueNPCDebug_Unavailable",
                "Snapshot unavailable")
        elseif not hasDefinitions then
            message = tr("UI_PNC_UniqueNPCDebug_NoDefinitions",
                "No server definitions registered. Produce files are client-local until added to shared/server bootstrap.")
        else
            message = tr("UI_PNC_UniqueNPCDebug_NoneSelected",
                "No unique NPC selected")
        end
        self.details:addItem("empty", {
            label = tr("UI_PNC_UniqueNPCDebug_Details", ""),
            value = message,
        })
        return
    end
    for index, row in ipairs(Model.BuildDetailRows(item.entry)) do
        local display = {}
        for key, value in pairs(row) do display[key] = value end
        display.label = tr(row.labelKey, row.fallback)
        display.value = row.value
        self.details:addItem("row_" .. tostring(index), display)
    end
end

function ISPNCUniqueNPCDebugWindow:refreshSnapshot(force)
    local previous = self:getSelected()
    local previousID = previous and previous.id or self.selectedID
    local snapshot = ClientState.uniqueNPCDebug
    local items = Model.BuildItems(snapshot, self.filter, self.query)
    self.list:clear()
    for _, item in ipairs(items) do self.list:addItem(item.label, item) end
    self.list.selected = 0
    if previousID then
        for index, entry in ipairs(self.list.items or {}) do
            if entry.item and entry.item.id == previousID then
                self.list.selected = index
                break
            end
        end
    end
    if self.list.selected == 0 and #self.list.items > 0 then
        self.list.selected = 1
    end
    self.selectedID = self:getSelected()
        and self:getSelected().id or previousID
    self.lastReceiveAt = tonumber(ClientState.lastUniqueNPCDebugReceiveAt) or 0
    self:refreshDetails()
    self:updateControlState()
end

function ISPNCUniqueNPCDebugWindow:updateControlState()
    local item = self:getSelected()
    local targetID = item and item.entry and item.entry.runtime
        and item.entry.runtime.runtimeNpcId or nil
    local tracking = PNC.NPCMonitor and PNC.NPCMonitor.trackedId
    local isTracked = targetID and tostring(targetID) == tostring(tracking)
    if self.locateButton then
        self.locateButton:setEnable(item ~= nil and Model.IsLocatable(item.entry))
        self.locateButton:setTitle(isTracked
            and tr("UI_PNC_UniqueNPCDebug_StopLocate", "STOP LOCATE")
            or tr("UI_PNC_UniqueNPCDebug_Locate", "LOCATE"))
        UI.SetButtonVariant(self.locateButton,
            isTracked and "danger" or "selected")
    end
    if self.spawnTestButton then
        self.spawnTestButton:setEnable(item ~= nil
            and Model.IsTestSpawnable(item.entry))
    end
end

function ISPNCUniqueNPCDebugWindow:onLocate()
    local item = self:getSelected()
    local entry = item and item.entry or nil
    local live = entry and entry.runtime or nil
    if not Model.IsLocatable(entry) then return end
    if PNC.NPCMonitor and PNC.NPCMonitor.trackedId
        and tostring(PNC.NPCMonitor.trackedId)
            == tostring(live.runtimeNpcId)
    then
        PNC.NPCMonitor.ClearTrack()
    elseif PNC.NPCMonitor and PNC.NPCMonitor.TrackTarget then
        PNC.NPCMonitor.TrackTarget({
            id = tostring(live.runtimeNpcId),
            name = live.name or entry.displayName,
            tacticalClass = live.tacticalClass,
            presenceState = live.presenceState,
            bodyLease = live.bodyLease,
            x = live.x,
            y = live.y,
            z = live.z,
        })
    elseif PNC.NPCTracking and PNC.NPCTracking.Track then
        PNC.NPCTracking.Track({
            id = tostring(live.runtimeNpcId),
            name = live.name or entry.displayName,
            tacticalClass = live.tacticalClass,
            x = live.x,
            y = live.y,
            z = live.z,
        })
    end
    self:updateControlState()
end

function ISPNCUniqueNPCDebugWindow:onSpawnTest()
    local item = self:getSelected()
    local entry = item and item.entry or nil
    if not Model.IsTestSpawnable(entry) then return end
    if PNC.Client and PNC.Client.SendDebug then
        PNC.Client.SendDebug("spawn_unique_test", {
            definitionId = tostring(entry.definitionId),
        })
    end
end

function ISPNCUniqueNPCDebugWindow:onAction(button)
    if not button then return end
    if button.internal == "refresh" then
        self:requestSnapshot()
        return
    end
    if button.internal == "locate" then self:onLocate() end
    if button.internal == "spawn_test" then self:onSpawnTest() end
end

function ISPNCUniqueNPCDebugWindow:prerender()
    local now = PNC.Core.Now()
    local receiveAt = tonumber(ClientState.lastUniqueNPCDebugReceiveAt) or 0
    if receiveAt > (tonumber(self.lastReceiveAt) or 0) then
        self:refreshSnapshot(false)
    end
    if now - (tonumber(self.lastRequestAt) or 0) >= 3000 then
        self:requestSnapshot()
    end
    if self.list.selected ~= self.lastSelection then
        self.lastSelection = self.list.selected
        self:refreshDetails()
    end
    if PNC.NPCMonitor and PNC.NPCMonitor.UpdateTrackedMarker then
        PNC.NPCMonitor.UpdateTrackedMarker(false)
    end
    self:updateControlState()
    PsychopatzWindow.prerender(self)
end

function ISPNCUniqueNPCDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local snapshot = ClientState.uniqueNPCDebug
    local counts = snapshot and snapshot.counts or {}
    local summary = string.format(
        "%d total | %d alive | %d dead | %d problems | %d registration errors",
        tonumber(counts.total) or 0, tonumber(counts.alive) or 0,
        tonumber(counts.dead) or 0, tonumber(counts.problems) or 0,
        tonumber(counts.registrationErrors) or 0)
    UI.DrawSectionTitle(self, tr("UI_PNC_UniqueNPCDebug_Registered",
        "REGISTERED UNIQUE NPCS"), self.layout.list.x,
        self.layout.list.y - Layout.Pixels(20, self.uiScale),
        self.layout.list.width, summary)
    local selectedItem = self:getSelected()
    UI.DrawSectionTitle(self, tr("UI_PNC_UniqueNPCDebug_Details", "DETAILS"),
        self.layout.details.x,
        self.layout.details.y - Layout.Pixels(20, self.uiScale),
        self.layout.details.width,
        selectedItem and selectedItem.label or "")
end

function ISPNCUniqueNPCDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DebugUI.instance == self then DebugUI.instance = nil end
end

function ISPNCUniqueNPCDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    object.filter = "All"
    return object
end

function DebugUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then return nil end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCUniqueNPCDebugWindow, {
            title = tr("UI_PNC_UniqueNPCDebug_Title", ""),
            resizable = true,
            responsiveSpec = {
                width = 1080,
                height = 700,
                minWidth = 720,
                minHeight = 460,
                maxWidth = 1500,
                maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

return DebugUI
