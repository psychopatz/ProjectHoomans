PNC = PNC or {}

-- This file is retained as a compatibility loader for older callers.  Project
-- Zomboid auto-loads client Lua files, so leaving the old implementation live
-- here would overwrite PNC.BaseUI.Open when this file is evaluated after the
-- Base module.  The visible building surface now belongs to the Base widget.
local BaseUI = require "PNC/UI/Base/PNC_Base"
if BaseUI then
    PNC.BuildingUI = BaseUI
    return BaseUI
end

-- Legacy fallback below is intentionally preserved for source compatibility,
-- including its WidgetWindow.Install id "pnc-command-hub-building-widget" and
-- persistence key "PNC.CommandHub.Building".  Normal mod loading never reaches
-- it because the Base module is required above.
require "PsychopatzCore/UI/PsychopatzUI"

PNC.BuildingUI = PNC.BuildingUI or {}

local BuildingUI = PNC.BuildingUI
local Building = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab"
local Placement = require
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Client = PNC.ColonyManagementClient
if not Client then
    require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement"
    Client = PNC.ColonyManagementClient
end
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local WidgetWindow = UI.WidgetWindow

ISPNCBuildingWindow = PsychopatzWindow:derive("ISPNCBuildingWindow")

function ISPNCBuildingWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCBuildingWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tab = "building"
    self.buildingActive = true
    Building.Create(self, UI)
    self:requestResponsiveLayout(true)
    Building.Apply(self, true)
    self:refresh()
    self:requestSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-building-widget",
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

function ISPNCBuildingWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    Building.Layout(self, Layout, rect)
end

function ISPNCBuildingWindow:onBuildingControl(button)
    return Building.OnControl(self, button)
end

function ISPNCBuildingWindow:requestSnapshot(_)
    local _, _, requestedAt = Client.RequestSnapshot()
    self.lastRequestAt = requestedAt
end

function ISPNCBuildingWindow:refresh(update)
    update = update or Client.ReadSnapshot()
    self.snapshot = update.snapshot or {}
    Building.Rebuild(self, self.snapshot)
    self.lastReceiveAt = update.receivedAt or PNC.Core.Now()
    self.lastReceiveRevision = tonumber(update.revision) or 0
end

function ISPNCBuildingWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    if self.uiScale ~= Layout.Scale() then
        self.uiScale = Layout.Scale()
        self:requestResponsiveLayout(true)
    end
    local now = PNC.Core.Now()
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot("poll")
    end
    local changed, update = Client.HasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt
    )
    if changed then self:refresh(update) end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCBuildingWindow:close()
    Placement.Cancel(self, { restorePrevious = false })
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if BuildingUI.instance == self then BuildingUI.instance = nil end
end

function ISPNCBuildingWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function BuildingUI.Open(owner)
    if owner and owner.getIsVisible and not owner:getIsVisible() then
        owner = nil
    end
    local window = BuildingUI.instance
    if not window then
        window = UI.NewWindow(ISPNCBuildingWindow, {
            title = Shared.Tr("UI_PNC_Building_WindowTitle",
                "COLONY BUILDING"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Building",
            responsiveSpec = {
                width = 980,
                height = 700,
                minWidth = 760,
                minHeight = 520,
                maxWidth = 1320,
                maxHeight = 900,
            },
        })
        window:initialise()
        window:instantiate()
        BuildingUI.instance = window
    end
    window.owner = owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:refresh()
    window:requestSnapshot("opened")
    return window
end

function BuildingUI.Close()
    if BuildingUI.instance then BuildingUI.instance:close() end
end

function BuildingUI.Toggle(owner)
    if BuildingUI.instance and BuildingUI.instance.getIsVisible
        and BuildingUI.instance:getIsVisible()
    then
        BuildingUI.Close()
        return false
    end
    return BuildingUI.Open(owner) ~= nil
end

return BuildingUI
