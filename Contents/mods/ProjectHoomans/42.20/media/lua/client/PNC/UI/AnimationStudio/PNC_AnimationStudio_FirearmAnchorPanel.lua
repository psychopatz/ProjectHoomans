require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Nameplates/PNC_NameplateFirearmAnchor"

PNC = PNC or {}
PNC.NPCPresentationDebugTabs = PNC.NPCPresentationDebugTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue
local Anchor = PNC.NameplateFirearmAnchor

local function firearmEffects()
    if not PNC.ClientFirearmEffects and require then
        pcall(require, "PNC/PNC_ClientFirearmEffects")
    end
    return PNC.ClientFirearmEffects
end

local function number(value)
    value = tonumber(value)
    return value and string.format("%.1f", value) or "-"
end

local function pair(x, y)
    return number(x) .. ", " .. number(y)
end

local function triplet(x, y, z)
    return pair(x, y) .. ", " .. number(z)
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

ISPNCNPCPresentationDebugAnchorTab = ISPanel:derive(
    "ISPNCNPCPresentationDebugAnchorTab")

function ISPNCNPCPresentationDebugAnchorTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCNPCPresentationDebugAnchorTab:createChildren()
    ISPanel.createChildren(self)
    self.step = 2.0
    self.buttons = {}
    local definitions = {
        { "probe", "ANCHOR PROBE: OFF", "quiet" },
        { "text", "ANCHOR TEXT: ON", "quiet" },
        { "fire", "FIRE SIM: OFF", "quiet" },
        { "forwardMinus", "< FWD", "quiet" },
        { "forwardPlus", "FWD >", "quiet" },
        { "heightMinus", "^ HEIGHT", "quiet" },
        { "heightPlus", "HEIGHT v", "quiet" },
        { "sideMinus", "SIDE -", "quiet" },
        { "sidePlus", "SIDE +", "quiet" },
        { "flipSide", "FLIP SIDE", "warning" },
        { "stepMinus", "STEP -", "quiet" },
        { "stepPlus", "STEP +", "quiet" },
        { "reset", "RESET RELATIVE", "danger" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(button)
                return ISPNCNPCPresentationDebugAnchorTab.onAction(self, button)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
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

function ISPNCNPCPresentationDebugAnchorTab:setContext(hub)
    self.hub = hub
    self:refreshDetails(true)
end

function ISPNCNPCPresentationDebugAnchorTab:resolveBody()
    return self.hub and self.hub:resolveBody() or nil
end

function ISPNCNPCPresentationDebugAnchorTab:refreshDetails(force)
    if not self.details then return end
    local hub = self.hub
    local body = self:resolveBody()
    local id = hub and hub.npcId or nil
    local effects = firearmEffects()
    local state = Anchor and Anchor.GetDebugState
        and Anchor.GetDebugState(body, id) or nil
    local sim = effects and effects.IsSimulationActive
        and effects.IsSimulationActive(body, id) or false
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force and now < (tonumber(self.nextRefreshAt) or 0) then return end
    self.nextRefreshAt = now + 120
    self.details:clear()
    addDetail(self.details, "Target", tostring(id or "-"))
    if not state or state.status == "MISSING" then
        addDetail(self.details, "Anchor cache", "MISSING", true)
        addDetail(self.details, "Instruction",
            "Enable the probe and keep the NPC visible to cache its nameplate.",
            true)
    else
        addDetail(self.details, "Anchor cache",
            tostring(state.status) .. " / age " .. number(state.cacheAgeMs) .. " ms",
            state.status ~= "LIVE")
        addDetail(self.details, "Nameplate screen",
            pair(state.nameplateX, state.nameplateY))
        addDetail(self.details, "Launch screen",
            pair(state.renderX, state.renderY))
        addDetail(self.details, "Local F / S / H",
            number(state.localForward) .. " / " .. number(state.localSide)
                .. " / " .. number(state.localHeight))
        addDetail(self.details, "Facing world",
            pair(state.facingX, state.facingY))
        addDetail(self.details, "Forward screen basis",
            pair(state.forwardScreenX, state.forwardScreenY))
        addDetail(self.details, "Side screen basis",
            pair(state.sideScreenX, state.sideScreenY))
        addDetail(self.details, "Height screen basis",
            pair(state.heightScreenX, state.heightScreenY))
        addDetail(self.details, "Resolved offset px",
            pair(state.offsetX, state.offsetY))
        addDetail(self.details, "World body",
            triplet(state.worldX, state.worldY, state.worldZ))
        addDetail(self.details, "Anchor source", state.source or "-")
    end
    addDetail(self.details, "Fire simulation", sim and "RUNNING" or "STOPPED")
    addDetail(self.details, "Debug text", Anchor.IsDebugTextVisible()
        and "VISIBLE" or "HIDDEN")
    addDetail(self.details, "Step px", number(self.step))
end

function ISPNCNPCPresentationDebugAnchorTab:onAction(button)
    local id = button and button.internal or ""
    local hub = self.hub
    local body = self:resolveBody()
    local step = tonumber(self.step) or 2.0
    local effects
    if id == "stepMinus" then
        self.step = math.max(0.5, step - 0.5)
    elseif id == "stepPlus" then
        self.step = math.min(20, step + 0.5)
    elseif id == "reset" then
        Anchor.ResetOffsets()
    elseif id == "forwardMinus" then
        Anchor.AdjustOffset("x", -step)
    elseif id == "forwardPlus" then
        Anchor.AdjustOffset("x", step)
    elseif id == "heightMinus" then
        Anchor.AdjustOffset("y", -step)
    elseif id == "heightPlus" then
        Anchor.AdjustOffset("y", step)
    elseif id == "sideMinus" then
        Anchor.AdjustOffset("side", -step)
    elseif id == "sidePlus" then
        Anchor.AdjustOffset("side", step)
    elseif id == "flipSide" then
        Anchor.FlipSide()
    elseif id == "text" then
        Anchor.ToggleDebugText()
    elseif id == "probe" then
        if body then Anchor.ToggleTarget(body, hub.npcId, hub.playerIndex) end
    elseif id == "fire" then
        effects = firearmEffects()
        if body then
            Anchor.SetTarget(body, hub.npcId, hub.playerIndex)
            if effects and effects.ToggleSimulation then
                effects.ToggleSimulation(body, hub.npcId, hub.playerIndex)
            end
        end
    end
    self:refreshDetails(true)
end

function ISPNCNPCPresentationDebugAnchorTab:refreshControls()
    local hub = self.hub
    local body = self:resolveBody()
    local effects = firearmEffects()
    local sim = effects and effects.IsSimulationActive
        and effects.IsSimulationActive(body, hub and hub.npcId or nil) or false
    local probe = Anchor.IsTarget(body, hub and hub.npcId or nil)
    local visible = Anchor.IsDebugTextVisible()
    setButtonState(self.probeButton,
        probe and "ANCHOR PROBE: ON" or "ANCHOR PROBE: OFF",
        probe and "selected" or "quiet")
    setButtonState(self.textButton,
        visible and "ANCHOR TEXT: ON" or "ANCHOR TEXT: OFF",
        visible and "quiet" or "selected")
    setButtonState(self.fireButton,
        sim and "FIRE SIM: ON" or "FIRE SIM: OFF",
        sim and "danger" or "quiet")
    if self.probeButton then self.probeButton:setEnable(body ~= nil) end
    if self.fireButton then self.fireButton:setEnable(body ~= nil and effects ~= nil) end
end

function ISPNCNPCPresentationDebugAnchorTab:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local buttonWidth = math.max(92,
        math.floor((width - margin * 2 - 36) / 4))
    local buttonsTop = margin
    for index, button in ipairs(self.buttons) do
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        Layout.SetBounds(button, margin + column * (buttonWidth + 8),
            buttonsTop + row * 35, buttonWidth, 27)
    end
    local buttonRows = math.ceil(#self.buttons / 4)
    local detailsTop = buttonsTop + buttonRows * 35 + 8
    Layout.SetBounds(self.details, margin, detailsTop,
        math.max(240, width - margin * 2),
        math.max(160, height - detailsTop - margin))
end

function ISPNCNPCPresentationDebugAnchorTab:prerender()
    self:refreshControls()
    self:refreshDetails(false)
    ISPanel.prerender(self)
end

function ISPNCNPCPresentationDebugAnchorTab:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ISPNCNPCPresentationDebugAnchorTab
