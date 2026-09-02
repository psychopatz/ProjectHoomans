require "PsychopatzCore/UI/PsychopatzUI"

local Controller = require "PNC/UI/Colonist/PNC_ColonistController"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local WidgetWindow = PsychopatzCore.UI.WidgetWindow
local Client = PNC.ColonyManagementClient
local UI = PsychopatzCore.UI
local Layout = UI.Layout

PNC = PNC or {}
PNC.ColonistUI = PNC.ColonistUI or {}
local ColonistUI = PNC.ColonistUI

ISPNCColonistWindow = PsychopatzWindow:derive("ISPNCColonistWindow")

function ISPNCColonistWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCColonistWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    Controller.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-colonist-widget",
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

function ISPNCColonistWindow:onResponsiveLayout()
    Controller.ApplyResponsiveLayout(self)
end

function ISPNCColonistWindow:onTab(button)
    return Controller.SelectTab(self, button)
end

function ISPNCColonistWindow:onPersonSelected()
    Controller.OnPersonSelected(self)
end

function ISPNCColonistWindow:onColonistControl(button)
    return Controller.OnControl(self, button)
end

function ISPNCColonistWindow:requestSnapshot(source)
    local _, _, requestedAt = Client.RequestSnapshot()
    self.lastRequestAt = requestedAt
end

function ISPNCColonistWindow:refresh(update)
    Controller.Refresh(self, update)
end

function ISPNCColonistWindow:prerender()
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
    if self.tabRegistryRevision ~= PNC.ColonistUI.TabRegistry.Revision then
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

function ISPNCColonistWindow:render()
    PsychopatzWindow.render(self)
end

function ISPNCColonistWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if ColonistUI.instance == self then ColonistUI.instance = nil end
end

function ISPNCColonistWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function ColonistUI.Open(owner)
    local window = ColonistUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonistWindow, {
            title = string.upper(Shared.Tr(
                "UI_PNC_Colonist_Title", "COLONISTS")),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Colonist",
            responsiveSpec = {
                width = 920,
                height = 620,
                minWidth = 760,
                minHeight = 480,
                maxWidth = 1320,
                maxHeight = 900,
            },
        })
        window:initialise()
        window:instantiate()
        ColonistUI.instance = window
    end
    window.owner = owner or window.owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:requestSnapshot("opened")
    return window
end

function ColonistUI.Close()
    if ColonistUI.instance then ColonistUI.instance:close() end
end

function ColonistUI.Toggle(owner)
    if ColonistUI.instance and ColonistUI.instance.getIsVisible
        and ColonistUI.instance:getIsVisible()
    then
        ColonistUI.Close()
        return false
    end
    return ColonistUI.Open(owner) ~= nil
end

return ColonistUI
