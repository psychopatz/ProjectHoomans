require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.SemanticSocialDirectorDebugUI =
    PNC.SemanticSocialDirectorDebugUI or {}

local DebugUI = PNC.SemanticSocialDirectorDebugUI
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function score(value)
    value = tonumber(value)
    if value == nil then return "-" end
    return string.format("%.3f", value)
end

local function drawEvent(list, y, entry, alternate)
    local item = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight,
        list.selected == entry.index, alternate
    )
    local title = "#" .. tostring(item.sequence or "?")
        .. " " .. string.upper(tostring(item.kind or "event"))
    if item.stage then
        title = title .. " / " .. string.upper(tostring(item.stage))
    end
    list:drawText(
        Layout.Ellipsize(title, UIFont.Small, list:getWidth() - 14),
        7, y + 4,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small
    )
    local detail = item.reason or item.mode or ""
    if item.speakerID or item.currentSpeakerID then
        detail = tostring(item.speakerID or item.currentSpeakerID)
            .. " -> "
            .. tostring(item.recipientID or item.currentRecipientID or "?")
            .. (detail ~= "" and (" | " .. tostring(detail)) or "")
    end
    list:drawText(
        Layout.Ellipsize(detail, UIFont.Small, list:getWidth() - 14),
        7, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small
    )
    return y + list.itemheight
end

local function addKV(window, label, value)
    window.details:addItem(label, {
        label = label,
        value = value == nil and "-" or tostring(value),
    })
end

ISPNCSemanticSocialDirectorDebugWindow =
    PsychopatzWindow:derive("ISPNCSemanticSocialDirectorDebugWindow")

function ISPNCSemanticSocialDirectorDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCSemanticSocialDirectorDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.events = UI.CreateList(self, {
        itemHeight = 42,
        doDrawItem = drawEvent,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = 180,
        valueRightPadding = 7,
    })
    self.controls = {}
    for _, definition in ipairs({
        { "refresh", "REFRESH", "quiet" },
        { "enable", "ENABLE AUDIT", "success" },
        { "disable", "DISABLE AUDIT", "danger" },
        { "clear", "CLEAR CAPTURE", "quiet" },
    }) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = ISPNCSemanticSocialDirectorDebugWindow.onAction,
            variant = definition[3],
        })
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCSemanticSocialDirectorDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local flow = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 105 }
    )
    local top = flow.bottom + 24
    local gap = 8
    local eventWidth = math.max(280, math.floor(rect.width * 0.38))
    local height = rect.height - (top - rect.y)
    self.layout = {
        events = {
            x = rect.x, y = top,
            width = eventWidth, height = height,
        },
        details = {
            x = rect.x + eventWidth + gap, y = top,
            width = rect.width - eventWidth - gap, height = height,
        },
    }
    Layout.SetBounds(
        self.events,
        self.layout.events.x, self.layout.events.y,
        self.layout.events.width, self.layout.events.height
    )
    Layout.SetBounds(
        self.details,
        self.layout.details.x, self.layout.details.y,
        self.layout.details.width, self.layout.details.height
    )
end

function ISPNCSemanticSocialDirectorDebugWindow:requestSnapshot()
    if not PNC.Client or not PNC.Client.RequestSemanticSocialDebug then
        return false
    end
    local ok = PNC.Client.RequestSemanticSocialDebug()
    self.lastRequestAt = PNC.Core.Now()
    return ok
end

function ISPNCSemanticSocialDirectorDebugWindow:refreshSnapshot()
    local snapshot = ClientState.semanticSocialDebug or {}
    local old = selected(self.events)
    local oldSequence = old and old.sequence
    self.events:clear()
    for _, row in ipairs(snapshot.rows or {}) do
        self.events:addItem(tostring(row.sequence or ""), row)
    end
    if oldSequence then
        for index, entry in ipairs(self.events.items or {}) do
            if entry.item and entry.item.sequence == oldSequence then
                self.events.selected = index
                break
            end
        end
    end
    if (self.events.selected or 0) < 1 and #self.events.items > 0 then
        self.events.selected = 1
    end
    self.lastReceiveAt = ClientState.lastSemanticSocialDebugReceiveAt
        or PNC.Core.Now()
    self:refreshDetails()
end

