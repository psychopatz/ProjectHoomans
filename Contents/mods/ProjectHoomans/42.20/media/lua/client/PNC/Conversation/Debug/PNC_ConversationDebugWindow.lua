require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "ISUI/ISTextEntryBox"
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel"

PNC.ConversationDebugUI = PNC.ConversationDebugUI or {}
local DebugUI = PNC.ConversationDebugUI
local Model = PNC.ConversationDebugModel
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local DEBUG_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/debugger.json",
    domain = "pnc.system.shared.debugger",
}

local function tr(key, args)
    PNC.Conversation.TextLoader.EnsureSource(DEBUG_SOURCE, { key })
    return PsychopatzCore.Conversation.Text.Resolve({
        key = key, domain = DEBUG_SOURCE.domain, args = args,
    })
end

DebugUI.Text = tr

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawBlock(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local color = item.valid and Theme.colors.text or Theme.colors.danger
    list:drawText(Layout.Ellipsize(item.id, UIFont.Small,
        list:getWidth() - 16), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    local detail = table.concat({
        item.block.category or "?",
        table.concat(item.block.audiences or {}, ","),
        item.translationFallback and tr("status.text_fallback")
            or item.translationValid and tr("status.text_ok")
            or tr("status.text_missing"),
        item.eligible and tr("status.eligible")
            or tostring(item.eligibilityReason or tr("status.unknown")),
    }, " | ")
    list:drawText(Layout.Ellipsize(detail, UIFont.Small,
        list:getWidth() - 16), 8, y + 24,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function booleanText(value)
    if value == true then return tr("status.yes") end
    if value == false then return tr("status.no") end
    return tr("status.unknown")
end

local function statusTone(value)
    return value == true and "success" or value == false and "danger" or "warning"
end

local function textValue(value)
    if value == nil or value == "" then return "-" end
    return tostring(value)
end

ISPNCConversationDebugWindow =
    PsychopatzWindow:derive("ISPNCConversationDebugWindow")

function ISPNCConversationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCConversationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.context = Model.DefaultContext()
    self.search = ISTextEntryBox:new("", 0, 0, 260, 26)
    self.search:initialise()
    self.search:instantiate()
    self:addChild(self.search)
    self.blocks = UI.CreateList(self, { itemHeight = 44, doDrawItem = drawBlock })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 24,
        labelX = 8,
        valueX = 178,
        valueRightPadding = 8,
    })
    self.controls = {}
    local actions = {
        { id = "refresh", title = tr("button.refresh") },
        { id = "audience", title = tr("button.audience", { audience = "neutral" }) },
        { id = "time", title = tr("button.hour", { hour = 12 }) },
        { id = "approval_down", title = tr("button.approval_down") },
        { id = "approval_up", title = tr("button.approval_up") },
        { id = "respect_down", title = tr("button.respect_down") },
        { id = "respect_up", title = tr("button.respect_up") },
        { id = "familiarity_down", title = tr("button.familiarity_down") },
        { id = "familiarity_up", title = tr("button.familiarity_up") },
        { id = "skill", title = tr("button.skill") },
        { id = "personality", title = tr("button.personality") },
        { id = "history", title = tr("button.history", { uses = 0 }) },
        { id = "simulate", title = tr("button.simulate"), variant = "success" },
    }
    for _, action in ipairs(actions) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = action.id,
            title = action.title,
            target = self,
            onclick = ISPNCConversationDebugWindow.onAction,
            variant = action.variant or "quiet",
        })
    end
    self:requestResponsiveLayout(true)
    self:refreshBlocks()
end

function ISPNCConversationDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 10 })
    Layout.SetBounds(self.search, rect.x, rect.y, math.min(340, rect.width), 26)
    local flow = Layout.Flow(self.controls, {
        x = rect.x, y = rect.y + 34, width = rect.width,
    }, { scale = self.uiScale, minWidth = 105 })
    local top = flow.bottom + 26
    local gap = 8
    local left = math.floor(rect.width * 0.43)
    Layout.SetBounds(self.blocks, rect.x, top, left,
        rect.height - (top - rect.y))
    Layout.SetBounds(self.details, rect.x + left + gap, top,
        rect.width - left - gap, rect.height - (top - rect.y))
end

function ISPNCConversationDebugWindow:addField(label, value, options)
    UI.AddKeyValue(self.details, label, textValue(value), options)
end

function ISPNCConversationDebugWindow:refreshBlocks()
    local old = selected(self.blocks)
    local query = self.search and self.search:getText() or ""
    self.blocks:clear()
    for _, item in ipairs(Model.List({ query = query }, self.context)) do
        self.blocks:addItem(item.id, item)
    end
    for index, entry in ipairs(self.blocks.items or {}) do
        if old and old.id == entry.item.id then self.blocks.selected = index end
    end
    if (self.blocks.selected or 0) < 1 and #self.blocks.items > 0 then
        self.blocks.selected = 1
    end
    self:refreshDetails()
end

