require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/NPCPresentationDebug/PNC_NPCPresentationDebug_HeldItem"

PNC = PNC or {}
PNC.NPCPresentationDebugTabs = PNC.NPCPresentationDebugTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local addDetail = UI.AddKeyValue
local Holder = PNC.NPCPresentationHeldItem

local function makeLabel(parent, value, colorName)
    local color = Theme.colors[colorName or "text"] or Theme.colors.text
    local label = ISLabel:new(0, 0, 20, tostring(value or ""),
        color.r, color.g, color.b, color.a, UIFont.Small, true)
    label:initialise()
    label.psychopatzThemeColorName = colorName or "text"
    parent:addChild(label)
    return label
end

local function setLabel(label, value)
    if label then UI.SetLabelText(label, value) end
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

local function modeLabel(mode)
    mode = tostring(mode or "auto")
    if mode == "action_prop" then return "ACTION PROP" end
    return string.upper(mode)
end

ISPNCNPCPresentationDebugHoldItemTab = ISPanel:derive(
    "ISPNCNPCPresentationDebugHoldItemTab")

function ISPNCNPCPresentationDebugHoldItemTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCNPCPresentationDebugHoldItemTab:createChildren()
    ISPanel.createChildren(self)
    self.itemLabel = makeLabel(self, "ITEM FULL TYPE", "textMuted")
    self.itemEntry = UI.CreateTextEntry(self, {
        text = Holder.GetRequestedType(),
        width = 360,
        height = 27,
        maxTextLength = 160,
        tooltip = "Example: Base.Apple or Base.DoubleBarrelShotgun",
        onTextChange = function()
            Holder.SetRequestedType(self.itemEntry:getText())
            self:refreshDetails(true)
        end,
    })
    self.applyButton = UI.CreateButton(self, {
        id = "apply",
        title = "APPLY ITEM TYPE",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.toggleButton = UI.CreateButton(self, {
        id = "toggle",
        title = "HOLD ITEM: OFF",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.restoreButton = UI.CreateButton(self, {
        id = "restore",
        title = "RESTORE ORIGINAL",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "danger",
    })
    self.defaultButton = UI.CreateButton(self, {
        id = "default",
        title = "USE DEFAULT SHOTGUN",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "selected",
    })
    self.modeButton = UI.CreateButton(self, {
        id = "mode",
        title = "MODE: AUTO",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.handButton = UI.CreateButton(self, {
        id = "hand",
        title = "HAND: AUTO",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCNPCPresentationDebugHoldItemTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.statusLabel = makeLabel(self, "", "textMuted")
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 27,
        valueXMax = 260,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        labelColor = { r = 0.62, g = 0.72, b = 0.80, a = 1 },
        valueColor = { r = 0.92, g = 0.92, b = 0.92, a = 1 },
        warningColor = { r = 1.0, g = 0.56, b = 0.30, a = 1 },
        alternateColor = { r = 0.16, g = 0.18, b = 0.20, a = 1 },
        alternateAlpha = 0.12,
        drawSelection = false,
    })
end

function ISPNCNPCPresentationDebugHoldItemTab:setContext(hub)
    self.hub = hub
    self:refreshDetails(true)
end

function ISPNCNPCPresentationDebugHoldItemTab:refreshDetails(force)
    if not self.details then return end
    local hub = self.hub
    local state = Holder.GetState(hub and hub.body or nil, hub and hub.npcId or nil)
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force and now < (tonumber(self.nextRefreshAt) or 0) then return end
    self.nextRefreshAt = now + 150
    self.details:clear()
    addDetail(self.details, "Requested full type", state.requestedType)
    addDetail(self.details, "Requested mode", state.requestedMode)
    addDetail(self.details, "Requested hand", state.requestedHand)
    addDetail(self.details, "Toggle", state.status, state.enabled)
    addDetail(self.details, "Active mode", state.mode or "-")
    addDetail(self.details, "Presentation full type", state.fullType or "-")
    addDetail(self.details, "Persistent primary", state.persistentPrimary or "-")
    addDetail(self.details, "Persistent secondary", state.persistentSecondary or "-")
    addDetail(self.details, "Action primary", state.actionPrimary or "-")
    addDetail(self.details, "Action secondary", state.actionSecondary or "-")
    addDetail(self.details, "Action hand", state.actionHand or "-")
    addDetail(self.details, "Action override", state.actionOverride and "ON" or "OFF")
    addDetail(self.details, "Action class", state.actionClass or "-")
    addDetail(self.details, "Static model", state.staticModel ~= "" and state.staticModel or "NONE")
    addDetail(self.details, "Presentation type", state.primaryType or "-")
    addDetail(self.details, "Last result", state.lastResult
        and tostring(state.lastResult.ok) .. " / "
            .. tostring(state.lastResult.reason) or "-")
    setLabel(self.statusLabel, state.enabled
        and (state.mode == "action_prop"
            and "Action prop is attached through the engine timed-action hand-model path."
            or "Equipment mode is active; the item occupies the NPC's persistent hand state.")
        or "No temporary item is active. The NPC's original hand state is unchanged.")
end

function ISPNCNPCPresentationDebugHoldItemTab:onAction(button)
    local id = button and button.internal or ""
    local hub = self.hub
    local body = hub and hub:resolveBody() or nil
    local fullType
    if id == "default" then
        fullType = Holder.DefaultItem()
        if self.itemEntry and self.itemEntry.setText then
            self.itemEntry:setText(fullType)
        end
        Holder.SetRequestedType(fullType)
    elseif id == "apply" then
        fullType = self.itemEntry and self.itemEntry:getText() or nil
        Holder.SetRequestedType(fullType)
        if Holder.IsActive(body, hub and hub.npcId or nil) then
            Holder.Reapply()
        end
    elseif id == "toggle" then
        fullType = self.itemEntry and self.itemEntry:getText() or nil
        Holder.Toggle(body, hub and hub.npcId or nil,
            hub and hub.playerIndex or 0, fullType)
    elseif id == "mode" then
        Holder.CycleMode()
        if Holder.IsActive(body, hub and hub.npcId or nil) then
            Holder.Reapply()
        end
    elseif id == "hand" then
        Holder.CycleHand()
        if Holder.IsActive(body, hub and hub.npcId or nil) then
            Holder.Reapply()
        end
    elseif id == "restore" then
        Holder.Disable("manual_restore")
    end
    self:refreshDetails(true)
end

function ISPNCNPCPresentationDebugHoldItemTab:refreshControls()
    local hub = self.hub
    local body = hub and hub:resolveBody() or nil
    local state = Holder.GetState(body, hub and hub.npcId or nil)
    setButtonState(self.toggleButton,
        state.enabled and "HOLD ITEM: ON" or "HOLD ITEM: OFF",
        state.enabled and "selected" or "quiet")
    setButtonState(self.modeButton,
        "MODE: " .. modeLabel(state.requestedMode),
        state.requestedMode == "auto" and "quiet" or "selected")
    setButtonState(self.handButton,
        "HAND: " .. string.upper(tostring(state.requestedHand or "auto")),
        state.requestedHand == "auto" and "quiet" or "selected")
    if self.toggleButton then self.toggleButton:setEnable(body ~= nil) end
    if self.restoreButton then
        self.restoreButton:setEnable(state.enabled)
    end
end

function ISPNCNPCPresentationDebugHoldItemTab:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local rowY = margin
    Layout.SetBounds(self.itemLabel, margin, rowY + 5, 120, 20)
    Layout.SetBounds(self.itemEntry, margin + 128, rowY, math.min(430,
        math.max(240, width - margin * 2 - 128)), 27)
    rowY = rowY + 38
    local buttonWidth = math.max(112, math.floor((width - margin * 2 - 16) / 3))
    local buttons = { self.modeButton, self.handButton, self.defaultButton }
    for index, button in ipairs(buttons) do
        Layout.SetBounds(button, margin + (index - 1) * (buttonWidth + 8),
            rowY, buttonWidth, 27)
    end
    rowY = rowY + 35
    buttons = { self.applyButton, self.toggleButton, self.restoreButton }
    for index, button in ipairs(buttons) do
        Layout.SetBounds(button, margin + (index - 1) * (buttonWidth + 8),
            rowY, buttonWidth, 27)
    end
    rowY = rowY + 42
    Layout.SetBounds(self.statusLabel, margin, rowY,
        math.max(240, width - margin * 2), 30)
    Layout.SetBounds(self.details, margin, rowY + 42,
        math.max(240, width - margin * 2),
        math.max(150, height - rowY - 54))
end

function ISPNCNPCPresentationDebugHoldItemTab:prerender()
    self:refreshControls()
    self:refreshDetails(false)
    ISPanel.prerender(self)
end

function ISPNCNPCPresentationDebugHoldItemTab:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ISPNCNPCPresentationDebugHoldItemTab
