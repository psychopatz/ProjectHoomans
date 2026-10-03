-- Relationship laboratory selection, requests, controls, and refresh behavior.
PNC = PNC or {}
PNC.RelationshipDebugUI = PNC.RelationshipDebugUI or {}

local Model = PNC.RelationshipDebugModel
local ClientState = PNC.Network.ClientState

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
            conversationDelta = ClientState.lastConversationDelta,
            conversationDeltas = ClientState.lastConversationDeltas,
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
        evaluation,
        ClientState.lastConversationDelta,
        ClientState.lastConversationDeltas
    )
    rows = Model.FilterRows(rows, self.currentSection)
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

function ISPNCRelationshipDebugWindow:onSection(button)
    self.currentSection = button.sectionID or "relationship"
    self:refreshDetails()
end

function ISPNCRelationshipDebugWindow:onBaseline(button)
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target or not PNC.Client then return end
    PNC.Client.SendDebug("relationship_debug_baseline", {
        observerNPCID = observer.id,
        targetKind = target.kind,
        targetNPCID = target.npcID,
        standingID = button.standingID,
    })
end

function ISPNCRelationshipDebugWindow:onCustomBaseline()
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target or not PNC.Client then return end
    local approval = tonumber(self.customApproval:getText())
    local respect = tonumber(self.customRespect:getText())
    if not approval or not respect then return end
    PNC.Client.SendDebug("relationship_debug_baseline", {
        observerNPCID = observer.id,
        targetKind = target.kind,
        targetNPCID = target.npcID,
        approval = math.max(-100, math.min(100, approval)),
        respect = math.max(-100, math.min(100, respect)),
    })
end

function ISPNCRelationshipDebugWindow:onSwapDirection()
    local observer = self:getObserver()
    local target = self:getTarget()
    if not observer or not target or target.kind ~= "npc" then return end
    for index, entry in ipairs(self.observers.items or {}) do
        if tostring(entry.item.id) == tostring(target.id) then
            self.observers.selected = index
            break
        end
    end
    self.lastObserverID = nil
    self:refreshTargets()
    for index, entry in ipairs(self.targets.items or {}) do
        if entry.item.kind == "npc"
            and tostring(entry.item.id) == tostring(observer.id)
        then
            self.targets.selected = index
            break
        end
    end
    self.requestedSignature = nil
    self:requestRelationship()
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

function ISPNCRelationshipDebugWindow:onKnowledge()
    local observer = self:getObserver()
    if observer and PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.Open then
        PNC.KnowledgeDebugUI.Open(observer.id)
    end
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


return PNC.RelationshipDebugUI
