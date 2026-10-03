-- Relationship laboratory rendering, lifecycle, and public open/toggle API.
PNC = PNC or {}
PNC.RelationshipDebugUI = PNC.RelationshipDebugUI or {}

local RelationshipUI = PNC.RelationshipDebugUI
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

function ISPNCRelationshipDebugWindow:prerender()
    local now = PNC.Core.Now()
    local rosterReceiveAt =
        tonumber(ClientState.lastDebugRosterReceiveAt)
        or tonumber(ClientState.lastDebugRosterRequestAt)
        or 0
    local relationshipReceiveAt =
        tonumber(ClientState.lastRelationshipDebugReceiveAt) or 0
    local conversationDeltaAt = ClientState.lastConversationDelta
        and tonumber(ClientState.lastConversationDelta.at) or 0
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
    if conversationDeltaAt >
        (tonumber(self.lastConversationDeltaAt) or 0)
    then
        self:refreshDetails()
        self.lastConversationDeltaAt = conversationDeltaAt
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
    if self.swapButton then
        self.swapButton:setEnable(enabled and self:getTarget()
            and self:getTarget().kind == "npc")
    end
    if self.applyCustomButton then
        self.applyCustomButton:setEnable(enabled)
    end
    for _, button in ipairs(self.sectionControls or {}) do
        button:setEnable(ClientState.relationshipDebug ~= nil)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCRelationshipDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then
        return
    end
    self:drawText(
        "Synthetic baseline  Approval / Respect",
        self.layout.custom.x,
        self.layout.custom.y - Layout.Pixels(17, self.uiScale),
        Theme.colors.textMuted.r,
        Theme.colors.textMuted.g,
        Theme.colors.textMuted.b,
        Theme.colors.textMuted.a,
        UIFont.Small
    )
    UI.DrawSectionTitle(
        self,
        "Relationship graph / interaction preview",
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
        "Relationship laboratory: "
            .. tostring(self.currentSection or "relationship"),
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
            title = "PNC Relationship Laboratory",
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
