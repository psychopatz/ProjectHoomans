require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.ZoneUI = PNC.CommandHub.ZoneUI or {}

local Hub = PNC.CommandHub
local ZoneUI = Hub.ZoneUI
local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_ZoneRegistry"
local Options = CoreHub.Options
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

ZoneUI.instances = ZoneUI.instances or {}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function setEnabled(button, enabled)
    if not button then return end
    if button.setEnable then button:setEnable(enabled == true)
    else button.enable = enabled == true end
end

local function snapshot()
    return PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement or {}
end

ISPNCCommandHubZoneWindow = PsychopatzWindow:derive(
    "ISPNCCommandHubZoneWindow"
)

function ISPNCCommandHubZoneWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCCommandHubZoneWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.controls = {}
    self.statusText = ""
    self.lastRevision = -1
    self.lastRequestAt = 0
    local definition = Registry.Get(self.definitionID)
    for _, section in ipairs(definition and definition.sections or {}) do
        local createButton = UI.CreateButton(self, {
            id = "zone-create:" .. tostring(section.id),
            title = tr("UI_PNC_CommandHub_Zone_Create", "CREATE ZONE"),
            target = self,
            onclick = ISPNCCommandHubZoneWindow.onControl,
            variant = "primary",
        })
        createButton.zoneSectionID = section.id
        createButton.zoneAction = "create"
        local clearButton = UI.CreateButton(self, {
            id = "zone-clear:" .. tostring(section.id),
            title = tr("UI_PNC_CommandHub_Zone_Delete", "DELETE ZONE"),
            target = self,
            onclick = ISPNCCommandHubZoneWindow.onControl,
            variant = "danger",
        })
        clearButton.zoneSectionID = section.id
        clearButton.zoneAction = "clear"
        self.controls[section.id] = {
            definition = section,
            createButton = createButton,
            clearButton = clearButton,
        }
    end
    self:refresh()
    self:requestSnapshot()
    self:requestResponsiveLayout(true)
end

function ISPNCCommandHubZoneWindow:getDefinition()
    return Registry.Get(self.definitionID)
end

function ISPNCCommandHubZoneWindow:getZoneState()
    local definition = self:getDefinition()
    return definition and definition.getState
        and definition.getState(snapshot()) or nil
end

function ISPNCCommandHubZoneWindow:isConfigured(section)
    local zone = self:getZoneState()
    if not zone then return false end
    if self.definitionID == "corpse_haul" then
        return zone.sourceRegion ~= nil and zone.destinationRegion ~= nil
    end
    return zone.enabled ~= false and zone.id ~= nil
end

function ISPNCCommandHubZoneWindow:setStatus(value)
    self.statusText = tostring(value or "")
end

function ISPNCCommandHubZoneWindow:refresh()
    local definition = self:getDefinition()
    if not definition then return end
    self.title = tr(definition.titleKey, definition.titleFallback or "ZONE")
    local zone = self:getZoneState()
    if self.definitionID == "fishing" and PNC.FishingZoneOverlay then
        if zone and PNC.FishingZoneOverlay.SetZone then
            PNC.FishingZoneOverlay.SetZone(zone)
        elseif PNC.FishingZoneOverlay.Clear then
            PNC.FishingZoneOverlay.Clear()
        end
    end
    for _, section in ipairs(definition.sections or {}) do
        local controls = self.controls[section.id]
        if controls then
            local configured = self:isConfigured(section)
            controls.createButton:setTitle(configured
                and tr("UI_PNC_CommandHub_Zone_ConfiguredButton", "CONFIGURED")
                or tr("UI_PNC_CommandHub_Zone_Create", "CREATE ZONE"))
            controls.clearButton:setTitle(self.definitionID == "corpse_haul"
                and tr("UI_PNC_CommandHub_Zone_Clear", "CLEAR ZONES")
                or tr("UI_PNC_CommandHub_Zone_Delete", "DELETE ZONE"))
            setEnabled(controls.createButton, not configured)
            setEnabled(controls.clearButton, configured)
            UI.StyleButton(controls.createButton,
                configured and "quiet" or "primary")
            UI.StyleButton(controls.clearButton,
                configured and "danger" or "quiet")
        end
    end
    self:requestResponsiveLayout(true)
end

function ISPNCCommandHubZoneWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function ISPNCCommandHubZoneWindow:onControl(button)
    local controls = button and self.controls[button.zoneSectionID] or nil
    local section = controls and controls.definition or nil
    local definition = self:getDefinition()
    if not section or not definition then return false end
    if button.zoneAction == "create" then
        local result, reason
        if type(section.open) == "function" then
            result, reason = section.open(self)
        else
            result, reason = Registry.OpenSelector(self, definition, section)
        end
        if result == false or result == nil then
            self:setStatus(tostring(reason or tr(
                "UI_PNC_CommandHub_Zone_SelectorUnavailable",
                "ZONE SELECTOR UNAVAILABLE")))
            return false
        end
        self:setStatus(tr("UI_PNC_CommandHub_Zone_Selecting",
            "SELECT AN AREA IN THE WORLD"))
        return true
    end
    if button.zoneAction == "clear" then
        local result
        if type(section.clear) == "function" then
            result = section.clear(self)
        elseif PNC.Client and PNC.Client.RequestColonyAction then
            result = PNC.Client.RequestColonyAction(definition.clearAction)
        else
            result = false
        end
        if result == false then
            self:setStatus(tr("UI_PNC_CommandHub_Zone_ClearFailed",
                "COULD NOT DELETE ZONE"))
            return false
        end
        self:setStatus(tr("UI_PNC_CommandHub_Zone_RequestSent",
            "ZONE REQUEST SENT"))
        self:refresh()
        return true
    end
    return false
end

function ISPNCCommandHubZoneWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    local scale = Layout.Scale()
    if self.uiScale ~= scale then
        self.uiScale = scale
        self:requestResponsiveLayout(true)
    end
    local current = PNC.Network and PNC.Network.ClientState or {}
    local revision = tonumber(current.colonyManagementRevision) or 0
    if revision ~= (tonumber(self.lastRevision) or -1) then
        self.lastRevision = revision
        self:refresh()
    end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
    ZoneUI.SyncPositions()
end

function ISPNCCommandHubZoneWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if ZoneUI.instances[self.definitionID] == self then
        ZoneUI.instances[self.definitionID] = nil
    end
end

function ISPNCCommandHubZoneWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow_Layout"

function ZoneUI.Open(definitionID, owner)
    local definition = Registry.Get(definitionID)
    if not definition then return nil end
    local window = ZoneUI.instances[definition.id]
    if not window then
        window = UI.NewWindow(ISPNCCommandHubZoneWindow, {
            title = tr(definition.titleKey, definition.titleFallback or "ZONE"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Zone." .. definition.id,
            responsiveSpec = {
                width = 360,
                height = 170 + #(definition.sections or {}) * 94,
                minWidth = 300,
                minHeight = 190,
                maxWidth = 560,
                maxHeight = 520,
            },
        })
        window.definitionID = definition.id
        window.owner = owner
        window:initialise()
        window:instantiate()
        ZoneUI.instances[definition.id] = window
    else
        window.owner = owner or window.owner
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refresh()
    window:requestSnapshot()
    ZoneUI.SyncPositions()
    return window
end

function ZoneUI.Close(definitionID)
    local window = ZoneUI.instances[tostring(definitionID or "")]
    if window then window:close() end
end

function ZoneUI.CloseAll()
    local pending = {}
    for _, window in pairs(ZoneUI.instances) do pending[#pending + 1] = window end
    for _, window in ipairs(pending) do
        if window then window:close() end
    end
end

function ZoneUI.SyncPositions()
    local parent = Hub.instance
    if not parent or not parent.getIsVisible
        or not parent:getIsVisible()
    then
        ZoneUI.CloseAll()
        return
    end
    local anchor = CoreHub.Actions and CoreHub.Actions.instance or nil
    if not anchor or not anchor.getIsVisible or not anchor:getIsVisible() then
        anchor = Hub.instance
    end
    if not anchor or not anchor.getIsVisible or not anchor:getIsVisible() then
        return
    end
    local open = {}
    for _, definition in ipairs(Registry.All()) do
        local window = ZoneUI.instances[definition.id]
        if window and window.getIsVisible and window:getIsVisible() then
            open[#open + 1] = window
        end
    end
    local gap = Layout.Pixels(4, Layout.Scale())
    local branch = Options.GetBranch()
    local cursor = branch == "left"
        and anchor:getX() or anchor:getX() + anchor:getWidth()
    local screenWidth, screenHeight = Layout.ScreenSize()
    for _, window in ipairs(open) do
        local x
        if branch == "left" then
            x = cursor - window:getWidth()
            cursor = x - gap
        else
            x = cursor
            cursor = x + window:getWidth() + gap
        end
        x = Layout.Clamp(x, 0,
            math.max(0, screenWidth - window:getWidth()))
        local y = Layout.Clamp(anchor:getY(), 0,
            math.max(0, screenHeight - window:getHeight()))
        window:setX(x)
        window:setY(y)
    end
end

return ZoneUI
