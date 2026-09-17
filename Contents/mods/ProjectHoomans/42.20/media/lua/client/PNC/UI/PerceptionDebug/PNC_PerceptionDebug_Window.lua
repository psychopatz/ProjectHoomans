-- Dashboard for the client-local perception snapshot.  It deliberately has
-- no request/response path: refresh means re-scan the loaded cell locally.
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}
PNC.PerceptionDebug.UI = PNC.PerceptionDebug.UI or {}

local DebugUI = PNC.PerceptionDebug.UI
local Settings = PNC.PerceptionDebug.Settings
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
local Model = PNC.PerceptionDebug.Model
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
local Overlay = PNC.PerceptionDebug.Overlay
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local SLEEP_COLOR = { r = 0.78, g = 0.42, b = 1.0, a = 1 }

local OPTION_LABELS = {
    enabled = "UI_PNC_PerceptionDebug_EnableOverlay",
    showObjectNames = "UI_PNC_PerceptionDebug_ShowObjectNames",
    showSemanticNames = "UI_PNC_PerceptionDebug_ShowSemanticNames",
    showUsage = "UI_PNC_PerceptionDebug_ShowUsage",
    showSitting = "UI_PNC_PerceptionDebug_ShowSitting",
    showSleeping = "UI_PNC_PerceptionDebug_ShowSleeping",
    showWater = "UI_PNC_PerceptionDebug_ShowWater",
    showCampZones = "UI_PNC_PerceptionDebug_ShowCampZones",
    showJobs = "UI_PNC_PerceptionDebug_ShowJobs",
    showUnknownObjects = "UI_PNC_PerceptionDebug_ShowUnknown",
    showTooltip = "UI_PNC_PerceptionDebug_ShowTooltip",
    showCampPreview = "UI_PNC_PerceptionDebug_ShowCampPreview",
}

local function tr(key, fallback)
    local translation = PNC and PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback or key)
    end
    return fallback or key
end

local function trf(key, fallback, ...)
    local translation = PNC and PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        return translation.TrFormat(key, fallback, ...)
    end
    local value = tr(key, fallback)
    local args = { ... }
    value = string.gsub(value, "%%(%d+)", function(index)
        local position = tonumber(index)
        return position and args[position] ~= nil
            and tostring(args[position]) or "%%" .. index
    end)
    local ok, formatted = pcall(string.format, value, ...)
    return ok and formatted or value
end

local function now()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis()) or 0
    end
    return 0
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawObject(list, y, entry, alternate)
    local item = entry.item or {}
    local facts = item.object and item.object.facts or {}
    local selectedRow = list.selected == entry.index
    UI.DrawListSelection(list, y, list.itemheight, selectedRow, alternate)
    local color = facts.validSleeping and SLEEP_COLOR
        or facts.validSitting and Theme.colors.success
        or facts.waterState == "UNSAFE" and Theme.colors.danger
        or facts.waterState == "DEPLETED" and Theme.colors.warning
        or Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(item.label or tr(
        "UI_PNC_PerceptionDebug_Value_WorldObject", "world object"),
        UIFont.Small, list:getWidth() - 14), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.detail or tr(
        "UI_PNC_PerceptionDebug_Value_Unclassified", "unclassified"),
        UIFont.Small, list:getWidth() - 14), 8, y + 25,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCPerceptionDebugWindow = PsychopatzWindow:derive(
    "ISPNCPerceptionDebugWindow")

function ISPNCPerceptionDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCPerceptionDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.topControls = {}
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PNC_PerceptionDebug_Refresh", "REFRESH LOCAL SCAN"),
        target = self,
        onclick = ISPNCPerceptionDebugWindow.onAction,
        variant = "quiet",
    })
    self.overlayButton = UI.CreateButton(self, {
        id = "overlay",
        title = "",
        target = self,
        onclick = ISPNCPerceptionDebugWindow.onAction,
        variant = "selected",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PNC_PerceptionDebug_Close", "CLOSE"),
        target = self,
        onclick = ISPNCPerceptionDebugWindow.onAction,
        variant = "quiet",
    })
    self.topControls = { self.refreshButton, self.overlayButton,
        self.closeButton }

    self.settingControls = {}
    for _, definition in ipairs(Settings.GetOptionDefinitions()) do
        local checkbox = UI.CreateCheckbox(self, {
            id = definition.id,
            label = tr(OPTION_LABELS[definition.id], definition.id),
            value = definition.get(),
            target = self,
            onChange = function(owner, value, control)
                Settings.Set(control and control.internal or definition.id,
                    value, true)
                if owner and owner.syncControls then owner:syncControls() end
                if owner and owner.refreshSnapshot then
                    owner:refreshSnapshot(false)
                end
            end,
        })
        checkbox.psychopatzPreferredWidth = Layout.Pixels(220, self.uiScale)
        self.settingControls[#self.settingControls + 1] = checkbox
    end

    self.objects = UI.CreateList(self, {
        itemHeight = Layout.Pixels(43, self.uiScale),
        doDrawItem = drawObject,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(190, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.40,
    })
    self.campPreview = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(150, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.34,
    })
    self:requestResponsiveLayout(true)
    self:syncControls()
    self:refreshSnapshot(true)
end

function ISPNCPerceptionDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local top = Layout.Flow(self.topControls, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = self.uiScale, minWidth = 108 })
    local settingsY = top.bottom + Layout.Pixels(8, self.uiScale)
    local settings = Layout.Grid(self.settingControls, {
        x = rect.x, y = settingsY, width = rect.width,
    }, {
        scale = self.uiScale,
        columns = 3,
        height = 24,
        gap = 8,
        rowGap = 3,
    })
    local mainY = settings.bottom + Layout.Pixels(22, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local listWidth = math.max(Layout.Pixels(300, self.uiScale),
        math.floor(rect.width * 0.42))
    local height = math.max(Layout.Pixels(160, self.uiScale),
        rect.y + rect.height - mainY)
    local previewHeight = math.min(Layout.Pixels(170, self.uiScale),
        math.max(Layout.Pixels(90, self.uiScale), math.floor(height * 0.32)))
    local detailHeight = math.max(Layout.Pixels(70, self.uiScale),
        height - previewHeight - gap)
    self.layout = {
        objects = { x = rect.x, y = mainY, width = listWidth,
            height = height },
        details = { x = rect.x + listWidth + gap, y = mainY,
            width = rect.width - listWidth - gap, height = detailHeight },
        campPreview = { x = rect.x + listWidth + gap,
            y = mainY + detailHeight + gap,
            width = rect.width - listWidth - gap, height = previewHeight },
    }
    Layout.SetBounds(self.objects, self.layout.objects.x,
        self.layout.objects.y, self.layout.objects.width,
        self.layout.objects.height)
    Layout.SetBounds(self.details, self.layout.details.x,
        self.layout.details.y, self.layout.details.width,
        self.layout.details.height)
    Layout.SetBounds(self.campPreview, self.layout.campPreview.x,
        self.layout.campPreview.y, self.layout.campPreview.width,
        self.layout.campPreview.height)
end

function ISPNCPerceptionDebugWindow:getSelected()
    return selected(self.objects)
end

function ISPNCPerceptionDebugWindow:syncControls()
    if self.overlayButton then
        local enabled = Overlay.IsEnabled()
        self.overlayButton:setTitle(enabled
            and tr("UI_PNC_PerceptionDebug_OverlayDisable", "DISABLE OVERLAY")
            or tr("UI_PNC_PerceptionDebug_OverlayEnable", "ENABLE OVERLAY"))
        UI.SetButtonVariant(self.overlayButton,
            enabled and "danger" or "selected")
    end
    for index = 1, #(self.settingControls or {}) do
        local control = self.settingControls[index]
        if control and control.setChecked then
            control:setChecked(Settings.Get(control.internal, false))
        end
    end
end

function ISPNCPerceptionDebugWindow:refreshDetails()
    self.details:clear()
    local item = self:getSelected()
    for index, row in ipairs(Model.DetailRows(item and item.object,
        Settings.All())) do
        self.details:addItem("detail_" .. tostring(index), row)
    end
end

function ISPNCPerceptionDebugWindow:refreshCampPreview()
    self.campPreview:clear()
    if Settings.Get("showCampPreview", true) then
        for index, row in ipairs(Model.CampPreviewRows(
            self.snapshot)) do
            self.campPreview:addItem("camp_" .. tostring(index), row)
        end
    else
        self.campPreview:addItem("camp_disabled", {
            label = tr("UI_PNC_PerceptionDebug_CampPreview", "CAMP PREVIEW"),
            value = tr("UI_PNC_PerceptionDebug_Hidden", "hidden"),
        })
    end
end

function ISPNCPerceptionDebugWindow:refreshSnapshot(force)
    if force then Perception.ClearSnapshotCache() end
    local previous = self:getSelected()
    local previousID = previous and (previous.id or previous.object
        and previous.object.objectKey) or self.selectedID
    self.snapshot = Perception.GetSnapshot({
        radius = Perception.DEFAULT_RADIUS,
        maxObjects = Perception.MAX_OBJECTS,
    })
    local rows = Model.ObjectRows(self.snapshot, Settings.All())
    self.objects:clear()
    for index = 1, #rows do
        self.objects:addItem(rows[index].label, rows[index])
    end
    self.objects.selected = 0
    if previousID then
        for index, entry in ipairs(self.objects.items or {}) do
            if entry.item and tostring(entry.item.id) == tostring(previousID) then
                self.objects.selected = index
                break
            end
        end
    end
    if self.objects.selected == 0 and #self.objects.items > 0 then
        self.objects.selected = 1
    end
    local current = self:getSelected()
    self.selectedID = current and current.id or previousID
    self:refreshDetails()
    self:refreshCampPreview()
    self.lastSnapshotAt = now()
    self:syncControls()
end

function ISPNCPerceptionDebugWindow:onAction(button)
    local id = button and button.internal or ""
    if id == "refresh" then
        self:refreshSnapshot(true)
    elseif id == "overlay" then
        Overlay.Toggle()
        self:syncControls()
    elseif id == "close" then
        self:close()
    end
end

function ISPNCPerceptionDebugWindow:prerender()
    local timestamp = now()
    if timestamp - (tonumber(self.lastSnapshotAt) or 0) >= 500 then
        self:refreshSnapshot(false)
    end
    if self.objects.selected ~= self.lastSelection then
        self.lastSelection = self.objects.selected
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCPerceptionDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local summary = Model.Summary(self.snapshot)
    local suffix = trf("UI_PNC_PerceptionDebug_Summary",
        "%1 | %2 objects | %3 inspected", summary.status,
        summary.objects, summary.inspected)
    if summary.serverRequests ~= 0 then
        suffix = suffix .. trf("UI_PNC_PerceptionDebug_ServerRequests",
            " | server requests %1", summary.serverRequests)
    end
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_Objects", "OBSERVED OBJECTS"),
        self.layout.objects.x, self.layout.objects.y - Layout.Pixels(20,
            self.uiScale), self.layout.objects.width, suffix)
    local current = self:getSelected()
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_Details", "OBJECT DETAILS"),
        self.layout.details.x, self.layout.details.y - Layout.Pixels(20,
            self.uiScale), self.layout.details.width,
        current and current.label or "")
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_CampPreview", "CAMP PREVIEW"),
        self.layout.campPreview.x,
        self.layout.campPreview.y - Layout.Pixels(20, self.uiScale),
        self.layout.campPreview.width)
end

function ISPNCPerceptionDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DebugUI.instance == self then DebugUI.instance = nil end
end

function ISPNCPerceptionDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open()
    if PNC.Client and PNC.Client.CanUseDebug
        and not PNC.Client.CanUseDebug()
    then return nil end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCPerceptionDebugWindow, {
            title = tr("UI_PNC_PerceptionDebug_Title",
                "HOOMANS PERCEPTION DEBUG"),
            resizable = true,
            responsiveSpec = {
                width = 1120,
                height = 720,
                minWidth = 780,
                minHeight = 480,
                maxWidth = 1600,
                maxHeight = 1100,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshSnapshot(true)
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

DebugUI.OpenWindow = DebugUI.Open

return DebugUI
