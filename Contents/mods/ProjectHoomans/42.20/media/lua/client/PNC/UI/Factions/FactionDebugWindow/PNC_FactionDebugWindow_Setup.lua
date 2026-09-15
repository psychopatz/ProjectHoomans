-- Faction debug window widget construction.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local UI = Internal.UI
local Layout = Internal.Layout
local CONTROLS = Internal.Controls
local text = Internal.Text
local drawEntity = Internal.DrawEntity
local drawMobileEntity = Internal.DrawMobileEntity
function ISPNCFactionDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFactionDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.factions = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.mobileGroups = UI.CreateList(self, {
        itemHeight = Layout.Pixels(52, self.uiScale),
        doDrawItem = drawMobileEntity,
    })
    self.targets = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.npcs = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        labelX = 10,
        labelY = 6,
        valueY = 6,
        labelWidth = 150,
        labelWidthRatio = 0.34,
        valueXOffset = 2,
        valueRightPadding = 12,
        valueMinimumWidth = 40,
    })
    self.dashboard = PNC.FactionDebugOverlay.NewDashboard(
        0, 0, 430, 492
    )
    self:addChild(self.dashboard)
    self.controls = {}
    self.scenarioIndex = 1
    self.groupSize = 4
    self.presenceMode = "auto"
    self.mobilePathMode = "random"
    self.mobileControlMode = "ambient"
    self.mobileFilter = "all"
    self.viewMode = "overview"
    for _, definition in ipairs(CONTROLS) do
        local title = text(definition.titleKey)
        if definition.id == "presence_mode" then
            title = title .. ": " .. self.presenceMode
        elseif definition.id == "mobile_path_mode" then
            title = title .. ": " .. self.mobilePathMode
        elseif definition.id == "mobile_control_mode" then
            title = title .. ": " .. self.mobileControlMode
        end
        local button = UI.CreateButton(self, {
            id = definition.id,
            title = title,
            target = self,
            onclick = ISPNCFactionDebugWindow.onAction,
            variant = definition.variant,
        })
        self.controls[#self.controls + 1] = button
    end
    self.groupSizeEntry = UI.CreateTextEntry(self, {
        text = tostring(self.groupSize),
        width = 64,
        height = 26,
        onlyNumbers = true,
        preferredWidth = 64,
        tooltip = text("UI_PNC_FactionGroupSizeTooltip"),
    })
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end
