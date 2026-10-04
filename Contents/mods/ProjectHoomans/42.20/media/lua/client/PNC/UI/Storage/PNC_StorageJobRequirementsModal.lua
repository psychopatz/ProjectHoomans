require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"

PNC = PNC or {}
PNC.StorageJobRequirementsUI = PNC.StorageJobRequirementsUI or {}

local JobRequirementsUI = PNC.StorageJobRequirementsUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local Components = require "PNC/UI/Shared/PNC_ColonyUIComponents"
local Client = require "PNC/UI/Storage/PNC_StorageClient"
local Model = require
    "PNC/UI/Storage/PNC_StorageJobRequirementsModal_Model"

local function tr(key, fallback)
    return Shared.Tr(key, fallback)
end

local function drawRequirement(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local color = Theme.colors[row.colorName or "text"] or Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(row.label or "", UIFont.Small,
        list:getWidth() - 16), 9, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.detail or "", UIFont.Small,
        list:getWidth() - 16), 9, y + 25,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCStorageJobRequirementsWindow = PsychopatzWindow:derive(
    "ISPNCStorageJobRequirementsWindow")

function ISPNCStorageJobRequirementsWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCStorageJobRequirementsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.operationLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_Storage_Job", "JOB"), 1, 1, 1, 1, UIFont.Small, true)
    self.operationLabel:initialise()
    self:addChild(self.operationLabel)
    self.operationCombo = ISComboBox:new(0, 0, 220, 26, self,
        ISPNCStorageJobRequirementsWindow.onOperationChanged)
    self.operationCombo:initialise()
    self:addChild(self.operationCombo)
    self.requirements = UI.CreateList(self, {
        itemHeight = Layout.Pixels(46, self.uiScale),
        doDrawItem = drawRequirement,
    })
    self.spawnButton = UI.CreateButton(self, {
        id = "spawn", title = tr("UI_PNC_Storage_SpawnRequirements",
            "SPAWN IN STORAGE"), target = self,
        onclick = ISPNCStorageJobRequirementsWindow.onAction,
        variant = "primary",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close", title = tr("UI_Close", "CLOSE"), target = self,
        onclick = ISPNCStorageJobRequirementsWindow.onAction,
        variant = "quiet",
    })
    self.statusLabel = ISLabel:new(0, 0, 20, "", 0.8, 0.8, 0.8, 1,
        UIFont.Small, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
    self.operations = {}
    self:rebuildOperations()
    local update = Client.ReadSnapshot()
    self.lastRevision = tonumber(update.revision) or 0
    self.lastReceiveAt = update.receivedAt
    self:requestResponsiveLayout(true)
end

function ISPNCStorageJobRequirementsWindow:rebuildOperations()
    self.operations, self.operationDefinitions = Model.Operations()
    self.operationCombo:clear()
    for _, operation in ipairs(self.operations) do
        self.operationCombo:addOptionWithData(
            Model.OperationLabel(operation,
                self.operationDefinitions[operation]),
            operation)
    end
    if #self.operations > 0 then
        self.operationCombo:select(1)
        self.operation = self.operations[1]
    end
    self:rebuildRequirements()
    if self.spawnButton and self.spawnButton.setEnable then
        self.spawnButton:setEnable(Model.IsRegistered(self.operation))
    end
end

function ISPNCStorageJobRequirementsWindow:rebuildRequirements()
    Components.SetRows(self.requirements,
        Model.RequirementRows(self.operation))
end

function ISPNCStorageJobRequirementsWindow:onOperationChanged()
    local selected = self.operationCombo.selected or 0
    self.operation = self.operationCombo:getOptionData(selected)
        or self.operations[selected]
    self:rebuildRequirements()
    if self.spawnButton and self.spawnButton.setEnable then
        self.spawnButton:setEnable(Model.IsRegistered(self.operation))
    end
end

function ISPNCStorageJobRequirementsWindow:onAction(button)
    if button.internal == "close" then
        self:close()
        return
    end
    if button.internal ~= "spawn" or not self.operation
        or not Model.IsRegistered(self.operation)
    then return end
    if not self.storageId then
        UI.SetLabelText(self.statusLabel, tr(
            "UI_PNC_Storage_NoStorage", "Storage is unavailable."))
        return
    end
    local ok, reason, requestId = PNC.Client.RequestColonyAction(
        "storage_debug", {
            storageId = self.storageId,
            debugAction = "job_requirements",
            operation = self.operation,
            target = "storage",
        })
    self.pendingRequestId = requestId
    UI.SetLabelText(self.statusLabel, ok and tr(
        "UI_PNC_Storage_JobRequirements_Sent", "Request sent.")
        or tostring(reason or "Request failed."))
end

function ISPNCStorageJobRequirementsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local rowHeight = Layout.Pixels(46, self.uiScale)
    local comboHeight = Layout.Pixels(26, self.uiScale)
    Layout.SetBounds(self.operationLabel, rect.x, rect.y, 70, comboHeight)
    Layout.SetBounds(self.operationCombo, rect.x + Layout.Pixels(76,
        self.uiScale), rect.y, Layout.Pixels(240, self.uiScale), comboHeight)
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    local buttonY = rect.y + rect.height - buttonHeight
    Layout.SetBounds(self.spawnButton, rect.x, buttonY,
        Layout.Pixels(190, self.uiScale), buttonHeight)
    Layout.SetBounds(self.closeButton, rect.x + rect.width
        - Layout.Pixels(110, self.uiScale), buttonY,
        Layout.Pixels(110, self.uiScale), buttonHeight)
    Layout.SetBounds(self.statusLabel, rect.x, buttonY - 28,
        rect.width - Layout.Pixels(210, self.uiScale), 22)
    Layout.SetBounds(self.requirements, rect.x,
        rect.y + comboHeight + Layout.Pixels(12, self.uiScale), rect.width,
        math.max(rowHeight, buttonY - rect.y - comboHeight
            - Layout.Pixels(28, self.uiScale)))
    Components.LayoutScrollbar(self.requirements)
end

function ISPNCStorageJobRequirementsWindow:prerender()
    local changed, update = Client.HasUpdate(
        self.lastRevision, self.lastReceiveAt)
    if changed then
        self.lastRevision = tonumber(update.revision) or self.lastRevision
        self.lastReceiveAt = update.receivedAt
        local result = update.snapshot and update.snapshot.actionResult or nil
        if result and result.action == "storage_debug" then
            UI.SetLabelText(self.statusLabel,
                result.ok and tr("UI_PNC_Storage_JobRequirements_Added",
                    "Requirements added to storage.")
                or tostring(result.reason or "Job requirement request failed."))
        end
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCStorageJobRequirementsWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if JobRequirementsUI.instance == self then JobRequirementsUI.instance = nil end
end

function ISPNCStorageJobRequirementsWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    object.storageId = options and options.storageId or nil
    object.owner = options and options.owner or nil
    return object
end

function JobRequirementsUI.Open(options)
    options = type(options) == "table" and options or {}
    local window = JobRequirementsUI.instance
    if not window then
        window = UI.NewWindow(ISPNCStorageJobRequirementsWindow, {
            title = tr("UI_PNC_Storage_JobRequirements_Title",
                "STORAGE JOB REQUIREMENTS"),
            storageId = options.storageId,
            owner = options.owner,
            resizable = true,
            responsiveSpec = {
                width = 620, height = 430,
                minWidth = 500, minHeight = 340,
                maxWidth = 900, maxHeight = 700,
            },
        })
        window:initialise()
        window:instantiate()
        JobRequirementsUI.instance = window
    else
        window.storageId = options.storageId or window.storageId
        window.owner = options.owner or window.owner
    end
    window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop()
    return window
end

function JobRequirementsUI.Close()
    if JobRequirementsUI.instance then JobRequirementsUI.instance:close() end
end

return JobRequirementsUI
