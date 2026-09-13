require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.WorkshopUI = PNC.WorkshopUI or {}

local WorkshopUI = PNC.WorkshopUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local WidgetWindow = UI.WidgetWindow
local Shared = require
    "PNC/UI/Shared/PNC_ColonyUIShared"
local Controller = require "PNC/UI/Workshop/PNC_WorkshopController"

ISPNCWorkshopWindow = PsychopatzWindow:derive("ISPNCWorkshopWindow")

function ISPNCWorkshopWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCWorkshopWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    Controller.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestWorkshopSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-workshop-widget",
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

function ISPNCWorkshopWindow:onResponsiveLayout()
    Controller.ApplyResponsiveLayout(self)
end

function ISPNCWorkshopWindow:onWorkshopControl(button)
    return Controller.OnControl(self, button)
end

function ISPNCWorkshopWindow:rebuildDetails()
    return Controller.Rebuild(self)
end

function ISPNCWorkshopWindow:refresh(update)
    return Controller.Refresh(self, update)
end

function ISPNCWorkshopWindow:requestWorkshopSnapshot(source)
    Controller.RequestSnapshot(self)
end

function ISPNCWorkshopWindow:prerender()
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
    local current = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if current - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestWorkshopSnapshot("poll")
    end
    local changed, update = PNC.ColonyManagementClient.HasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt)
    if changed then self:refresh(update) end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCWorkshopWindow:render()
    PsychopatzWindow.render(self)
end

function ISPNCWorkshopWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if WorkshopUI.instance == self then WorkshopUI.instance = nil end
end

function ISPNCWorkshopWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WorkshopUI.Open(owner)
    if owner and owner.getIsVisible and not owner:getIsVisible() then
        owner = nil
    end
    local window = WorkshopUI.instance
    if not window then
        window = UI.NewWindow(ISPNCWorkshopWindow, {
            title = Shared.Tr("UI_PNC_Workshop_WindowTitle", "COLONY WORKSHOP"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Workshop",
            responsiveSpec = {
                width = 1080, height = 700,
                minWidth = 820, minHeight = 520,
                maxWidth = 1440, maxHeight = 920,
            },
        })
        window:initialise()
        window:instantiate()
        WorkshopUI.instance = window
    end
    window.owner = owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:refresh()
    window:requestWorkshopSnapshot("opened")
    return window
end

function WorkshopUI.Close()
    if WorkshopUI.instance then WorkshopUI.instance:close() end
end

function WorkshopUI.Toggle(owner)
    if WorkshopUI.instance and WorkshopUI.instance.getIsVisible
        and WorkshopUI.instance:getIsVisible()
    then
        WorkshopUI.Close()
        return false
    end
    return WorkshopUI.Open(owner) ~= nil
end

return WorkshopUI
