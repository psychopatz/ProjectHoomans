require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ColonyStorageUI = PNC.ColonyStorageUI or {}

local StorageUI = PNC.ColonyStorageUI
local StorageTabs = require "PNC/UI/Communities/PNC_ColonyManagementStorageTabs"
local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function currentSnapshot()
    return clientState().colonyManagement or {}
end

local function accessAllowed(snapshot)
    local access = snapshot and snapshot.storage and snapshot.storage.access
    return access and access.hasStockpile == true or false
end

ISPNCColonyStorageWindow = PsychopatzWindow:derive(
    "ISPNCColonyStorageWindow")

function ISPNCColonyStorageWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCColonyStorageWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tab = "storage"
    self.storageSort = "name"
    self.storageCollapsedGroups = {}
    self.detailsPane, self.details = Components.CreateDetailPane(self)
    self.detailsPane:setHeader(
        Shared.Tr("UI_PNC_Storage_DebugTools", "DEBUG TOOLS"), "")
    self.detailsPane:setVisible(false)
    StorageTabs.Create(self, UI, Shared.Tr)
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCColonyStorageWindow:layoutPane(pane, x, y, width, height)
    Layout.SetBounds(pane, x, y, width, height)
    pane.uiScale = self.uiScale
    pane:layoutContent()
end

function ISPNCColonyStorageWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 12, bottom = 12 })
    local summaryHeight = Layout.Pixels(64, self.uiScale)
    local contentY = rect.y + summaryHeight + Layout.Pixels(10, self.uiScale)
    self.layout = {
        summary = { x = rect.x, y = rect.y,
            width = rect.width, height = summaryHeight },
        content = { x = rect.x, y = contentY, width = rect.width,
            height = math.max(100, rect.y + rect.height - contentY) },
    }
    StorageTabs.Layout(self, Layout, self.layout.content)
    StorageTabs.ApplyLayout(self, Layout, true)
end

function ISPNCColonyStorageWindow:applyTabLayout()
    self:onResponsiveLayout()
end

function ISPNCColonyStorageWindow:addDetail(label, detail, colorName)
    Components.AddRow(self.details,
        Presentation.Detail(label, detail, colorName))
end

function ISPNCColonyStorageWindow:drawSectionTitle(title, target)
    UI.DrawSectionTitle(self, title, target:getX(), target:getY() - 21,
        target:getWidth())
end

function ISPNCColonyStorageWindow:toggleInventoryGroup(role, groupKey)
    if role ~= "storage" or not groupKey then return false end
    self.storageCollapsedGroups[groupKey] =
        self.storageCollapsedGroups[groupKey] ~= true
    self:rebuildDetails()
    return true
end

function ISPNCColonyStorageWindow:rebuildDetails()
    Components.SetRows(self.storageList, {})
    Components.SetRows(self.details, {})
    StorageTabs.Rebuild(self, self.snapshot or {}, Shared.Tr)
    StorageTabs.ApplyLayout(self, Layout, true)
end

function ISPNCColonyStorageWindow:onStorageControl(button)
    return StorageTabs.OnControl(self, button, Shared.Tr)
end

function ISPNCColonyStorageWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0
end

function ISPNCColonyStorageWindow:refreshSnapshot()
    self.snapshot = currentSnapshot()
    self.lastRevision = tonumber(clientState().colonyManagementRevision) or 0
    self:rebuildDetails()
end

function ISPNCColonyStorageWindow:prerender()
    local state = clientState()
    local revision = tonumber(state.colonyManagementRevision) or 0
    if revision ~= (tonumber(self.lastRevision) or -1) then
        self:refreshSnapshot()
    end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCColonyStorageWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    local summary = self.layout.summary
    UI.DrawSurface(self, summary.x, summary.y, summary.width,
        summary.height, true)
    self:drawText(string.upper(Shared.Text(colony.name, "COLONY STORAGE")),
        summary.x + 14, summary.y + 10,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        Theme.Font(self.uiScale, "title"))
    self:drawSectionTitle(
        Shared.Tr("UI_PNC_Storage_GeneralStockpile", "GENERAL STOCKPILE"),
        self.storageList)
    StorageTabs.RenderSummary(self, Theme)
end

function ISPNCColonyStorageWindow:close()
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

function StorageUI.CanOpen()
    return accessAllowed(currentSnapshot())
end

function StorageUI.Open()
    if not StorageUI.CanOpen() then
        if PNC.Client and PNC.Client.RequestColonyManagement then
            PNC.Client.RequestColonyManagement()
        end
        return nil, "outside_base"
    end
    local window = StorageUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonyStorageWindow, {
            title = Shared.Tr("UI_PNC_Storage_WindowTitle", "COLONY STORAGE"),
            resizable = true,
            persistenceKey = "PNC.ColonyStorage",
            responsiveSpec = {
                width = 980, height = 700,
                minWidth = 700, minHeight = 500,
                maxWidth = 1320, maxHeight = 900,
            },
        })
        window:initialise()
        window:instantiate()
        StorageUI.instance = window
    end
    window.snapshot = currentSnapshot()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshSnapshot()
    window:requestSnapshot()
    return window
end

return StorageUI