function ISPNCConversationDebugWindow:refreshDetails(sandbox)
    self.details:clear()
    local item = selected(self.blocks)
    if not item then return end
    local inspection = Model.Inspect(item.id, self.context)
    self:addField(tr("detail.label.id"), item.id)
    self:addField(tr("detail.label.owner"), item.block.ownerModID)
    self:addField(tr("detail.label.category"), item.block.category)
    self:addField(tr("detail.label.source"), item.block.textSource.pathPattern)
    self:addField(tr("detail.label.registry"), booleanText(item.valid), {
        tone = statusTone(item.valid),
    })
    self:addField(tr("detail.label.translation"), booleanText(item.translationValid), {
        tone = statusTone(item.translationValid),
    })
    self:addField(tr("detail.label.fallback"), booleanText(item.translationFallback), {
        tone = item.translationFallback and "warning" or "text",
    })
    local eligible = inspection and inspection.eligible == true
    self:addField(tr("detail.label.eligibility"), booleanText(eligible), {
        tone = statusTone(eligible),
    })
    if inspection and inspection.reason then
        self:addField(tr("detail.label.reason"), inspection.reason, {
            tone = "warning",
        })
    end
    self:addField(tr("detail.label.seed"), inspection and inspection.seed)
    for _, errorValue in ipairs(item.errors or {}) do
        self:addField(tr("detail.label.error"), errorValue, { tone = "danger" })
    end
    for _, errorValue in ipairs(item.translationErrors or {}) do
        self:addField(tr("detail.label.text_error"), errorValue, { tone = "danger" })
    end
    local nodes = inspection and inspection.nodes or {}
    table.sort(nodes, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    for _, node in ipairs(nodes) do
        self:addField(tr("detail.label.node"), node.id, { tone = "accent" })
        self:addField(tr("detail.label.node_text"),
            node.textKey or table.concat(node.textKeys or {}, ","))
        for _, choice in ipairs(node.choices or {}) do
            local choiceEligible = choice.eligible == true
            self:addField(tr("detail.label.choice"), choice.id, {
                tone = "accent",
            })
            self:addField(tr("detail.label.choice_status"), booleanText(choiceEligible), {
                tone = statusTone(choiceEligible),
            })
            if choice.reason then
                self:addField(tr("detail.label.reason"), choice.reason, {
                    tone = "warning",
                })
            end
            for _, outcome in ipairs(choice.outcomes or {}) do
                local outcomeEligible = outcome.eligible == true
                self:addField(tr("detail.label.outcome"), outcome.id, {
                    tone = "accent",
                })
                self:addField(tr("detail.label.outcome_status"),
                    booleanText(outcomeEligible), {
                        tone = statusTone(outcomeEligible),
                    })
                self:addField(tr("detail.label.weight"), outcome.weight)
                self:addField(tr("detail.label.next"),
                    outcome.next or outcome.close and "close" or "none")
                self:addField(tr("detail.label.response"), outcome.responseKey)
                if outcome.reason then
                    self:addField(tr("detail.label.reason"), outcome.reason, {
                        tone = "warning",
                    })
                end
                for _, effect in ipairs(outcome.effects or {}) do
                    self:addField(tr("detail.label.effect"), effect.type, {
                        tone = "success",
                    })
                end
            end
        end
    end
    if sandbox then
        self:addField(tr("detail.label.sandbox_outcome"), sandbox.outcomeID, {
            tone = "success",
        })
        self:addField(tr("detail.label.sandbox_roll"), table.concat({
            textValue(sandbox.roll), textValue(sandbox.totalWeight),
        }, " / "))
        local axes = {}
        for key in pairs(sandbox.after.relationship or {}) do
            axes[#axes + 1] = key
        end
        table.sort(axes)
        for _, key in ipairs(axes) do
            self:addField(tr("detail.label.relationship"), key)
            self:addField(tr("detail.label.before_after"), table.concat({
                textValue(sandbox.before.relationship[key]),
                textValue(sandbox.after.relationship[key]),
            }, " -> "))
        end
        self:addField(tr("detail.label.persistence"), tr("status.no"), {
            tone = "success",
        })
        self:addField(tr("detail.label.networked"), tr("status.no"), {
            tone = "success",
        })
    end
end

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
    local item = selected(self.blocks)
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
        local item = selected(self.blocks)
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

function ISPNCConversationDebugWindow:prerender()
    local query = self.search and self.search:getText() or ""
    if query ~= self.lastQuery then
        self.lastQuery = query
        self:refreshBlocks()
    elseif self.blocks and self.blocks.selected ~= self.lastSelection then
        self.lastSelection = self.blocks.selected
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCConversationDebugWindow:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCConversationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open(context)
    if PNC.Client and PNC.Client.CanUseDebug
        and not PNC.Client.CanUseDebug()
    then return nil end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCConversationDebugWindow, {
            title = tr("title"),
            resizable = true,
            responsiveSpec = {
                width = 1120, height = 720,
                minWidth = 760, minHeight = 500,
                maxWidth = 1600, maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    if type(context) == "table" then
        window.context = Model.NormalizeContext(context)
    end
    window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    if window.setCapture then window:setCapture(true) end
    window:bringToTop()
    window:refreshBlocks()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

return DebugUI
