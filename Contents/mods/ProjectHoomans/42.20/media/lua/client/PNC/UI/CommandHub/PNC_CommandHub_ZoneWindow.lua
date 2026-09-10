require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzAttachedWindow"
require "ISUI/ISPanel"
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
require "PNC/UI/CommandHub/PNC_CommandHub_ZoneOverlay"

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
local AttachedWindow = UI.AttachedWindow or PsychopatzAttachedWindow
local Selector = UI.GridRegionSelector
local ZoneOverlay = Hub.ZoneOverlay

ZoneUI.instances = ZoneUI.instances or {}
ZoneUI.activeDefinitionID = ZoneUI.activeDefinitionID or nil

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function setEnabled(button, enabled)
    if not button then return end
    if button.setEnable then button:setEnable(enabled == true)
    else button.enable = enabled == true end
end

local function snapshot(definitionID)
    local client = PNC.ColonyManagementClient
    if definitionID == "base_zone" and client
        and type(client.ReadBaseSnapshot) == "function"
    then
        local update = client.ReadBaseSnapshot()
        if type(update) == "table" and type(update.snapshot) == "table" then
            return update.snapshot
        end
    end
    return PNC.Network and PNC.Network.ClientState
        and (PNC.Network.ClientState.colonyManagement
            or PNC.Network.ClientState.colonyBase) or {}
end

local function revision(definitionID)
    local client = PNC.ColonyManagementClient
    if definitionID == "base_zone" and client
        and type(client.ReadBaseSnapshot) == "function"
    then
        local update = client.ReadBaseSnapshot()
        if type(update) == "table" then return tonumber(update.revision) or 0 end
    end
    local state = PNC.Network and PNC.Network.ClientState or {}
    return tonumber(state.colonyManagementRevision) or 0
end

local function defaultControls()
    return {
        {
            id = "create", action = "create",
            titleKey = "UI_PNC_CommandHub_Zone_Create",
            titleFallback = "CREATE ZONE", variant = "primary",
        },
        {
            id = "clear", action = "clear",
            titleKey = "UI_PNC_CommandHub_Zone_Delete",
            titleFallback = "DELETE ZONE", variant = "danger",
        },
    }
end

local function isPendingSnapshotReason(reason)
    return reason == "COLONY_STATE_UNAVAILABLE"
        or reason == "FACTION_STATE_UNAVAILABLE"
        or reason == "BASE_STATE_UNAVAILABLE"
        or reason == "PLAYER_UNAVAILABLE"
end

local function actionResultText(result)
    if type(result) ~= "table"
        or result.action ~= "corpse_haul_zones_set"
        or result.ok ~= false
    then return nil end
    if result.reason == "CORPSE_HAUL_ZONES_OVERLAP" then
        return tr("UI_PNC_CommandHub_CorpseHaul_Overlap",
            "Collect and dump areas cannot overlap.")
    end
    return tostring(result.reason or "CORPSE_HAUL_SAVE_FAILED")
end

ISPNCCommandHubZoneWindow = AttachedWindow:derive(
    "ISPNCCommandHubZoneWindow"
)

function ISPNCCommandHubZoneWindow:initialise()
    AttachedWindow.initialise(self)
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    Options.ApplyWindowOpacity(self, Options.GetOpacity())
end

