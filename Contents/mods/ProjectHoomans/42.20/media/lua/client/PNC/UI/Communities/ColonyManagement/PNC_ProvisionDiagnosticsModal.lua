require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ProvisionDiagnosticsUI = PNC.ProvisionDiagnosticsUI or {}

local DiagnosticsUI = PNC.ProvisionDiagnosticsUI
local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local State = PNC.Network and PNC.Network.ClientState or {}

local function drawRow(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local color = Theme.colors[row.colorName or "text"] or Theme.colors.text
    list:drawText(Layout.Ellipsize(row.label or "", UIFont.Small,
        list:getWidth() - 20), 10, y + 6,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.detail or "", UIFont.Small,
        list:getWidth() - 20), 10, y + 25,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function add(rows, key, label, detail, colorName)
    rows[#rows + 1] = {
        key = key, label = label, detail = detail, colorName = colorName,
    }
end

local function itemDetail(item)
    return string.format("%s x%d | hunger %.3f | thirst %.3f | uses %d%s",
        tostring(item.fullType or "unknown"), tonumber(item.quantity) or 0,
        tonumber(item.hunger) or 0, tonumber(item.thirst) or 0,
        tonumber(item.remainingUses) or 0,
        item.unsafe and " | UNSAFE" or "")
end

local function buildRows(data)
    local rows = {}
    if type(data) ~= "table" then
        add(rows, "loading", Shared.Tr(
            "UI_PNC_ProvisionDebug_Loading", "Loading diagnostics..."), "")
        return rows
    end
    add(rows, "identity", tostring(data.name or data.npcID),
        tostring(data.npcID or "unknown"))
    add(rows, "access", Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageAccess", "Storage access"),
        tostring(data.storageAccessReason or "unknown") .. " | mode "
            .. tostring(data.storageAccessMode or "unknown"),
        data.storageAccess and "success" or "danger")
    add(rows, "inventory", Shared.Tr(
        "UI_PNC_ProvisionDebug_Inventory", "Inventory state"),
        string.format("mode %s | revision %d",
            tostring(data.inventoryMode or "unknown"),
            tonumber(data.inventoryRevision) or 0))
    local location = data.location or {}
    add(rows, "location", Shared.Tr(
        "UI_PNC_ProvisionDebug_Location", "NPC location"),
        string.format("%.1f, %.1f, %.0f",
            tonumber(location.x) or 0, tonumber(location.y) or 0,
            tonumber(location.z) or 0))
    local home = data.home or {}
    add(rows, "home", Shared.Tr(
        "UI_PNC_ProvisionDebug_Home", "Colony home"),
        string.format("%.1f, %.1f, %.0f | radius %.1f | distance %.1f",
            tonumber(home.x) or 0, tonumber(home.y) or 0,
            tonumber(home.z) or 0, tonumber(home.radius) or 0,
            tonumber(data.homeDistance) or -1))
    local storage = data.storageSummary or {}
    local foodStorage = storage.food or {}
    local waterStorage = storage.hydration or {}
    local medicineStorage = storage.bandage or {}
    add(rows, "storage_food", Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageFood", "Colony storage food"),
        string.format("hunger utility %.3f | calories %.0f | types %d",
            tonumber(foodStorage.amount) or 0,
            tonumber(foodStorage.calories) or 0,
            tonumber(foodStorage.candidateTypes) or 0))
    add(rows, "storage_water", Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageHydration", "Colony storage hydration"),
        string.format("thirst utility %.3f | types %d",
            tonumber(waterStorage.amount) or 0,
            tonumber(waterStorage.candidateTypes) or 0))
    add(rows, "storage_medicine", Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageMedicine", "Colony storage medicine"),
        string.format("usable bandages %.0f | types %d",
            tonumber(medicineStorage.amount) or 0,
            tonumber(medicineStorage.candidateTypes) or 0))
    local grabLabel = Shared.Tr("UI_PNC_ProvisionDebug_Grab", "GRAB")
    for index, result in ipairs(data.forceResults or {}) do
        add(rows, "force_result_" .. index,
            grabLabel .. " "
                .. string.upper(tostring(result.ruleId or "unknown")),
            tostring(result.reason or "unknown"),
            result.ok and "success" or "danger")
    end
    for _, rule in ipairs(data.rules or {}) do
        local ruleName = string.upper(tostring(rule.id or "unknown"))
        add(rows, "rule_" .. ruleName, ruleName,
            tostring(rule.measure or "unknown"), "accent")
        add(rows, "measure_" .. ruleName, Shared.Tr(
            "UI_PNC_ProvisionDebug_Measurement", "Measured reserve"),
            string.format("on hand %.3f | refill below %.3f | target %.3f | deficit %.3f",
                tonumber(rule.onHand) or 0,
                tonumber(rule.refillBelow) or 0,
                tonumber(rule.target) or 0,
                tonumber(rule.deficit) or 0),
            rule.deficit and rule.deficit > 0 and "warning" or "success")
        add(rows, "scheduler_" .. ruleName, Shared.Tr(
            "UI_PNC_ProvisionDebug_Scheduler", "Scheduler"),
            string.format("enabled %s | refilling %s | queued %s | ready %.3f",
                tostring(rule.enabled == true),
                tostring(rule.refilling == true),
                tostring(rule.queued == true), tonumber(rule.readyAt) or 0))
        add(rows, "runtime_" .. ruleName, Shared.Tr(
            "UI_PNC_ProvisionDebug_Runtime", "Last supply attempt"),
            string.format("phase %s | result %s | failure %s | retry %.3f",
                tostring(rule.phase or "IDLE"),
                tostring(rule.lastResult or "none"),
                tostring(rule.lastFailureReason or "none"),
                tonumber(rule.nextRetry) or 0))
        add(rows, "candidates_" .. ruleName, Shared.Tr(
            "UI_PNC_ProvisionDebug_Candidates", "Recognized candidates"),
            string.format("personal %d | storage %d | selected %d",
                #(rule.personalItems or {}),
                tonumber(rule.storageCandidateCount) or 0,
                #(rule.selected or {})))
        for index, item in ipairs(rule.personalItems or {}) do
            add(rows, "personal_" .. ruleName .. index,
                Shared.Tr("UI_PNC_ProvisionDebug_Carried", "Carried item"),
                itemDetail(item))
        end
        for index, item in ipairs(rule.selected or {}) do
            add(rows, "selected_" .. ruleName .. index,
                Shared.Tr("UI_PNC_ProvisionDebug_Selected", "Storage selection"),
                itemDetail(item))
        end
    end
    return rows
end

ISPNCProvisionDiagnosticsWindow = PsychopatzWindow:derive(
    "ISPNCProvisionDiagnosticsWindow"
)

function ISPNCProvisionDiagnosticsWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCProvisionDiagnosticsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    local closeTitle = Shared.Tr("UI_Close", "CLOSE")
    self.rows = UI.CreateList(self, { itemHeight = 46, doDrawItem = drawRow })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh", title = Shared.Tr(
            "UI_PNC_ProvisionDebug_Refresh", "REFRESH"),
        target = self, onclick = ISPNCProvisionDiagnosticsWindow.onAction,
        variant = "selected",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close", title = closeTitle,
        target = self, onclick = ISPNCProvisionDiagnosticsWindow.onAction,
        variant = "quiet",
    })
    Components.SetRows(self.rows, buildRows(nil))
    self:requestResponsiveLayout(true)
    self:requestDiagnostics()
