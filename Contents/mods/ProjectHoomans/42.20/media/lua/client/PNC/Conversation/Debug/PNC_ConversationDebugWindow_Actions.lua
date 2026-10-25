-- Debug context controls and sandbox action handling.

local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal
local Model = Internal.Model

local function findGate(gates, gateType)
    for _, gate in ipairs(gates or {}) do
        if gate.type == gateType then return gate end
        local nested = findGate(gate.gates, gateType)
            or findGate(gate.gate and { gate.gate }, gateType)
        if nested then return nested end
    end
    return nil
end

local function findBlockGate(block, gateType)
    local found = findGate(block and block.gates, gateType)
    if found then return found end
    for _, node in pairs(block and block.nodes or {}) do
        found = findGate(node.gates, gateType)
        if found then return found end
        for _, choice in ipairs(node.choices or {}) do
            found = findGate(choice.gates, gateType)
            if found then return found end
            for _, outcome in ipairs(choice.outcomes or {}) do
                found = findGate(outcome.gates, gateType)
                if found then return found end
            end
        end
    end
    return nil
end

function ISPNCConversationDebugWindow:adjustGateValue(gateType, delta)
    local item = Internal.selected(self.blocks)
    local gate = findBlockGate(item and item.block, gateType) or {}
    local actor = gate.actor == "player" and "player" or "npc"
    local values
    local key
    if gateType == "pnc:skill" then
        actor = gate.actor == "npc" and "npc" or "player"
        values = self.context[actor .. "Skills"]
        key = gate.skill or "Aiming"
    else
        values = self.context[actor .. "Personality"]
        key = gate.key or gate.dimension or "bravery"
    end
    values[key] = (tonumber(values[key]) or 0) + delta
end

function ISPNCConversationDebugWindow:onAction(button)
    local id = button.internal
    local tr = Internal.tr
    if id == "refresh" then self:refreshBlocks() return end
    if id == "audience" then
        local order = { "neutral", "member", "special", "hostile" }
        local current = "neutral"
        for _, value in ipairs(order) do
            if self.context.audiences[value] then current = value end
            self.context.audiences[value] = false
        end
        local nextValue = order[1]
        for index, value in ipairs(order) do
            if value == current then nextValue = order[index % #order + 1] end
        end
        self.context.audiences[nextValue] = true
        self.context.relationshipState = nextValue == "member" and "Member"
            or nextValue == "special" and "Lover"
            or nextValue == "neutral" and "Acquaintance" or "FirstMeet"
        button:setTitle(tr("button.audience", { audience = nextValue }))
    elseif id == "time" then
        self.context.hour = (tonumber(self.context.hour) or 0) + 3
        if self.context.hour >= 24 then self.context.hour = 0 end
        button:setTitle(tr("button.hour", { hour = self.context.hour }))
    elseif id == "approval_down" or id == "approval_up" then
        self.context.relationship.approval = self.context.relationship.approval
            + (id == "approval_down" and -5 or 5)
    elseif id == "respect_down" or id == "respect_up" then
        self.context.relationship.respect = self.context.relationship.respect
            + (id == "respect_down" and -5 or 5)
    elseif id == "familiarity_down" or id == "familiarity_up" then
        self.context.relationship.familiarity = self.context.relationship.familiarity
            + (id == "familiarity_down" and -5 or 5)
    elseif id == "skill" then
        self:adjustGateValue("pnc:skill", 1)
    elseif id == "personality" then
        self:adjustGateValue("pnc:personality", 0.1)
    elseif id == "history" then
        self.context.historyEntry = self.context.historyEntry or {
            useCount = 0,
        }
        local uses = ((tonumber(self.context.historyEntry.useCount) or 0) + 1)
            % 4
        self.context.historyEntry.useCount = uses
        self.context.historyEntry.lastUsedWorldHour = uses > 0
            and self.context.worldAgeHours or nil
        self.context.historySlot = uses
        button:setTitle(tr("button.history", { uses = uses }))
    elseif id == "simulate" then
        local item = Internal.selected(self.blocks)
        if not item then return end
        local view, reason = Model.OpenSandbox(item.id, self.context)
        if not view then
            self:addField(tr("detail.label.error"), tr("sandbox.open_failed", {
                reason = tostring(reason or "unavailable"),
            }), { tone = "danger" })
        end
        return
    end
    self:refreshBlocks()
end