function ISPNCCommandHubZoneWindow:createChildren()
    AttachedWindow.createChildren(self)
    self.controls = {}
    self.statusText = ""
    self.lastRevision = -1
    self.lastRequestAt = 0
    self.lastActionResultRevision = nil
    local definition = Registry.Get(self.definitionID)
    for _, section in ipairs(definition and definition.sections or {}) do
        local buttons = {}
        for _, control in ipairs(section.controls or defaultControls()) do
            local action = tostring(control.action or control.id or "")
            local button = UI.CreateButton(self, {
                id = "zone-" .. action .. ":" .. tostring(section.id),
                title = tr(control.titleKey, control.titleFallback or action),
                target = self,
                onclick = ISPNCCommandHubZoneWindow.onControl,
                variant = control.variant or "primary",
            })
            button.zoneSectionID = section.id
            button.zoneAction = action
            button.zoneControl = control
            buttons[#buttons + 1] = button
        end
        self.controls[section.id] = {
            definition = section,
            buttons = buttons,
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
        and definition.getState(snapshot(self.definitionID)) or nil
end

function ISPNCCommandHubZoneWindow:isConfigured(section)
    local zone = self:getZoneState()
    if not zone then return false end
    if self.definitionID == "corpse_haul" then
        return zone.sourceRegion ~= nil and zone.destinationRegion ~= nil
    end
    if self.definitionID == "base_zone" then
        return zone.id ~= nil and zone.geometry ~= nil
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
    if ZoneOverlay and ZoneOverlay.SetActive then
        ZoneOverlay.SetActive(self.definitionID, zone)
    end
    local currentRevision = revision(self.definitionID)
    if currentRevision ~= self.lastActionResultRevision then
        self.lastActionResultRevision = currentRevision
        if definition.applyResult then
            definition.applyResult(self, snapshot(self.definitionID))
        end
        local message = actionResultText(snapshot(self.definitionID).actionResult)
        if message then self:setStatus(message) end
    end
    for _, section in ipairs(definition.sections or {}) do
        local controls = self.controls[section.id]
        if controls then
            local configured = self:isConfigured(section)
            for _, button in ipairs(controls.buttons or {}) do
                local action = button.zoneAction
                local control = button.zoneControl or {}
                local enabled
                if type(section.isActionEnabled) == "function" then
                    enabled = section.isActionEnabled(action, configured,
                        self:getZoneState())
                elseif action == "create" then
                    enabled = not configured
                elseif action == "clear" then
                    enabled = configured
                else
                    enabled = configured
                end
                local title = tr(control.titleKey, control.titleFallback
                    or action)
                if action == "create" and configured then
                    title = tr("UI_PNC_CommandHub_Zone_ConfiguredButton",
                        "CONFIGURED")
                elseif action == "clear" and self.definitionID == "corpse_haul"
                then
                    title = tr("UI_PNC_CommandHub_Zone_Clear", "CLEAR ZONES")
                end
                button:setTitle(title)
                setEnabled(button, enabled)
                UI.StyleButton(button, enabled
                    and (control.variant or "primary") or "quiet")
            end
        end
    end
    self:requestResponsiveLayout(true)
end

function ISPNCCommandHubZoneWindow:requestSnapshot()
    if self.definitionID == "base_zone"
        and PNC.Client and PNC.Client.RequestBaseBootstrap
    then
        PNC.Client.RequestBaseBootstrap()
    elseif PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function ISPNCCommandHubZoneWindow:onControl(button)
    local controls = button and self.controls[button.zoneSectionID] or nil
    local section = controls and controls.definition or nil
    local definition = self:getDefinition()
    if not section or not definition then return false end
    if button.zoneAction ~= "clear" then
        local result, reason
        if type(section.open) == "function" then
            result, reason = section.open(self, button.zoneAction)
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

function ISPNCCommandHubZoneWindow:tryStartPendingOperation()
    local operation = self.pendingOperation
    if not operation then return false end
    if Selector and Selector.instance
        and Selector.instance.ownerWindow == self
    then
        self.pendingOperation = nil
        return true
    end
    local current = snapshot(self.definitionID)
    if operation == "create"
        and (type(current.colony) ~= "table"
            or not current.colony.id
            or not (current.colony.factionID or current.colony.factionId))
    then
        return false
    end
    local definition = self:getDefinition()
    local result, reason
    local section = definition and definition.sections
        and definition.sections[1] or nil
    if section and type(section.open) == "function" then
        result, reason = section.open(self, operation)
    else
        result, reason = false, "SELECTOR_UNAVAILABLE"
    end
    if result == false or result == nil then
        if isPendingSnapshotReason(reason) then return false end
        self.pendingOperation = nil
        self:setStatus(tostring(reason or tr(
            "UI_PNC_CommandHub_Zone_SelectorUnavailable",
            "ZONE SELECTOR UNAVAILABLE")))
        return false
    end
    self.pendingOperation = nil
    return true
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
    local currentRevision = revision(self.definitionID)
    if currentRevision ~= (tonumber(self.lastRevision) or -1) then
        self.lastRevision = currentRevision
        self:refresh()
    end
    self:tryStartPendingOperation()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot()
    end
    AttachedWindow.prerender(self)
    ZoneUI.SyncPositions()
end

function ISPNCCommandHubZoneWindow:close()
    if Selector and Selector.instance
        and Selector.instance.ownerWindow == self
    then
        Selector.instance:close(false)
    end
    if ZoneUI.activeDefinitionID == self.definitionID then
        ZoneUI.activeDefinitionID = nil
        if ZoneOverlay and ZoneOverlay.Clear then ZoneOverlay.Clear() end
    end
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if ZoneUI.instances[self.definitionID] == self then
        ZoneUI.instances[self.definitionID] = nil
    end
end

function ISPNCCommandHubZoneWindow:new(x, y, width, height, options)
    local object = AttachedWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow_Layout"

function ZoneUI.Open(definitionID, owner, openOptions)
    local definition = Registry.Get(definitionID)
    if not definition then return nil end

    local id = definition.id
    local current = ZoneUI.instances[id]
    if ZoneUI.activeDefinitionID == id
        and current and current.getIsVisible and current:getIsVisible()
    then
        if type(openOptions) == "table" and openOptions.startOperation then
            current.pendingOperation = openOptions.startOperation
            current:bringToTop()
            current:refresh()
            current:tryStartPendingOperation()
            return current
        end
        ZoneUI.Close(id)
        return nil
    end

    -- The action panel is the parent of exactly one zone editor. Switching
    -- actions closes the old third-level window before opening the new one.
    ZoneUI.CloseAll()

    local window = ZoneUI.instances[id]
    if not window then
        window = UI.NewWindow(ISPNCCommandHubZoneWindow, {
            title = tr(definition.titleKey, definition.titleFallback or "ZONE"),
            resizable = true,
            collapsible = false,
            bottomResize = true,
            persistenceKey = "PNC.CommandHub.Zone." .. id,
            responsiveSpec = {
                width = 360,
                height = 170 + #(definition.sections or {}) * 94,
                minWidth = 300,
                minHeight = 190,
                maxWidth = 560,
                maxHeight = 520,
            },
            geometryTrace = true,
        })
        window.definitionID = definition.id
        window.owner = owner
        window:initialise()
        window:instantiate()
        ZoneUI.instances[id] = window
    else
        window.owner = owner or window.owner
    end
    ZoneUI.activeDefinitionID = id
    window.pendingOperation = type(openOptions) == "table"
        and openOptions.startOperation or nil
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refresh()
    window:requestSnapshot()
    window:tryStartPendingOperation()
    ZoneUI.SyncPositions()
    return window
end

function ZoneUI.Close(definitionID)
    local id = tostring(definitionID or "")
    local window = ZoneUI.instances[id]
    if window then window:close() end
    if ZoneUI.activeDefinitionID == id and not window then
        ZoneUI.activeDefinitionID = nil
        if ZoneOverlay and ZoneOverlay.Clear then ZoneOverlay.Clear() end
    end
end

function ZoneUI.CloseAll()
    if Selector and Selector.instance and Selector.instance.ownerWindow
        and Selector.instance.ownerWindow.definitionID
    then
        Selector.instance:close(false)
    end
    local pending = {}
    for _, window in pairs(ZoneUI.instances) do pending[#pending + 1] = window end
    for _, window in ipairs(pending) do
        if window then window:close() end
    end
    ZoneUI.activeDefinitionID = nil
    if ZoneOverlay and ZoneOverlay.Clear then ZoneOverlay.Clear() end
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
        ZoneUI.CloseAll()
        return
    end

    local window = ZoneUI.instances[ZoneUI.activeDefinitionID]
    if not window or not window.getIsVisible or not window:getIsVisible() then
        ZoneUI.activeDefinitionID = nil
        if ZoneOverlay and ZoneOverlay.Clear then ZoneOverlay.Clear() end
        return
    end
    local gap = Layout.Pixels(4, Layout.Scale())
    local branch = Options.GetBranch()
    local screenWidth, screenHeight = Layout.ScreenSize()
    local x
    if branch == "left" then
        x = anchor:getX() - window:getWidth() - gap
    else
        x = anchor:getX() + anchor:getWidth() + gap
    end
    x = Layout.Clamp(x, 0,
        math.max(0, screenWidth - window:getWidth()))
    local y = Layout.Clamp(anchor:getY(), 0,
        math.max(0, screenHeight - window:getHeight()))
    window:setX(x)
    window:setY(y)
end

return ZoneUI
