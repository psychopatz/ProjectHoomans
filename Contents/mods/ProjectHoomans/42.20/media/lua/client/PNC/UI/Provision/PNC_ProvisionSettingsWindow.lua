require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Components/PsychopatzWidgetWindow"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"
local Model = require "PNC/UI/Provision/PNC_ProvisionSettingsModel"
local RulePanel = require "PNC/UI/Provision/PNC_ProvisionRulePanel"
require "PNC/UI/Provision/PNC_ProvisionScrollPanel"

PNC = PNC or {}
PNC.ProvisionSettingsUI = PNC.ProvisionSettingsUI or {}

local ProvisionUI = PNC.ProvisionSettingsUI
local Client = PNC.ProvisionSettingsClient
local UI = PsychopatzCore.UI
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local WidgetWindow = UI.WidgetWindow

local function tr(key)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or key
end

local function syncCommandHub()
    local hub = PNC.CommandHub
    local owner = hub and hub.instance or nil
    if not owner or not owner.getIsVisible or not owner:getIsVisible() then
        return
    end
    local controller = hub.ChildController
    if controller and controller.SyncPositions then
        controller.SyncPositions()
    end
end

ISPNCProvisionSettingsWindow = PsychopatzWindow:derive(
    "ISPNCProvisionSettingsWindow"
)

function ISPNCProvisionSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCProvisionSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.model = Model.New(Client.CurrentSnapshot(), Client)
    self.policyLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_Provision_Policy"), 1, 1, 1, 1, UIFont.Small, true)
    self.policyLabel:initialise()
    self:addChild(self.policyLabel)
    self.policyCombo = ISComboBox:new(0, 0, 220, 26, self, nil)
    self.policyCombo:initialise()
    self.policyCombo:addOption(tr("UI_PNC_Provision_ColonyDefault"))
    self:addChild(self.policyCombo)
    self.scroll = ISPNCProvisionScrollPanel:new(0, 0, 100, 100)
    self.scroll:initialise()
    self.scroll:instantiate()
    self:addChild(self.scroll)
    self.resetButton = UI.CreateButton(self, {
        id = "reset", title = tr("UI_PNC_Provision_ResetDefaults"),
        target = self, onclick = ISPNCProvisionSettingsWindow.onReset,
        variant = "quiet",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel", title = tr("UI_PNC_Provision_Cancel"),
        target = self, onclick = ISPNCProvisionSettingsWindow.onCancel,
        variant = "quiet",
    })
    self.applyButton = UI.CreateButton(self, {
        id = "apply", title = tr("UI_PNC_Provision_Apply"),
        target = self, onclick = ISPNCProvisionSettingsWindow.onApply,
        variant = "primary",
    })
    self.statusLabel = ISLabel:new(0, 0, 20, "", 0.8, 0.8, 0.8, 1,
        UIFont.Small, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
    self:buildRuleRows()
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-colony-provision-widget",
            onDetachedChanged = syncCommandHub,
        })
    end
end

function ISPNCProvisionSettingsWindow:buildRuleRows()
    self.ruleRows = {}
    self.categoryLabels = {}
    local previousCategory
    for _, definition in ipairs(PNC.ProvisionRuleRegistry.List()) do
        if definition.category ~= previousCategory then
            local category = PNC.ProvisionRuleRegistry.Categories[
                definition.category] or {}
            local title = ISLabel:new(0, 0, 24, tr(category.labelKey),
                0.7, 0.8, 1, 1, UIFont.Medium, true)
            title:initialise()
            self.scroll:addChild(title)
            self.categoryLabels[#self.categoryLabels + 1] = {
                id = definition.category, widget = title,
            }
            previousCategory = definition.category
        end
        self.ruleRows[#self.ruleRows + 1] = RulePanel.Create(
            self.scroll, definition, self.model, tr
        )
    end
end

function ISPNCProvisionSettingsWindow:readRows()
    for _, row in ipairs(self.ruleRows or {}) do
        local ok, reason = RulePanel.Read(row, self.model)
        if not ok then return false, reason end
    end
    return true
end

function ISPNCProvisionSettingsWindow:refreshRows()
    for _, row in ipairs(self.ruleRows or {}) do
        RulePanel.Refresh(row, self.model)
    end
end

function ISPNCProvisionSettingsWindow:onReset()
    self.model:ResetDefaults()
    self:refreshRows()
    UI.SetLabelText(self.statusLabel,
        tr("UI_PNC_Provision_DefaultsPending"))
end

function ISPNCProvisionSettingsWindow:onCancel()
    self:close()
end

function ISPNCProvisionSettingsWindow:onApply()
    local read = self:readRows()
    if not read then
        UI.SetLabelText(self.statusLabel,
            tr("UI_PNC_Provision_Invalid"))
        return
    end
    local ok = self.model:Submit()
    UI.SetLabelText(self.statusLabel,
        tr(ok and "UI_PNC_Provision_Applying"
            or "UI_PNC_Provision_Invalid"))
end

function ISPNCProvisionSettingsWindow:requestSnapshot()
    Client.RequestSnapshot()
    self.lastRequestAt = Client.Now()
end

function ISPNCProvisionSettingsWindow:prerender()
    local update = Client.ReadUpdate(self.lastReceiveAt)
    if update then
        if update.snapshot then
            self.model:Load(update.snapshot)
            self:refreshRows()
            local result = update.result
            if result and result.action == "provision_set" then
                UI.SetLabelText(self.statusLabel,
                    tr(result.ok and "UI_PNC_Provision_Applied"
                        or "UI_PNC_Provision_Rejected"))
            end
        end
        self.lastReceiveAt = update.receivedAt
    end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCProvisionSettingsWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    ProvisionUI.instance = nil
end

function ISPNCProvisionSettingsWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/Provision/PNC_ProvisionSettingsWindow_Layout"

function ProvisionUI.Open(owner)
    local window = ProvisionUI.instance
    if not window then
        window = UI.NewWindow(ISPNCProvisionSettingsWindow, {
            title = tr("UI_PNC_Provision_Title"),
            resizable = true,
            persistenceKey = "PNC.ProvisionSettings",
            responsiveSpec = { width = 680, height = 680,
                minWidth = 520, minHeight = 480,
                maxWidth = 900, maxHeight = 900 },
        })
        window:initialise()
        window:instantiate()
        ProvisionUI.instance = window
    end
    window.owner = owner or window.owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function ProvisionUI.Close()
    if ProvisionUI.instance then ProvisionUI.instance:close() end
end

return ProvisionUI