function ISPNCSemanticSocialDirectorDebugWindow:refreshDetails()
    local snapshot = ClientState.semanticSocialDebug or {}
    local row = selected(self.events)
    self.details:clear()

    addKV(self, "Capture", snapshot.enabled == true and "ON" or "OFF")
    addKV(self, "Captured", snapshot.eventCount or 0)
    addKV(self, "Dropped", snapshot.dropped or 0)
    addKV(self, "Capacity", snapshot.maxEvents or 0)

    local director = snapshot.director or {}
    local metrics = director.metrics or {}
    addKV(self, "Submitted", metrics.submitted or 0)
    addKV(self, "Admitted", metrics.admitted or 0)
    addKV(self, "Rejected", metrics.rejected or 0)
    addKV(self, "Silent", metrics.silent or 0)
    addKV(self, "Budget rejected", metrics.budgetRejected or 0)

    if not row then
        addKV(self, "Selected event", "None")
        return
    end

    addKV(self, "Sequence", row.sequence)
    addKV(self, "Source", row.source)
    addKV(self, "Kind", row.kind)
    addKV(self, "Stage", row.stage)
    addKV(self, "Accepted", row.accepted)
    addKV(self, "Scene", row.sceneID)
    addKV(self, "Motive", row.motive)
    addKV(self, "Relevance", score(row.relevance))
    addKV(self, "Priority", row.priority)
    addKV(self, "Topic", row.topic)
    addKV(self, "Event type", row.eventType)
    addKV(self, "Reason", row.reason)
    addKV(self, "Speaker", row.speakerID or row.currentSpeakerID)
    addKV(self, "Recipient", row.recipientID or row.currentRecipientID)
    addKV(self, "Turn mode", row.mode)
    addKV(self, "Chosen actor", row.selectedActorID)
    addKV(self, "Chosen target", row.selectedTargetID)
    addKV(self, "Chosen strategy", row.selectedStrategy)
    addKV(self, "Area key", row.areaKey)
    addKV(self, "Budget bypass", row.bypassBudget)

    if type(row.participantIDs) == "table" then
        addKV(self, "Participants", table.concat(row.participantIDs, ", "))
    end

    for choiceIndex, choice in ipairs(row.choices or {}) do
        local prefix = "Choice " .. tostring(choiceIndex)
            .. " [" .. tostring(choice.actorID or "?") .. "]"
        local summary = tostring(choice.selectedStrategy or "SILENCE")
            .. " score=" .. score(choice.selectedScore)
            .. " reason=" .. tostring(choice.reason or "-")
        addKV(self, prefix, summary)
        addKV(self, "  target", choice.targetID)
        addKV(self, "  frontier", choice.frontierCount)
        for candidateIndex, candidate in ipairs(choice.candidates or {}) do
            local candidateSummary =
                tostring(candidate.strategy or candidate.candidateID or "?")
                .. " score=" .. score(candidate.score)
                .. " eligible=" .. tostring(candidate.eligible == true)
                .. " reason=" .. tostring(candidate.reason or "-")
            addKV(
                self,
                "  candidate " .. tostring(candidateIndex),
                candidateSummary
            )
            for _, modifier in ipairs(candidate.modifiers or {}) do
                addKV(
                    self,
                    "    " .. tostring(modifier.reason or "modifier"),
                    score(modifier.delta)
                )
            end
        end
    end
end

function ISPNCSemanticSocialDirectorDebugWindow:onAction(button)
    if button.internal == "refresh" then
        self:requestSnapshot()
        return
    end
    if not PNC.Client or not PNC.Client.SendDebug then return end
    PNC.Client.SendDebug("semantic_social_debug_action", {
        socialDirectorAction = button.internal,
    })
end

function ISPNCSemanticSocialDirectorDebugWindow:prerender()
    local received = ClientState.lastSemanticSocialDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then
        self:refreshSnapshot()
    end

    local snapshot = ClientState.semanticSocialDebug or {}
    if snapshot.enabled == true
        and PNC.Core.Now() - (self.lastRequestAt or 0) > 1500
    then
        self:requestSnapshot()
    end

    local row = selected(self.events)
    local sequence = row and row.sequence or nil
    if sequence ~= self.lastSelectedSequence then
        self.lastSelectedSequence = sequence
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCSemanticSocialDirectorDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(
            self, "AI SOCIAL DIRECTOR DECISIONS",
            self.layout.events.x, self.layout.events.y - 20,
            self.layout.events.width
        )
        UI.DrawSectionTitle(
            self, "WHY THE DIRECTOR CHOSE IT",
            self.layout.details.x, self.layout.details.y - 20,
            self.layout.details.width
        )
    end
end

function ISPNCSemanticSocialDirectorDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCSemanticSocialDirectorDebugWindow:new(
    x, y, width, height, options
)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCSemanticSocialDirectorDebugWindow, {
            title = "PNC AI SOCIAL DIRECTOR AUDIT",
            resizable = true,
            persistenceKey = "PNC.SemanticSocialDirectorDebug",
            responsiveSpec = {
                width = 1120, height = 700,
                minWidth = 760, minHeight = 480,
                maxWidth = 1600, maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

function DebugUI.IsOpen()
    return DebugUI.instance
        and DebugUI.instance.getIsVisible
        and DebugUI.instance:getIsVisible() == true or false
end

return DebugUI
