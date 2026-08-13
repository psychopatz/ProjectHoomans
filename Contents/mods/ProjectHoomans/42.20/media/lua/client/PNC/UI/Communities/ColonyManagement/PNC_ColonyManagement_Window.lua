require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Controller = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Controller"
local Diagnostics = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Diagnostics"
local LayoutModel = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Layout"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Registry = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local ColonyUI = PNC.ColonyManagementUI
local Client = PNC.ColonyManagementClient
local UI = PsychopatzCore.UI
local Theme = UI.Theme

ISPNCColonyManagementWindow = PsychopatzWindow:derive(
    "ISPNCColonyManagementWindow"
)

function ISPNCColonyManagementWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCColonyManagementWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    Controller.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestSnapshot()
end

function ISPNCColonyManagementWindow:onResponsiveLayout()
    Controller.ApplyResponsiveLayout(self)
end

function ISPNCColonyManagementWindow:layoutPane(
    pane, x, y, width, height
)
    LayoutModel.SetPane(self, pane, {
        x = x, y = y, width = width, height = height,
    })
end

function ISPNCColonyManagementWindow:applyTabLayout()
    Controller.ApplyTabLayout(self)
end

function ISPNCColonyManagementWindow:updateTabStyles()
    Controller.UpdateTabStyles(self)
end

function ISPNCColonyManagementWindow:onTab(button)
    Controller.SelectTab(self, button)
end

function ISPNCColonyManagementWindow:onStorageControl(button)
    local definition = Registry.Get("storage")
    if definition and definition.onControl then
        return definition.onControl(self, button)
    end
    local Storage = require "PNC/UI/Communities/PNC_ColonyManagementStorageTabs"
    return Storage.OnControl(self, button, Shared.Tr)
end

function ISPNCColonyManagementWindow:onResearchUpgrade(button)
    local Research = require "PNC/UI/Communities/PNC_ColonyManagementResearchTab"
    return Research.OnUpgrade(self, button)
end

function ISPNCColonyManagementWindow:onResearchControl(button)
    local Research = require "PNC/UI/Communities/PNC_ColonyManagementResearchTab"
    return Research.OnControl(self, button)
end

function ISPNCColonyManagementWindow:onWorkshopControl(button)
    local Workshop = require "PNC/UI/Communities/PNC_ColonyManagementWorkshopTab"
    return Workshop.OnControl(self, button)
end

function ISPNCColonyManagementWindow:onBaseControl(button)
    local definition = Registry.Get("base")
    if definition and definition.onControl then
        return definition.onControl(self, button)
    end
    return false
end

function ISPNCColonyManagementWindow:onColonySettingsControl(button)
    local definition = Registry.Get("settings")
    if definition and definition.onControl then
        return definition.onControl(self, button)
    end
    return false
end

function ISPNCColonyManagementWindow:onJobsControl(button)
    local definition = Registry.Get("jobs")
    return definition and definition.onControl
        and definition.onControl(self, button) or false
end

function ISPNCColonyManagementWindow:onDebugControl(button)
    local definition = Registry.Get("debug")
    if definition and definition.onControl then
        return definition.onControl(self, button)
    end
    return false
end

function ISPNCColonyManagementWindow:requestSnapshot(source)
    local _, _, requestedAt = Client.RequestSnapshot()
    self.lastRequestAt = requestedAt
    Diagnostics.Log(self, "snapshot_requested", {
        source = source or "automatic",
        tab = self.tab,
        selected = self.selectedPersonID or "none",
    })
end

function ISPNCColonyManagementWindow:manualRefresh()
    local previousRevision = Client.ReadSnapshot().revision
    self:requestSnapshot("manual")
    local update = Client.ReadSnapshot()
    if update.revision > previousRevision then
        self:refresh(update)
    end
end

function ISPNCColonyManagementWindow:addDetail(label, detail, colorName)
    Components.AddRow(
        self.details, Presentation.Detail(label, detail, colorName)
    )
end

function ISPNCColonyManagementWindow:rebuildDetails()
    Controller.RebuildDetails(self)
end

function ISPNCColonyManagementWindow:toggleInventoryGroup(role, groupKey)
    if role ~= "storage" or not groupKey then return end
    self.storageCollapsedGroups = self.storageCollapsedGroups or {}
    self.storageCollapsedGroups[groupKey] =
        self.storageCollapsedGroups[groupKey] ~= true
    self:rebuildDetails()
end

function ISPNCColonyManagementWindow:onPersonSelected()
    Controller.OnPersonSelected(self)
end

function ISPNCColonyManagementWindow:refresh(update)
    Controller.Refresh(self, update)
end

function ISPNCColonyManagementWindow:prerender()
    local currentTime = PNC.Core.Now()
    if (self.tab == "tasks" or self.tab == "base")
        and currentTime - (tonumber(self.lastWorkPollAt) or 0) >= 2000
    then
        self.lastWorkPollAt = currentTime
        self:requestSnapshot("work_progress_poll")
    end
    local changed, update = Client.HasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt
    )
    if changed then
        self:refresh(update)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCColonyManagementWindow:drawSectionTitle(title, target)
    UI.DrawSectionTitle(self, title, target:getX(), target:getY() - 21,
        target:getWidth())
end

function ISPNCColonyManagementWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    local summary = self.layout.summary
    UI.DrawSurface(self, summary.x, summary.y, summary.width,
        summary.height, true)
    self:drawText(
        string.upper(Shared.Text(colony.name, "New Colony")),
        summary.x + 14, summary.y + 10,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        Theme.Font(self.uiScale, "title")
    )
    self:drawText(
        tostring(#(snapshot.people or {})) .. " companions  |  "
            .. tostring(#(snapshot.attention or {})) .. " need attention",
        summary.x + 14, summary.y + summary.height - 23,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small
    )
    local definition = Registry.Get(self.tab)
    if definition and definition.render then definition.render(self, Theme) end
end

function ISPNCColonyManagementWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ColonyUI.instance = nil
end

function ISPNCColonyManagementWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function ColonyUI.Open()
    local window = ColonyUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonyManagementWindow, {
            title = string.upper(Shared.Tr(
                "UI_PNC_ColonyManagement", "Colony Management")),
            resizable = true,
            persistenceKey = "PNC.ColonyManagement",
            responsiveSpec = {
                width = 980,
                height = 640,
                minWidth = 700,
                minHeight = 500,
                maxWidth = 1320,
                maxHeight = 860,
            },
        })
        window:initialise()
        window:instantiate()
        ColonyUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function ColonyUI.Toggle()
    if ColonyUI.instance and ColonyUI.instance:getIsVisible() then
        ColonyUI.instance:close()
        return false
    end
    return ColonyUI.Open() ~= nil
end

return ColonyUI
