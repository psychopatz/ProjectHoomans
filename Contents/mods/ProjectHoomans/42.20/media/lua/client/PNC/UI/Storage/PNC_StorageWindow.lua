require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ColonyStorageUI = PNC.ColonyStorageUI or {}

local StorageUI = PNC.ColonyStorageUI
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Options = CoreHub.Options
local WidgetWindow = PsychopatzCore.UI.WidgetWindow
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Client = require "PNC/UI/Storage/PNC_StorageClient"
local Controller = require "PNC/UI/Storage/PNC_StorageController"

ISPNCColonyStorageWindow = PsychopatzWindow:derive(
    "ISPNCColonyStorageWindow")

function ISPNCColonyStorageWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCColonyStorageWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    Controller.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestStorageSnapshot("opened")
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-storage-widget",
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

function ISPNCColonyStorageWindow:onResponsiveLayout()
    Controller.ApplyResponsiveLayout(self)
end

function ISPNCColonyStorageWindow:layoutPane(pane, x, y, width, height)
    Layout.SetBounds(pane, x, y, width, height)
    pane.uiScale = self.uiScale
    pane:layoutContent()
end

function ISPNCColonyStorageWindow:rebuild()
    Controller.Rebuild(self)
end

function ISPNCColonyStorageWindow:refresh(update)
    Controller.Refresh(self, update)
end

function ISPNCColonyStorageWindow:addDetail(label, detail, colorName)
    Controller.AddDetail(self, label, detail, colorName)
end

function ISPNCColonyStorageWindow:toggleInventoryGroup(role, groupKey)
    return Controller.ToggleInventoryGroup(self, role, groupKey)
end

function ISPNCColonyStorageWindow:onStorageControl(button)
    return Controller.OnControl(self, button)
end

function ISPNCColonyStorageWindow:requestStorageSnapshot(source)
    Controller.RequestSnapshot(self)
end

function ISPNCColonyStorageWindow:prerender()
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
        self:requestStorageSnapshot("poll")
    end
    local changed, update = Client.HasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt)
    if changed then self:refresh(update) end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCColonyStorageWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    local summary = self.layout.summary
    UI.DrawSurface(self, summary.x, summary.y, summary.width,
        summary.height, true, self.contentOpacity)
    self:drawText(string.upper(Shared.Text(colony.name, "COLONY STORAGE")),
        summary.x + 14, summary.y + 10,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        Theme.Font(self.uiScale, "title"))
    UI.DrawSectionTitle(self,
        Shared.Tr("UI_PNC_Storage_GeneralStockpile", "GENERAL STOCKPILE"),
        self.storageList:getX(), self.storageList:getY() - 21,
        self.storageList:getWidth())
    local Presentation = require "PNC/UI/Storage/PNC_StoragePresentation"
    Presentation.DrawSummary(self, Theme)
end

function ISPNCColonyStorageWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if StorageUI.instance == self then StorageUI.instance = nil end
end

function ISPNCColonyStorageWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function StorageUI.CanOpen(snapshot)
    return Client.HasAccess(snapshot)
end

function StorageUI.Open(owner)
    local snapshot = Client.ReadSnapshot().snapshot
    if not StorageUI.CanOpen(snapshot) then
        Client.RequestSnapshot()
        return nil, "outside_base"
    end
    -- Context-menu callers may discover the hub instance even while the hub
    -- itself is hidden. A hidden owner would immediately close a storage
    -- window on its first prerender, so only retain live owners.
    if owner and owner.getIsVisible and not owner:getIsVisible() then
        owner = nil
    end
    local window = StorageUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonyStorageWindow, {
            title = Shared.Tr("UI_PNC_Storage_WindowTitle", "COLONY STORAGE"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Storage",
            responsiveSpec = {
                width = 980, height = 700,
                minWidth = 760, minHeight = 520,
                maxWidth = 1320, maxHeight = 900,
            },
        })
        window:initialise()
        window:instantiate()
        StorageUI.instance = window
    end
    window.owner = owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:refresh()
    window:requestStorageSnapshot("opened")
    return window
end

function StorageUI.Close()
    if StorageUI.instance then StorageUI.instance:close() end
end

function StorageUI.Toggle(owner)
    if StorageUI.instance and StorageUI.instance.getIsVisible
        and StorageUI.instance:getIsVisible()
    then
        StorageUI.Close()
        return false
    end
    return StorageUI.Open(owner) ~= nil
end

return StorageUI
