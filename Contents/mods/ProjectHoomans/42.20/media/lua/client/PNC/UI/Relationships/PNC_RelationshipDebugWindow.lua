require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/Relationships/PNC_RelationshipDebugModel"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"

PNC.RelationshipDebugUI = PNC.RelationshipDebugUI or {}

local RelationshipUI = PNC.RelationshipDebugUI
local Model = PNC.RelationshipDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local EVENTS = {
    { id = "treated_wound", title = "Treat Wound", variant = "success" },
    { id = "saved_from_incapacitation", title = "Save", variant = "success" },
    { id = "protected_from_attacker", title = "Protect", variant = "default" },
    { id = "survived_combat_together", title = "Survive Together", variant = "default" },
    { id = "abandoned_in_combat", title = "Abandon", variant = "danger" },
}

local function drawEntity(list, y, entry, alternate)
    local item = entry.item
    local height = list.itemheight
    UI.DrawListSelection(
        list,
        y,
        height,
        list.selected == entry.index,
        alternate
    )
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label or item.name or item.id,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 5,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.key or item.id or item.kind,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 24,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    return y + height
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item
    local height = list.itemheight
    local muted = Theme.colors.textMuted
    local color = Theme.colors[item.tone or "text"]
        or Theme.colors.text
    local labelWidth = math.min(
        150,
        math.floor(list:getWidth() * 0.34)
    )
    UI.DrawListSelection(list, y, height, false, alternate)
    list:drawText(
        item.label,
        10, y + 6,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.value,
            UIFont.Small,
            math.max(40, list:getWidth() - labelWidth - 24)
        ),
        12 + labelWidth, y + 6,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    return y + height
end

ISPNCRelationshipDebugWindow =
    PsychopatzWindow:derive("ISPNCRelationshipDebugWindow")

function ISPNCRelationshipDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCRelationshipDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.observers = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.targets = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.details = UI.CreateList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.actionCombo = ISComboBox:new(
        0,
        0,
        240,
        Layout.Pixels(26, self.uiScale),
        self,
        ISPNCRelationshipDebugWindow.onActionChanged
    )
    self.actionCombo:initialise()
    self.actionCombo:instantiate()
    self:addChild(self.actionCombo)
    for _, requirement in ipairs(
        PNC.RelationshipGraph.ListRequirements()
    ) do
        self.actionCombo:addOptionWithData(
            requirement.label,
            requirement.id
        )
    end
    if self.actionCombo.selectData then
        self.actionCombo:selectData("inspect")
    end
    self.graph = ISPNCRelationshipGraphPanel:new(
        0,
        0,
        320,
        420
    )
    self.graph:initialise()
    self.graph:instantiate()
    self:addChild(self.graph)
    self.contextBonus = 0
    self.controls = {}
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = "Refresh",
        target = self,
        onclick = ISPNCRelationshipDebugWindow.onRefresh,
        variant = "quiet",
    })
    self.controls[#self.controls + 1] = self.refreshButton
    for _, definition in ipairs(EVENTS) do
        local button = UI.CreateButton(self, {
            id = definition.id,
            title = definition.title,
            target = self,
            onclick = ISPNCRelationshipDebugWindow.onTrigger,
            variant = definition.variant,
        })
        self.controls[#self.controls + 1] = button
    end
    local extraControls = {
        {
            id = "pacify_24h",
            title = "Pacify for 24h",
            callback =
                ISPNCRelationshipDebugWindow.onPacification,
            variant = "success",
        },
        {
            id = "clear_pacification",
            title = "Clear Pacification",
            callback =
                ISPNCRelationshipDebugWindow.onPacification,
            variant = "danger",
        },
        {
            id = "context_minus",
            title = "Context -5",
            callback =
                ISPNCRelationshipDebugWindow.onContext,
            variant = "quiet",
        },
        {
            id = "context_reset",
            title = "Context Reset",
            callback =
                ISPNCRelationshipDebugWindow.onContext,
            variant = "quiet",
        },
        {
            id = "context_plus",
            title = "Context +5",
            callback =
                ISPNCRelationshipDebugWindow.onContext,
            variant = "quiet",
        },
    }
    for _, definition in ipairs(extraControls) do
        local button = UI.CreateButton(self, {
            id = definition.id,
            title = definition.title,
            target = self,
            onclick = definition.callback,
            variant = definition.variant,
        })
        self.controls[#self.controls + 1] = button
    end
    self:requestResponsiveLayout(true)
    self:refreshRoster()
    self:requestRoster()
end

function ISPNCRelationshipDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local controls = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 72 }
    )
    local top = controls.bottom + Layout.Pixels(25, self.uiScale)
    local height = math.max(
        100,
        rect.y + rect.height - top
    )
    local gap = Layout.Pixels(8, self.uiScale)
    local leftWidth = math.max(
        145,
        math.floor(rect.width * 0.15)
    )
    local graphWidth = math.max(
        300,
        math.min(410, math.floor(rect.width * 0.31))
    )
    local detailWidth = math.max(
        240,
        rect.width - leftWidth * 2 - graphWidth - gap * 3
    )
    self.layout = {
        observer = {
            x = rect.x, y = top,
            width = leftWidth, height = height,
        },
        target = {
            x = rect.x + leftWidth + gap, y = top,
            width = leftWidth, height = height,
        },
        graph = {
            x = rect.x + leftWidth * 2 + gap * 2, y = top,
            width = graphWidth, height = height,
        },
        detail = {
            x = rect.x + leftWidth * 2
                + graphWidth + gap * 3,
            y = top,
            width = detailWidth, height = height,
        },
    }
    Layout.SetBounds(
        self.observers,
        self.layout.observer.x,
        self.layout.observer.y,
        self.layout.observer.width,
        self.layout.observer.height
    )
    Layout.SetBounds(
        self.targets,
        self.layout.target.x,
        self.layout.target.y,
        self.layout.target.width,
        self.layout.target.height
    )
    Layout.SetBounds(
        self.actionCombo,
        self.layout.graph.x,
        self.layout.graph.y,
        self.layout.graph.width,
        Layout.Pixels(26, self.uiScale)
    )
    Layout.SetBounds(
        self.graph,
        self.layout.graph.x,
        self.layout.graph.y + Layout.Pixels(32, self.uiScale),
        self.layout.graph.width,
        self.layout.graph.height - Layout.Pixels(32, self.uiScale)
    )
    Layout.SetBounds(
        self.details,
        self.layout.detail.x,
        self.layout.detail.y,
        self.layout.detail.width,
        self.layout.detail.height
    )
end

function ISPNCRelationshipDebugWindow:getActionID()
    local combo = self.actionCombo
    if combo and combo.getOptionData then
        return combo:getOptionData(combo.selected)
            or "inspect"
    end
    if combo and combo.optiondata then
        return combo.optiondata[combo.selected] or "inspect"
    end
    local option = combo and combo.options
        and combo.options[combo.selected] or nil
    return type(option) == "table"
        and option.data or "inspect"
end

function ISPNCRelationshipDebugWindow:refreshGraph()
    local evaluation = Model.BuildGraph(
        ClientState.relationshipDebug,
        self:getActionID(),
        {
            bonus = tonumber(self.contextBonus) or 0,
        }
    )
    if evaluation and self.graph then
        self.graph:setEvaluation(evaluation)
    end
    return evaluation
end

function ISPNCRelationshipDebugWindow:getObserver()
    local entry = self.observers and self.observers:getItem()
    return entry and entry.item or nil
end

function ISPNCRelationshipDebugWindow:getTarget()
    local entry = self.targets and self.targets:getItem()
    return entry and entry.item or nil
end

function ISPNCRelationshipDebugWindow:requestRoster()
    if PNC.Client and PNC.Client.RequestDebugRoster then
        PNC.Client.RequestDebugRoster(false)
    end
    self.lastRosterRequestAt = PNC.Core.Now()
end

function ISPNCRelationshipDebugWindow:refreshRoster()
    local observer = self:getObserver()
    local selectedID = self.preferredObserverID
        or observer and observer.id
    self.observers:clear()
    for _, item in ipairs(ClientState.debugRoster or {}) do
        if item.deathMarker ~= true and item.alive ~= false then
            local entry = {
                id = tostring(item.id),
                label = tostring(
                    item.name or item.displayName or item.id
                ),
                key = "npc:" .. tostring(item.id),
            }
            self.observers:addItem(entry.label, entry)
            if selectedID
                and tostring(entry.id) == tostring(selectedID)
            then
                self.observers.selected = #self.observers.items
            end
        end
    end
    if #self.observers.items > 0
        and (tonumber(self.observers.selected) or 0) < 1
    then
        self.observers.selected = 1
    end
    self.preferredObserverID = nil
    self:refreshTargets()
    self.lastRosterReceiveAt =
        tonumber(ClientState.lastDebugRosterReceiveAt)
        or PNC.Core.Now()
end

function ISPNCRelationshipDebugWindow:refreshTargets()
    local observer = self:getObserver()
    local current = self:getTarget()
    local selectedKind = current and current.kind
    local selectedID = current and current.id
    self.targets:clear()
    if not observer then
        return
    end
    for _, target in ipairs(Model.BuildTargets(
        ClientState.debugRoster,
        observer.id
    )) do
        self.targets:addItem(target.label, target)
        if target.kind == selectedKind
            and target.id == selectedID
        then
            self.targets.selected = #self.targets.items
        end
    end
    if #self.targets.items > 0
        and (tonumber(self.targets.selected) or 0) < 1
    then
        self.targets.selected = 1
    end
end

function ISPNCRelationshipDebugWindow:selectionSignature()
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target then
        return nil
    end
    return tostring(observer.id) .. "|"
        .. tostring(target.kind) .. "|" .. tostring(target.id)
end

function ISPNCRelationshipDebugWindow:requestRelationship()
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target
        or not PNC.Client
        or not PNC.Client.RequestRelationshipDebug
    then
        return false
    end
    self.requestedSignature = self:selectionSignature()
    return PNC.Client.RequestRelationshipDebug(
        observer.id,
        target.kind,
        target.npcID
    )
end

function ISPNCRelationshipDebugWindow:refreshDetails()
    local evaluation = self:refreshGraph()
    local rows = Model.BuildRows(
        ClientState.relationshipDebug,
        ClientState.relationshipDebugAuthorized,
        ClientState.relationshipDebugReason,
        evaluation
    )
    self.details:clear()
    for _, item in ipairs(rows) do
        self.details:addItem(item.label, item)
    end
    self.lastRelationshipReceiveAt =
        tonumber(ClientState.lastRelationshipDebugReceiveAt)
        or PNC.Core.Now()
end

function ISPNCRelationshipDebugWindow:onActionChanged()
    self:refreshDetails()
end

function ISPNCRelationshipDebugWindow:onContext(button)
    if button.internal == "context_minus" then
        self.contextBonus = math.max(
            -100,
            (tonumber(self.contextBonus) or 0) - 5
        )
    elseif button.internal == "context_plus" then
        self.contextBonus = math.min(
            100,
            (tonumber(self.contextBonus) or 0) + 5
        )
    else
        self.contextBonus = 0
    end
    self:refreshDetails()
end

function ISPNCRelationshipDebugWindow:onPacification(button)
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target
        or target.kind ~= "current_player"
        or not PNC.Client
    then
        return
    end
    PNC.Client.SendDebug("relationship_pacification", {
        observerNPCID = observer.id,
        mode = button.internal == "clear_pacification"
            and "clear" or "pacify",
        durationHours = 24,
    })
end

function ISPNCRelationshipDebugWindow:onRefresh()
    self:requestRoster()
    self:requestRelationship()
end

function ISPNCRelationshipDebugWindow:onTrigger(button)
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target or not PNC.Client then
        return
    end
    PNC.Client.SendDebug("social_trigger_event", {
        observerNPCID = observer.id,
        targetKind = target.kind,
        targetNPCID = target.npcID,
        eventType = button.internal,
    })
end

function ISPNCRelationshipDebugWindow:prerender()
    local now = PNC.Core.Now()
    local rosterReceiveAt =
        tonumber(ClientState.lastDebugRosterReceiveAt)
        or tonumber(ClientState.lastDebugRosterRequestAt)
        or 0
    local relationshipReceiveAt =
        tonumber(ClientState.lastRelationshipDebugReceiveAt) or 0
    local signature = self:selectionSignature()
    local observer = self:getObserver()
    local observerID = observer and observer.id
    if rosterReceiveAt >
        (tonumber(self.lastRosterReceiveAt) or 0)
    then
        self:refreshRoster()
        signature = self:selectionSignature()
    end
    if observerID ~= self.lastObserverID then
        self.lastObserverID = observerID
        self:refreshTargets()
        signature = self:selectionSignature()
    end
    if signature and signature ~= self.requestedSignature then
        self:requestRelationship()
    end
    if relationshipReceiveAt >
        (tonumber(self.lastRelationshipReceiveAt) or 0)
    then
        self:refreshDetails()
    end
    if now - (tonumber(self.lastRosterRequestAt) or 0) > 2000 then
        self:requestRoster()
    end
    local enabled = signature ~= nil
    for index = 2, #self.controls do
        local button = self.controls[index]
        local pacificationControl =
            button.internal == "pacify_24h"
            or button.internal == "clear_pacification"
        button:setEnable(
            enabled
            and (
                not pacificationControl
                or self:getTarget()
                    and self:getTarget().kind
                        == "current_player"
            )
        )
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCRelationshipDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then
        return
    end
    UI.DrawSectionTitle(
        self,
        "Approval / respect outcome map",
        self.layout.graph.x,
        self.layout.graph.y - Layout.Pixels(21, self.uiScale),
        self.layout.graph.width
    )
    UI.DrawSectionTitle(
        self,
        "Observer NPC",
        self.layout.observer.x,
        self.layout.observer.y - Layout.Pixels(21, self.uiScale),
        self.layout.observer.width
    )
    UI.DrawSectionTitle(
        self,
        "Relationship target",
        self.layout.target.x,
        self.layout.target.y - Layout.Pixels(21, self.uiScale),
        self.layout.target.width
    )
    UI.DrawSectionTitle(
        self,
        "Authoritative relationship data",
        self.layout.detail.x,
        self.layout.detail.y - Layout.Pixels(21, self.uiScale),
        self.layout.detail.width
    )
end

function ISPNCRelationshipDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    RelationshipUI.instance = nil
end

function ISPNCRelationshipDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function RelationshipUI.Open(observerNPCID)
    local window = RelationshipUI.instance
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if not window then
        window = UI.NewWindow(ISPNCRelationshipDebugWindow, {
            title = "PNC Relationship Inspector",
            resizable = true,
            responsiveSpec = {
                width = 1180,
                height = 760,
                minWidth = 980,
                minHeight = 500,
                maxWidth = 1420,
                maxHeight = 920,
            },
        })
        window.preferredObserverID = observerNPCID
        window:initialise()
        window:instantiate()
        RelationshipUI.instance = window
    elseif observerNPCID then
        window.preferredObserverID = observerNPCID
        window:refreshRoster()
        window.requestedSignature = nil
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestRoster()
    return window
end

function RelationshipUI.Toggle()
    local window = RelationshipUI.instance
    if window and window:getIsVisible() then
        window:close()
        return nil
    end
    return RelationshipUI.Open()
end

local function onResetLua()
    if RelationshipUI.instance then
        RelationshipUI.instance:close()
    end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

return RelationshipUI