end

function ISPNCProvisionDiagnosticsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    Layout.SetBounds(self.rows, rect.x, rect.y, rect.width,
        math.max(80, rect.height - buttonHeight - 8))
    local y = rect.y + rect.height - buttonHeight
    Layout.SetBounds(self.refreshButton, rect.x, y,
        Layout.Pixels(130, self.uiScale), buttonHeight)
    Layout.SetBounds(self.closeButton,
        rect.x + rect.width - Layout.Pixels(110, self.uiScale), y,
        Layout.Pixels(110, self.uiScale), buttonHeight)
    Components.LayoutScrollbar(self.rows)
end

function ISPNCProvisionDiagnosticsWindow:requestDiagnostics()
    if not PNC.Client or not PNC.Client.RequestColonyAction then return end
    PNC.Client.RequestColonyAction("debug_need", {
        npcID = self.npcID, operation = "inspect_provision",
    })
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCProvisionDiagnosticsWindow:onAction(button)
    if button.internal == "refresh" then
        self:requestDiagnostics()
        return
    end
    self:close()
end

function ISPNCProvisionDiagnosticsWindow:prerender()
    local revision = tonumber(State.colonyManagementRevision) or 0
    if revision > (self.lastRevision or 0) then
        self.lastRevision = revision
        local result = State.colonyManagement
            and State.colonyManagement.actionResult or nil
        local details = result and result.details or nil
        if result and result.action == "debug_need"
            and details and tostring(details.npcID) == tostring(self.npcID)
            and type(details.rules) == "table"
        then
            Components.SetRows(self.rows, buildRows(details))
        elseif result and result.action == "debug_need" and result.ok == false then
            local failedLabel = Shared.Tr(
                "UI_PNC_ProvisionDebug_Failed", "Diagnostics failed"
            )
            Components.SetRows(self.rows, {{
                key = "error",
                label = failedLabel,
                detail = tostring(result.reason or "unknown"),
                colorName = "danger",
            }})
        end
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCProvisionDiagnosticsWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DiagnosticsUI.instance == self then DiagnosticsUI.instance = nil end
end

function ISPNCProvisionDiagnosticsWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    object.npcID = options.npcID
    return object
end

function DiagnosticsUI.Open(person)
    if not person or not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then return nil end
    if DiagnosticsUI.instance then DiagnosticsUI.instance:close() end
    local windowCaption = Shared.Tr("UI_PNC_ProvisionDebug_Title",
        "PROVISION DIAGNOSTICS") .. " - "
            .. tostring(person.name or person.label or person.id)
    local window = UI.NewWindow(ISPNCProvisionDiagnosticsWindow, {
        title = windowCaption,
        npcID = person.id,
        resizable = true,
        responsiveSpec = {
            width = 780, height = 620, minWidth = 600, minHeight = 420,
            maxWidth = 1100, maxHeight = 860,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop()
    DiagnosticsUI.instance = window
    return window
end

return DiagnosticsUI
