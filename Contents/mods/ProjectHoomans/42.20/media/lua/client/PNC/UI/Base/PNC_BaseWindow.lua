require "PsychopatzCore/UI/PsychopatzUI"

local BaseTab = require
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Tab"
local BuildingTab = require "PNC/UI/Base/PNC_BaseBuildingTab"
local Queue = require "PNC/UI/Base/PNC_BaseQueue"
local SummaryPanel = require "PNC/UI/Base/PNC_BaseSummary"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"

PNC = PNC or {}
PNC.BaseUI = PNC.BaseUI or {}

local BaseUI = PNC.BaseUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local WidgetWindow = UI.WidgetWindow
local Client = PNC.ColonyManagementClient
if not Client then
    require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement"
    Client = PNC.ColonyManagementClient
end

local function trace(event, message)
    local hub = UI.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

ISPNCBaseWindow = PsychopatzWindow:derive("ISPNCBaseWindow")

function ISPNCBaseWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCBaseWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tab = "base"
    self.baseIntegrated = true
    self.baseControlHandler = ISPNCBaseWindow.onBaseControl
    self.onBaseBuildingControl = ISPNCBaseWindow.onBuildingControl
    -- The legacy vanilla-style recipe browser is embedded into the
    -- BUILDINGS tab and still creates its controls against this callback.
    self.onBuildingControl = ISPNCBaseWindow.onBuildingControl
    self.baseTabButtons = {}
    local tabs = {
        { "base", tr("UI_PNC_Base_Tab", "BASE") },
        { "facilities", tr("UI_PNC_Facilities_Tab", "FACILITIES") },
        { "buildings", tr("UI_PNC_Buildings_Tab", "BUILDINGS") },
    }
    for _, definition in ipairs(tabs) do
        local button = UI.CreateButton(self, {
            id = definition[1], title = definition[2], target = self,
            onclick = ISPNCBaseWindow.onTab,
            variant = definition[1] == self.tab and "selected" or "quiet",
        })
        self.baseTabButtons[definition[1]] = button
    end
    self.baseSummary = SummaryPanel:new(0, 0, 1, 1, self)
    self.baseSummary:initialise()
    self.baseSummary:instantiate()
    self.baseSummary.owner = self
    self:addChild(self.baseSummary)
    BaseTab.Create(self)
    Queue.Create(self)
    BuildingTab.Create(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-base-widget",
            onDetachedChanged = function()
                local controller = PNC.CommandHub
                    and PNC.CommandHub.ChildController
                if controller and controller.SyncPositions then
                    controller.SyncPositions()
                end
            end,
        })
    end
end

function ISPNCBaseWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local gap = Layout.Pixels(8, self.uiScale)
    local tabHeight = Layout.Pixels(30, self.uiScale)
    local tabOrder = { "base", "facilities", "buildings" }
    local tabWidth = math.floor((rect.width - gap * 2)
        / #tabOrder)
    local index = 0
    for _, id in ipairs(tabOrder) do
        index = index + 1
        Layout.SetBounds(self.baseTabButtons[id], rect.x + (index - 1)
            * (tabWidth + gap), rect.y, tabWidth, tabHeight)
    end
    local body = {
        x = rect.x, y = rect.y + tabHeight + gap,
        width = rect.width,
        height = math.max(1, rect.height - tabHeight - gap),
    }
    local baseActive = self.tab == "base"
    self.baseSummary:setVisible(baseActive)
    if baseActive then
        local summaryHeight = Layout.Pixels(68, self.uiScale)
        Layout.SetBounds(self.baseSummary, body.x, body.y,
            body.width, summaryHeight)
        body.y = body.y + summaryHeight + gap
        body.height = math.max(1, body.height - summaryHeight - gap)
        local queueHeight = math.max(Layout.Pixels(100, self.uiScale),
            math.min(Layout.Pixels(170, self.uiScale),
                math.floor(body.height * 0.27)))
        local browserBottom = body.y + body.height - queueHeight - gap
        BaseTab.Layout(self, Layout, {
            x = body.x, y = body.y, width = body.width,
            height = math.max(1, browserBottom - body.y),
        })
        Queue.Layout(self, body, browserBottom + gap,
            body.y + body.height)
    else
        BaseTab.Layout(self, Layout, {
            x = body.x, y = body.y, width = body.width, height = 1,
        })
        Queue.Layout(self, body, body.y, body.y)
    end
    BuildingTab.Layout(self, body)
end

function ISPNCBaseWindow:layoutPane(pane, x, y, width, height)
    Layout.SetBounds(pane, x, y, width, height)
    if pane and pane.layoutContent then pane:layoutContent() end
end

function ISPNCBaseWindow:onTab(button)
    local tab = button and button.internal or nil
    if tab ~= "base" and tab ~= "facilities" and tab ~= "buildings" then
        return false
    end
    self.tab = tab
    for id, candidate in pairs(self.baseTabButtons or {}) do
        UI.SetButtonVariant(candidate, id == tab and "selected" or "quiet")
    end
    BaseTab.Apply(self, tab == "base")
    Queue.Apply(self, tab == "base")
    BuildingTab.Apply(self, tab == "facilities" or tab == "buildings")
    self:requestResponsiveLayout(true)
    self:requestSnapshot(tab .. "_opened")
    return true
end

function ISPNCBaseWindow:onBaseControl(button)
    return BaseTab.OnControl(self, button)
end

function ISPNCBaseWindow:setBaseStatus(value)
    self.baseTerritoryStatus = tostring(value or "")
    if self.invalidateLayout then self:invalidateLayout("base_status") end
end

function ISPNCBaseWindow:onBuildingControl(button)
    return BuildingTab.OnControl(self, button)
end

function ISPNCBaseWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/Base/PNC_BaseWindowLifecycle"

function BaseUI.Open(owner)
    trace("pnc_base_open_start", "existing="
        .. tostring(BaseUI.instance ~= nil) .. " has_owner="
        .. tostring(owner ~= nil))
    if owner and owner.getIsVisible and not owner:getIsVisible() then owner = nil end
    local window = BaseUI.instance
    if not window then
        window = UI.NewWindow(ISPNCBaseWindow, {
            title = tr("UI_PNC_Base_WindowTitle", "BASE"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Base",
            responsiveSpec = {
                width = 1180, height = 780,
                minWidth = 820, minHeight = 600,
                maxWidth = 1440, maxHeight = 940,
            },
        })
        window:initialise()
        window:instantiate()
        BaseUI.instance = window
    end
    window.owner = owner or window.owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:refresh()
    window:requestSnapshot("opened")
    trace("pnc_base_open_result", "visible="
        .. tostring(window.getIsVisible and window:getIsVisible() == true)
        .. " tab=" .. tostring(window.tab))
    return window
end

function BaseUI.Close()
    if BaseUI.instance then BaseUI.instance:close() end
end

function BaseUI.Toggle(owner)
    if BaseUI.instance and BaseUI.instance.getIsVisible
        and BaseUI.instance:getIsVisible()
    then
        BaseUI.Close()
        return false
    end
    return BaseUI.Open(owner) ~= nil
end

return BaseUI
