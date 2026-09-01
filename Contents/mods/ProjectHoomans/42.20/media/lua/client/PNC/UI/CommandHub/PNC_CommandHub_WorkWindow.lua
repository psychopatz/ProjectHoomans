require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.WorkUI = PNC.CommandHub.WorkUI or {}

local WorkUI = PNC.CommandHub.WorkUI
local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry"
local Presentation = require "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow_Presentation"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local WidgetWindow = UI.WidgetWindow

ISPNCCommandHubWorkWindow = PsychopatzWindow:derive(
    "ISPNCCommandHubWorkWindow"
)

function ISPNCCommandHubWorkWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCCommandHubWorkWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.people = {}
    self.selectedPersonID = nil
    self.lastRevision = -1
    self.lastRequestAt = 0
    self.jobCheckboxes = {}
    self.workRegistry = Registry
    self.peoplePanel = UI.CreatePanel(self)
    self.authorizationPanel = UI.CreatePanel(self)
    self.peopleList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(66, self.uiScale),
        doDrawItem = Presentation.DrawPersonRow,
    })
    self.peopleList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        self:onPersonSelected()
    end
    for _, definition in ipairs(Registry.All()) do
        local checkbox = UI.CreateCheckbox(self, {
            id = "work:" .. definition.id,
            label = Presentation.TitleFor(definition),
            target = self,
            value = true,
            font = UIFont.Small,
            onChange = function(_, value)
                return self:onPermissionChanged(definition.id, value)
            end,
        })
        checkbox.workID = definition.id
        self.jobCheckboxes[definition.id] = checkbox
    end
    self:applyContentStyle()
    self:requestResponsiveLayout(true)
    self:refreshSnapshot()
    self:requestSnapshot()
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-work-widget",
            onDetachedChanged = function()
                local controller = PNC.CommandHub.ChildController
                if controller and controller.SyncPositions then
                    controller.SyncPositions()
                end
            end,
        })
    end
end

function ISPNCCommandHubWorkWindow:applyContentStyle()
    local opacity = Options.GetContentOpacity()
    if self.lastContentOpacity == opacity then return end
    Options.ApplySurfaceOpacity(self.peoplePanel)
    Options.ApplySurfaceOpacity(self.authorizationPanel)
    Options.ApplySurfaceOpacity(self.peopleList, 0.04)
    self.lastContentOpacity = opacity
end

function ISPNCCommandHubWorkWindow:selectedPerson()
    for _, person in ipairs(self.people or {}) do
        if tostring(person.id or "") == tostring(self.selectedPersonID or "")
        then return person end
    end
    return nil
end

function ISPNCCommandHubWorkWindow:onPersonSelected()
    local entry = self.peopleList and self.peopleList:getItem() or nil
    local person = entry and entry.item or nil
    if person then self.selectedPersonID = person.id end
    self:updatePermissionControls()
end

function ISPNCCommandHubWorkWindow:refreshPeople()
    self.peopleList:clear()
    for _, person in ipairs(self.people or {}) do
        self.peopleList:addItem(tostring(person.id or ""), person)
    end
    local selectedIndex = 0
    for index, entry in ipairs(self.peopleList.items or {}) do
        if entry.item and tostring(entry.item.id or "")
            == tostring(self.selectedPersonID or "")
        then
            selectedIndex = index
            break
        end
    end
    if selectedIndex == 0 and #self.peopleList.items > 0 then
        selectedIndex = 1
        self.selectedPersonID = self.peopleList.items[1].item.id
    end
    self.peopleList.selected = selectedIndex
    self:updatePermissionControls()
end

function ISPNCCommandHubWorkWindow:updatePermissionControls()
    local person = self:selectedPerson()
    for _, definition in ipairs(Registry.All()) do
        local checkbox = self.jobCheckboxes[definition.id]
        if checkbox then
            checkbox:setVisible(person ~= nil)
        checkbox:setChecked(person
            and Presentation.IsAllowed(person, definition.id) or false)
        end
    end
end

function ISPNCCommandHubWorkWindow:onPermissionChanged(job, enabled)
    local person = self:selectedPerson()
    if not person or not PNC.Client
        or not PNC.Client.RequestColonyAction
    then return false end
    person.allowedJobs = person.allowedJobs or {}
    local previous = Presentation.IsAllowed(person, job)
    person.allowedJobs[job] = enabled == true
    local ok = PNC.Client.RequestColonyAction("job_permission_set", {
        npcID = person.id, job = job, enabled = enabled == true,
    })
    if ok == false then
        if enabled == true then person.allowedJobs[job] = false
        elseif previous then person.allowedJobs[job] = nil
        else person.allowedJobs[job] = false end
        self:updatePermissionControls()
        return false
    end
    self:refreshPeople()
    return true
end

function ISPNCCommandHubWorkWindow:refreshSnapshot()
    local update = Presentation.ReadSnapshot()
    local value = update.snapshot or {}
    self.people = value.people or {}
    local present = {}
    for _, person in ipairs(self.people) do
        present[tostring(person.id or "")] = true
    end
    if not present[tostring(self.selectedPersonID or "")] then
        self.selectedPersonID = self.people[1] and self.people[1].id or nil
    end
    self:refreshPeople()
    self.lastRevision = tonumber(update.revision) or 0
end

function ISPNCCommandHubWorkWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function ISPNCCommandHubWorkWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    local currentScale = Layout.Scale()
    if self.uiScale ~= currentScale then
        self.uiScale = currentScale
        self:requestResponsiveLayout(true)
    end
    self:applyContentStyle()
    local current = Presentation.ClientState()
    local revision = tonumber(current.colonyManagementRevision) or 0
    if revision ~= (tonumber(self.lastRevision) or -1) then
        self:refreshSnapshot()
    end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end


function ISPNCCommandHubWorkWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
end

function ISPNCCommandHubWorkWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow_Layout"

function WorkUI.Open(owner)
    local window = WorkUI.instance
    if not window then
        window = UI.NewWindow(ISPNCCommandHubWorkWindow, {
            title = Presentation.Translate("UI_PNC_Work_Title", "WORK"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Work",
            responsiveSpec = {
                width = 760, height = 560,
                minWidth = 620, minHeight = 440,
                maxWidth = 1120, maxHeight = 820,
            },
        })
        window:initialise()
        window:instantiate()
        WorkUI.instance = window
    end
    window.owner = owner or window.owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function WorkUI.Close()
    if WorkUI.instance then WorkUI.instance:close() end
end

function WorkUI.Toggle()
    if WorkUI.instance and WorkUI.instance.getIsVisible
        and WorkUI.instance:getIsVisible()
    then
        WorkUI.instance:close()
        return false
    end
    return WorkUI.Open() ~= nil
end

return WorkUI
