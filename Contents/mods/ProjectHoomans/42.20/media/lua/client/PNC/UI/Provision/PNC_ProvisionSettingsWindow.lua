require "PsychopatzCore/UI/PsychopatzUI"
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
local Layout = UI.Layout

local function tr(key)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or key
end

ISPNCProvisionSettingsWindow = PsychopatzWindow:derive(
    "ISPNCProvisionSettingsWindow"
)

function ISPNCProvisionSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
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

function ISPNCProvisionSettingsWindow:layoutRows()
    local y = 8
    local categoryIndex = 1
    local currentCategory
    local width = math.max(260, self.scroll:getWidth() - 18)
    for _, row in ipairs(self.ruleRows or {}) do
        if row.definition.category ~= currentCategory then
            local category = self.categoryLabels[categoryIndex]
            category.widget:setX(8)
            category.widget:setY(y)
            y = y + 31
            categoryIndex = categoryIndex + 1
            currentCategory = row.definition.category
        end
        y = RulePanel.Layout(row, width, y)
        y = y + 8
    end
    self.scroll.contentHeight = y + 8
    self.scroll:setScrollHeight(self.scroll.contentHeight)
end

function ISPNCProvisionSettingsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    self.policyLabel:setX(rect.x)
    self.policyLabel:setY(rect.y + 5)
    Layout.SetBounds(self.policyCombo, rect.x + 72, rect.y,
        math.min(260, rect.width - 72), 26)
    local footerHeight = 66
    Layout.SetBounds(self.scroll, rect.x, rect.y + 36, rect.width,
        rect.height - footerHeight - 36)
    local statusY = rect.y + rect.height - footerHeight + 5
    local buttonY = rect.y + rect.height - 30
    Layout.SetBounds(self.resetButton, rect.x, buttonY,
        140, 28)
    Layout.SetBounds(self.cancelButton,
        rect.x + rect.width - 190, buttonY, 88, 28)
    Layout.SetBounds(self.applyButton,
        rect.x + rect.width - 94, buttonY, 94, 28)
    self.statusLabel:setX(rect.x)
    self.statusLabel:setY(statusY)
    self:layoutRows()
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
    self.statusLabel:setName(tr("UI_PNC_Provision_DefaultsPending"))
end

function ISPNCProvisionSettingsWindow:onCancel()
    self:close()
end

function ISPNCProvisionSettingsWindow:onApply()
    local read = self:readRows()
    if not read then
        self.statusLabel:setName(tr("UI_PNC_Provision_Invalid"))
        return
    end
    local ok = self.model:Submit()
    self.statusLabel:setName(tr(ok and "UI_PNC_Provision_Applying"
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
                self.statusLabel:setName(tr(result.ok
                    and "UI_PNC_Provision_Applied"
                    or "UI_PNC_Provision_Rejected"))
            end
        end
        self.lastReceiveAt = update.receivedAt
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCProvisionSettingsWindow:close()
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

function ProvisionUI.Open()
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
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

return ProvisionUI
