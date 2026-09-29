require "PsychopatzCore/UI/PsychopatzUI"

local Controller = require "PNC/UI/Colonist/PNC_ColonistController"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
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
    local selected = Controller.SelectTab(self, button)
    if selected and self.tab == "task" then
        self:requestSnapshot("task_tab")
    end
    return selected
end

function ISPNCColonistWindow:onPersonSelected()
    Controller.OnPersonSelected(self)
    -- Selection drives the on-demand per-colonist detail, so it always
    -- refreshes rather than only on the task tab.
    self:requestSnapshot("person_selected")
end

function ISPNCColonistWindow:onColonistControl(button)
    return Controller.OnControl(self, button)
end

--[[
    The roster and its default tabs read the header, the colonist projections,
    and the settlement facilities. The DEBUG tab additionally reads the
    provision/storage diagnostics, so the stockpile projection is requested
    only while that tab is open instead of on every poll.
]]
local ROSTER_SECTIONS = { "header", "roster", "settlement" }
local DEBUG_SECTIONS = { "header", "roster", "settlement", "storage" }

function ISPNCColonistWindow:colonistSections()
    if self.tab == "debug" then return DEBUG_SECTIONS end
    return ROSTER_SECTIONS
end

function ISPNCColonistWindow:requestSnapshot(source)
    local taskBrainNpcID = self.tab == "task"
        and self.selectedPersonID or nil
    -- The selected colonist's journal travels on demand; other colonists omit
    -- it, which keeps the roster inside one packet for large colonies.
    local _, _, requestedAt = Client.RequestSnapshot(taskBrainNpcID,
        self:colonistSections(), self.selectedPersonID)
    self.lastRequestAt = requestedAt
end

function ISPNCColonistWindow:refresh(update)
    local previousSelection = self.selectedPersonID
    Controller.Refresh(self, update)
    -- The roster may establish the initial selection on this refresh, which the
    -- request that produced it could not know about. Ask once for that
    -- colonist's detail; the selection is unchanged by the reply, so this does
    -- not loop.
    if self.selectedPersonID ~= previousSelection then
        self:requestSnapshot("selection_changed")
    end
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
    local tabsChanged = Controller.SyncTabs(self)
    if tabsChanged then
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

function ColonistUI.OpenDebug(owner)
    local client = PNC and PNC.Client
    if not client or type(client.CanUseDebug) ~= "function"
        or client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = ColonistUI.Open(owner)
    local button = window and window.tabButtons
        and window.tabButtons.debug or nil
    if button and window.onTab then window:onTab(button) end
    return window
end

return ColonistUI
