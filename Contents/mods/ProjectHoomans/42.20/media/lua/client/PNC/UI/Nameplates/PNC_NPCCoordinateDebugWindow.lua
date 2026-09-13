require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.NPCCoordinateDebugUI = PNC.NPCCoordinateDebugUI or {}

local Inspector = PNC.NPCCoordinateDebugUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Anchor = PNC.NameplateFirearmAnchor

local function text(value)
    return tostring(value == nil and "-" or value)
end

local function number(value)
    return value == nil and "-" or string.format("%.1f", tonumber(value) or 0)
end

local function pair(x, y)
    return number(x) .. ", " .. number(y)
end

local function triplet(x, y, z)
    return pair(x, y) .. ", " .. number(z)
end

local function drawRow(window, x, y, label, value, color)
    local labelColor = Theme.colors.textMuted
    local valueColor = color or Theme.colors.text
    window:drawText(
        label,
        x,
        y,
        labelColor.r,
        labelColor.g,
        labelColor.b,
        labelColor.a,
        UIFont.Small
    )
    window:drawText(
        value,
        x + 142,
        y,
        valueColor.r,
        valueColor.g,
        valueColor.b,
        valueColor.a,
        UIFont.Small
    )
end

ISPNCNPCCoordinateDebugWindow = PsychopatzWindow:derive(
    "ISPNCNPCCoordinateDebugWindow")

function ISPNCNPCCoordinateDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCNPCCoordinateDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.step = 1
    self.buttons = {}
    for _, definition in ipairs({
        { "xMinus", "< X", "quiet", 72 },
        { "xPlus", "X >", "quiet", 72 },
        { "yMinus", "^ Y", "quiet", 72 },
        { "yPlus", "Y v", "quiet", 72 },
        { "sideMinus", "< SIDE", "quiet", 82 },
        { "sidePlus", "SIDE >", "quiet", 82 },
        { "flipSide", "FLIP SIDE", "warning", 92 },
        { "stepMinus", "STEP -", "quiet", 78 },
        { "stepPlus", "STEP +", "quiet", 78 },
        { "simulation", "START FIRE", "success", 104 },
        { "probe", "PROBE", "selected", 78 },
        { "reset", "RESET OFFSET", "danger", 108 },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            width = definition[4],
            variant = definition[3],
            target = self,
            onclick = ISPNCNPCCoordinateDebugWindow.onAction,
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:requestResponsiveLayout(true)
end

function ISPNCNPCCoordinateDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 32, bottom = 12 })
    local flow = Layout.Flow(self.buttons, {
        x = rect.x,
        y = rect.y,
        width = rect.width,
    }, {
        scale = self.uiScale,
        minWidth = 70,
        height = 27,
        gap = 6,
        rowGap = 6,
    })
    self.layout = {
        info = {
            x = rect.x,
            y = flow.bottom + 18,
            width = rect.width,
            height = math.max(220, rect.height - (flow.bottom - rect.y) - 18),
        },
    }
end

function ISPNCNPCCoordinateDebugWindow:setTarget(body, npcID, playerIndex)
    local effects = PNC.ClientFirearmEffects
    if effects and effects.IsSimulationActive
        and effects.IsSimulationActive(self.body, self.npcID)
        and (self.body ~= body or tostring(self.npcID or "") ~= tostring(npcID or ""))
    then
        if effects.StopSimulation then effects.StopSimulation() end
    end
    self.body = body
    self.npcID = npcID
    self.playerIndex = tonumber(playerIndex) or 0
    if Anchor and Anchor.SetTarget then
        Anchor.SetTarget(body, npcID, self.playerIndex)
    end
    self:refreshControls()
end

function ISPNCNPCCoordinateDebugWindow:refreshControls()
    local effects = PNC.ClientFirearmEffects
    local simulationActive = effects and effects.IsSimulationActive
        and effects.IsSimulationActive(self.body, self.npcID) or false
    local probeActive = Anchor and Anchor.IsTarget
        and Anchor.IsTarget(self.body, self.npcID) or false
    if self.simulationButton then
        self.simulationButton:setTitle(
            simulationActive and "STOP FIRE" or "START FIRE")
        UI.SetButtonVariant(self.simulationButton,
            simulationActive and "danger" or "success")
    end
    if self.probeButton then
        self.probeButton:setTitle(probeActive and "PROBE ON" or "PROBE")
        UI.SetButtonVariant(self.probeButton,
            probeActive and "selected" or "quiet")
    end
end

function ISPNCNPCCoordinateDebugWindow:onAction(button)
    local id = button and button.internal or ""
    local step = tonumber(self.step) or 1
    local effects
    if id == "xMinus" then
        Anchor.AdjustOffset("x", -step)
    elseif id == "xPlus" then
        Anchor.AdjustOffset("x", step)
    elseif id == "yMinus" then
        Anchor.AdjustOffset("y", -step)
    elseif id == "yPlus" then
        Anchor.AdjustOffset("y", step)
    elseif id == "sideMinus" then
        Anchor.AdjustOffset("side", -step)
    elseif id == "sidePlus" then
        Anchor.AdjustOffset("side", step)
    elseif id == "flipSide" then
        Anchor.FlipSide()
    elseif id == "stepMinus" then
        self.step = math.max(0.5, step - 0.5)
    elseif id == "stepPlus" then
        self.step = math.min(20, step + 0.5)
    elseif id == "simulation" then
        effects = PNC.ClientFirearmEffects
        if Anchor and Anchor.SetTarget then
            Anchor.SetTarget(self.body, self.npcID, self.playerIndex)
        end
        if effects and effects.ToggleSimulation then
            effects.ToggleSimulation(self.body, self.npcID, self.playerIndex)
        end
    elseif id == "probe" then
        Anchor.ToggleTarget(self.body, self.npcID, self.playerIndex)
    elseif id == "reset" then
        Anchor.ResetOffsets()
    end
    self:refreshControls()
