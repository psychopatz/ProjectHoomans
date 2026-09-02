require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ResearchUI = PNC.ResearchUI or {}

local ResearchUI = PNC.ResearchUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local WidgetWindow = UI.WidgetWindow
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Controller = require "PNC/UI/Research/PNC_ResearchController"
local Presentation = require "PNC/UI/Research/PNC_ResearchPresentation"

ISPNCResearchWindow = PsychopatzWindow:derive("ISPNCResearchWindow")

function ISPNCResearchWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCResearchWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    Controller.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestResearchSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-research-widget",
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

function ISPNCResearchWindow:onResponsiveLayout()
    Controller.ApplyResponsiveLayout(self)
end

function ISPNCResearchWindow:refresh(update)
    Controller.Refresh(self, update)
end

function ISPNCResearchWindow:requestResearchSnapshot(source)
    Controller.RequestSnapshot(self)
end

function ISPNCResearchWindow:onResearchControl(button)
    return Controller.OnControl(self, button)
end

function ISPNCResearchWindow:rebuild()
    Controller.Rebuild(self)
end

function ISPNCResearchWindow:prerender()
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
    Controller.ApplyContentStyle(self)
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestResearchSnapshot("poll")
    end
    local changed, update = PNC.ColonyManagementClient.HasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt)
    if changed then self:refresh(update) end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCResearchWindow:render()
    PsychopatzWindow.render(self)
    Presentation.DrawSummary(self, self.researchView)
end

function ISPNCResearchWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if ResearchUI.instance == self then ResearchUI.instance = nil end
end

function ISPNCResearchWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function ResearchUI.Open(owner)
    if owner and owner.getIsVisible and not owner:getIsVisible() then
        owner = nil
    end
    local window = ResearchUI.instance
    if not window then
        window = UI.NewWindow(ISPNCResearchWindow, {
            title = Shared.Tr("UI_PNC_Research_WindowTitle", "COLONY RESEARCH"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Research",
            responsiveSpec = {
                width = 980, height = 700,
                minWidth = 760, minHeight = 500,
                maxWidth = 1400, maxHeight = 920,
            },
        })
        window:initialise()
        window:instantiate()
        ResearchUI.instance = window
    end
    window.owner = owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:refresh()
    window:requestResearchSnapshot("opened")
    return window
end

function ResearchUI.Close()
    if ResearchUI.instance then ResearchUI.instance:close() end
end

function ResearchUI.Toggle(owner)
    if ResearchUI.instance and ResearchUI.instance.getIsVisible
        and ResearchUI.instance:getIsVisible()
    then
        ResearchUI.Close()
        return false
    end
    return ResearchUI.Open(owner) ~= nil
end

return ResearchUI
