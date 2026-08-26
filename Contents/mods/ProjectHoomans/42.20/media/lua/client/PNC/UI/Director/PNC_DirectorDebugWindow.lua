require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Director/PNC_DirectorDebugModel"

PNC = PNC or {}
PNC.DirectorDebugUI = PNC.DirectorDebugUI or {}

local DirectorUI = PNC.DirectorDebugUI
local Model = PNC.DirectorDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawEntity(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    list:drawText(Layout.Ellipsize(item.label, UIFont.Small,
        list:getWidth() - 14), 7, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.detail or "", UIFont.Small,
        list:getWidth() - 14), 7, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCDirectorDebugWindow = PsychopatzWindow:derive("ISPNCDirectorDebugWindow")

function ISPNCDirectorDebugWindow:initialise() PsychopatzWindow.initialise(self) end

function ISPNCDirectorDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.groups = UI.CreateList(self, { itemHeight = 42, doDrawItem = drawEntity })
    self.locations = UI.CreateList(self, { itemHeight = 42, doDrawItem = drawEntity })
    self.sectors = UI.CreateList(self, { itemHeight = 42, doDrawItem = drawEntity })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = 148,
        valueRightPadding = 7,
    })
    self.controls = {}
    for _, definition in ipairs({
        { "refresh", "REFRESH", "quiet" },
        { "force_update", "FORCE UPDATE", "success" },
        { "force_arrival", "FORCE ARRIVAL", "quiet" },
        { "rebuild_profile", "REBUILD PROFILE", "quiet" },
        { "rebuild_behavior", "REBUILD BEHAVIOR", "quiet" },
        { "force_start_scavenge", "START SCAVENGE", "success" },
        { "force_complete_action", "COMPLETE ACTION", "quiet" },
        { "force_encounter", "EVALUATE ENCOUNTER", "danger" },
        { "toggle_pause", "PAUSE / RESUME", "danger" },
        { "force_population_reconcile", "RECONCILE POPULATION", "success" },
        { "queue_population_group", "QUEUE AUTO GROUP", "success" },
        { "queue_population_settlement", "QUEUE AUTO SETTLEMENT", "success" },
        { "clear_group_cooldown", "CLEAR GROUP COOLDOWN", "quiet" },
        { "clear_settlement_cooldown", "CLEAR SETTLEMENT COOLDOWN", "quiet" },
        { "rebuild_population_index", "REBUILD POP INDEX", "quiet" },
        { "discover_population_sites", "DISCOVER SITES", "quiet" },
        { "retry_starter_population", "RETRY STARTER", "success" },
        { "process_population_queue", "PROCESS POP QUEUE", "success" },
        { "clear_population_log", "CLEAR POP LOG", "quiet" },
        { "toggle_population_pause", "PAUSE POPULATION", "danger" },
    }) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = definition[1], title = definition[2], target = self,
            onclick = ISPNCDirectorDebugWindow.onAction,
            variant = definition[3],
        })
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCDirectorDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local flow = Layout.Flow(self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 85 })
    local top, gap = flow.bottom + 24, 8
    local listWidth = math.max(150, math.floor((rect.width - gap * 3) * 0.17))
    local height = rect.height - (top - rect.y)
    self.layout = {
        groups = { x = rect.x, y = top, width = listWidth, height = height },
        locations = { x = rect.x + listWidth + gap, y = top,
            width = listWidth, height = height },
        sectors = { x = rect.x + listWidth * 2 + gap * 2, y = top,
            width = listWidth, height = height },
        details = { x = rect.x + listWidth * 3 + gap * 3, y = top,
            width = rect.width - listWidth * 3 - gap * 3, height = height },
    }
    for widget, bounds in pairs({ [self.groups] = self.layout.groups,
        [self.locations] = self.layout.locations,
        [self.sectors] = self.layout.sectors,
        [self.details] = self.layout.details }) do
        Layout.SetBounds(widget, bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

function ISPNCDirectorDebugWindow:requestSnapshot()
    local group, location, sector = selected(self.groups), selected(self.locations),
        selected(self.sectors)
    PNC.Client.RequestDirectorDebug(group and group.id, location and location.id,
        sector and sector.id)
    self.lastRequestAt = PNC.Core.Now()
end

local function restore(list, id)
    for index, entry in ipairs(list.items or {}) do
        if entry.item and entry.item.id == id then list.selected = index return end
    end
    if #list.items > 0 then list.selected = 1 end
end

function ISPNCDirectorDebugWindow:refreshSnapshot()
    local snapshot = ClientState.directorDebug or {}
    local oldGroup, oldLocation, oldSector = selected(self.groups),
        selected(self.locations), selected(self.sectors)
    self.groups:clear()
    for _, item in ipairs(Model.GroupItems(snapshot)) do
        self.groups:addItem(item.label, item)
    end
    restore(self.groups, snapshot.selectedGroupId or oldGroup and oldGroup.id)
    self.locations:clear()
    for _, item in ipairs(Model.LocationItems(snapshot)) do
        self.locations:addItem(item.label, item)
    end
    restore(self.locations, snapshot.selectedLocationId
        or oldLocation and oldLocation.id)
    self.sectors:clear()
    for _, item in ipairs(Model.SectorItems(snapshot)) do
        self.sectors:addItem(item.label, item)
    end
    restore(self.sectors, snapshot.population
        and snapshot.population.selectedSectorId
        or oldSector and oldSector.id)
    self.details:clear()
    local group, location, sector = selected(self.groups), selected(self.locations),
        selected(self.sectors)
    for _, item in ipairs(Model.DetailRows(snapshot,
        group and group.value, location and location.value,
        sector and sector.value,
        ClientState.directorDebugAuthorized,
        ClientState.directorDebugReason)) do
        self.details:addItem(item.label, item)
    end
    self.lastReceiveAt = ClientState.lastDirectorDebugReceiveAt or PNC.Core.Now()
end

function ISPNCDirectorDebugWindow:onAction(button)
    if button.internal == "refresh" then self:requestSnapshot() return end
    local group, location, sector = selected(self.groups), selected(self.locations),
        selected(self.sectors)
    PNC.Client.SendDebug("director_debug_action", {
        directorAction = button.internal,
        groupID = group and group.id,
        locationID = location and location.id,
        populationSectorID = sector and sector.id,
    })
end

function ISPNCDirectorDebugWindow:prerender()
    local received = ClientState.lastDirectorDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then self:refreshSnapshot() end
    if PNC.Core.Now() - (self.lastRequestAt or 0) > 3000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCDirectorDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self, "ABSTRACT GROUPS", self.layout.groups.x,
            self.layout.groups.y - 20, self.layout.groups.width)
        UI.DrawSectionTitle(self, "LOCATIONS", self.layout.locations.x,
            self.layout.locations.y - 20, self.layout.locations.width)
        UI.DrawSectionTitle(self, "POPULATION SECTORS", self.layout.sectors.x,
            self.layout.sectors.y - 20, self.layout.sectors.width)
        UI.DrawSectionTitle(self, "DIRECTOR / POPULATION / QUEUES / LOGS",
            self.layout.details.x, self.layout.details.y - 20,
            self.layout.details.width)
    end
end

function ISPNCDirectorDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DirectorUI.instance = nil
end

function ISPNCDirectorDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DirectorUI.Open()
    if not PNC.Client.CanUseDebug() then return nil end
    local window = DirectorUI.instance
    if not window then
        window = UI.NewWindow(ISPNCDirectorDebugWindow, {
            title = "PNC ABSTRACT WORLD DIRECTOR", resizable = true,
            responsiveSpec = { width = 1180, height = 720,
                minWidth = 800, minHeight = 500,
                maxWidth = 1600, maxHeight = 1000 },
        })
        window:initialise()
        window:instantiate()
        DirectorUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function DirectorUI.Toggle()
    if DirectorUI.instance and DirectorUI.instance:getIsVisible() then
        DirectorUI.instance:close()
        return false
    end
    return DirectorUI.Open() ~= nil
end

return DirectorUI