end

function ISPNCNPCCoordinateDebugWindow:prerender()
    self:refreshControls()
    PsychopatzWindow.prerender(self)
end

function ISPNCNPCCoordinateDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local state = Anchor.GetDebugState(self.body, self.npcID)
    local info = self.layout.info
    local leftX = info.x + 10
    local rightX = info.x + math.floor(info.width * 0.52)
    local rowY = info.y + 34
    local gap = 23
    local statusColor = state.status == "LIVE"
        and Theme.colors.success or Theme.colors.warning
    local effects = PNC.ClientFirearmEffects
    local simulationActive = effects and effects.IsSimulationActive
        and effects.IsSimulationActive(self.body, self.npcID) or false
    UI.DrawSurface(self, info.x, info.y, info.width, info.height, false, 0.82)
    UI.DrawSectionTitle(self, "LIVE NPC COORDINATES", info.x + 8,
        info.y + 8, info.width - 16)

    drawRow(self, leftX, rowY, "Target ID", text(state.id or self.npcID))
    drawRow(self, leftX, rowY + gap, "Cache", text(state.status)
        .. " / " .. number(state.cacheAgeMs) .. " ms", statusColor)
    drawRow(self, leftX, rowY + gap * 2, "World", triplet(
        state.worldX, state.worldY, state.worldZ))
    drawRow(self, leftX, rowY + gap * 3, "Nameplate", pair(
        state.nameplateX, state.nameplateY))
    drawRow(self, leftX, rowY + gap * 4, "Ground", pair(
        state.groundX, state.groundY))
    drawRow(self, leftX, rowY + gap * 5, "Launch local", pair(
        state.launchX, state.launchY), Theme.colors.warning)
    drawRow(self, leftX, rowY + gap * 6, "Render screen", pair(
        state.renderX, state.renderY), Theme.colors.accent)

    drawRow(self, rightX, rowY, "Total offset px", pair(
        state.offsetX, state.offsetY), Theme.colors.warning)
    drawRow(self, rightX, rowY + gap, "Base offset px", pair(
        state.baseOffsetX, state.baseOffsetY))
    drawRow(self, rightX, rowY + gap * 2, "Side delta px", pair(
        state.sideOffsetX, state.sideOffsetY))
    drawRow(self, rightX, rowY + gap * 3, "Side vector", pair(
        state.sideScreenX, state.sideScreenY))
    drawRow(self, rightX, rowY + gap * 4, "Manager", pair(
        state.managerX, state.managerY))
    drawRow(self, rightX, rowY + gap * 5, "Zoom", number(state.zoom))
    drawRow(self, rightX, rowY + gap * 6, "Simulation",
        simulationActive and "RUNNING" or "STOPPED",
        simulationActive and Theme.colors.danger or Theme.colors.textMuted)

    self:drawText(
        "Arrows adjust direct X/Y pixels. SIDE adjusts the facing-relative hand offset.",
        info.x + 10,
        info.y + info.height - 42,
        Theme.colors.textMuted.r,
        Theme.colors.textMuted.g,
        Theme.colors.textMuted.b,
        Theme.colors.textMuted.a,
        UIFont.Small
    )
    self:drawText(
        "Step: " .. number(self.step) .. " px    Side sign: "
            .. text(state.config and state.config.sideSign),
        info.x + 10,
        info.y + info.height - 22,
        Theme.colors.text.r,
        Theme.colors.text.g,
        Theme.colors.text.b,
        Theme.colors.text.a,
        UIFont.Small
    )
end

function ISPNCNPCCoordinateDebugWindow:close()
    local effects = PNC.ClientFirearmEffects
    if effects and effects.StopSimulation then effects.StopSimulation() end
    if Anchor and Anchor.ClearTarget then Anchor.ClearTarget() end
    self:setVisible(false)
    self:removeFromUIManager()
    Inspector.instance = nil
end

function ISPNCNPCCoordinateDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function Inspector.Open(body, npcID, playerIndex)
    local window
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
        or not body
    then
        return nil
    end
    window = Inspector.instance
    if not window then
        window = UI.NewWindow(ISPNCNPCCoordinateDebugWindow, {
            title = "NPC COORDINATE INSPECTOR",
            resizable = true,
            persistenceKey = "PNC.NPCCoordinateDebugUI",
            responsiveSpec = {
                width = 780,
                height = 500,
                minWidth = 680,
                minHeight = 430,
                maxWidth = 1200,
                maxHeight = 820,
            },
        })
        window:initialise()
        window:instantiate()
        Inspector.instance = window
    end
    window:setTarget(body, npcID, playerIndex)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    return window
end

function Inspector.Toggle(body, npcID, playerIndex)
    if Inspector.instance and Inspector.instance:getIsVisible() then
        Inspector.instance:close()
        return false
    end
    return Inspector.Open(body, npcID, playerIndex) ~= nil
end

local function onResetLua()
    if Inspector.instance then Inspector.instance:close() end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

return Inspector
