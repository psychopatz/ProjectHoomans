-- Opt-in, transient audit recorder for the Semantic Social Director.
-- Disabled by default. Enabling temporarily wraps the two live decision
-- methods; disabling restores the original instance methods. Therefore the
-- ordinary director/conversation hot path contains no debug branch at all.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Audit = PNC.Semantics.SocialDirectorAudit or {}
PNC.Semantics.SocialDirectorAudit = Audit

Audit.VERSION = 1
Audit.MAX_EVENTS = 48

local state = Audit._state or {
    enabled = false,
    sequence = 0,
    dropped = 0,
    rows = {},
    director = nil,
    conversation = nil,
    directorWrapped = nil,
    directorSubmitBase = nil,
    conversationWrapped = nil,
    conversationEvaluateBase = nil,
}
Audit._state = state

local function now()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        return tonumber(core.Now()) or 0
    end
    return 0
end

local function clean(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 160)
end

local function copy(value, depth)
    if type(value) ~= "table" then
        if type(value) == "string" then return clean(value, 160) end
        if type(value) == "number" or type(value) == "boolean" then
            return value
        end
        return nil
    end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 64 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function retain(source, payload)
    if state.enabled ~= true or type(payload) ~= "table" then return false end
    state.sequence = state.sequence + 1
    local row = copy(payload) or {}
    row.sequence = state.sequence
    row.source = source
    row.at = now()
    state.rows[#state.rows + 1] = row
    while #state.rows > Audit.MAX_EVENTS do
        table.remove(state.rows, 1)
        state.dropped = state.dropped + 1
    end
    return true
end

local function isBudgetReason(reason)
    return reason == "social_actor_cooldown"
        or reason == "social_pair_cooldown"
        or reason == "social_topic_cooldown"
        or reason == "social_area_budget"
end

local function participantIDs(opportunity)
    local output = {}
    for index = 1, math.min(
        #(type(opportunity) == "table"
            and type(opportunity.participants) == "table"
            and opportunity.participants or {}),
        4
    ) do
        local row = opportunity.participants[index]
        if type(row) == "table" and row.id ~= nil then
            output[#output + 1] = clean(row.id, 128)
        end
    end
    return output
end

local function admissionPayload(self, spec, result)
    local decision = type(self.lastDecision) == "table"
        and self.lastDecision or {}
    local opportunity = type(decision.opportunity) == "table"
        and decision.opportunity
        or type(result) == "table"
            and type(result.socialOpportunity) == "table"
            and result.socialOpportunity
        or nil
    local accepted = type(result) == "table" and result.accepted == true
        or decision.accepted == true
    local reason = decision.reason
        or type(result) == "table" and result.reason
        or (accepted and "social_scene_admitted" or "social_scene_rejected")
    local stage
    if accepted then
        stage = "scene"
    elseif opportunity == nil then
        stage = "normalize"
    elseif isBudgetReason(reason) then
        stage = "budget"
    else
        stage = "scene"
    end
    local source = opportunity or type(spec) == "table" and spec or {}
    return {
        kind = "admission",
        stage = stage,
        accepted = accepted,
        reason = reason,
        sceneID = decision.sceneID
            or type(result) == "table" and result.sceneID,
        motive = source.motive,
        relevance = tonumber(source.relevance),
        priority = tonumber(source.priority),
        speakerID = source.speakerID,
        recipientID = source.recipientID,
        participantIDs = participantIDs(source),
        topic = source.topic,
        eventType = source.eventType,
        eventID = source.eventID,
        areaKey = source.areaKey,
        bypassBudget = source.bypassBudget == true,
    }
end

local function modifierRows(values)
    local output = {}
    for index = 1, math.min(
        #(type(values) == "table" and values or {}),
        3
    ) do
        local row = values[index]
        output[#output + 1] = {
            reason = row and row.reason,
            delta = row and tonumber(row.delta),
        }
    end
    return output
end

local function choiceRows(choices)
    local actorIDs = {}
    for actorID in pairs(type(choices) == "table" and choices or {}) do
        actorIDs[#actorIDs + 1] = tostring(actorID)
    end
    table.sort(actorIDs)
    local output = {}
    for index = 1, math.min(#actorIDs, 4) do
        local actorID = actorIDs[index]
        local choice = choices[actorID] or {}
        local candidates = {}
        for candidateIndex = 1, math.min(
            #(type(choice.rows) == "table" and choice.rows or {}),
            4
        ) do
            local row = choice.rows[candidateIndex] or {}
            candidates[#candidates + 1] = {
                candidateID = row.candidateID,
                strategy = row.strategy,
                eligible = row.eligible == true,
                score = tonumber(row.score),
                reason = row.reason,
                modifiers = modifierRows(row.modifiers),
            }
        end
        output[#output + 1] = {
            actorID = actorID,
            targetID = choice.targetID,
            frontierCount = tonumber(choice.frontierCount) or 0,
            selectedStrategy = choice.selected and choice.selected.strategy or nil,
            selectedStance = choice.selected and choice.selected.stance or nil,
            selectedScore = tonumber(choice.selectedScore),
            reason = choice.reason,
            candidates = candidates,
        }
    end
    return output
end

local function turnPayload(scene, social, decision)
    decision = type(decision) == "table" and decision or {}
    social = type(social) == "table" and social or {}
    return {
        kind = "turn",
        sceneID = scene and scene.id,
        motive = social.motive,
        relevance = tonumber(social.relevance),
        topic = social.topic,
        currentSpeakerID = decision.currentSpeakerID,
        currentRecipientID = decision.currentRecipientID,
        mode = decision.mode,
        reason = decision.reason,
        selectedActorID = decision.actorID,
        selectedTargetID = decision.targetID,
        selectedStrategy = decision.choice
            and decision.choice.selected
            and decision.choice.selected.strategy or nil,
        choices = choiceRows(decision.choicesByActor),
    }
end

local function uninstallWrappers()
    if state.directorWrapped then
        state.directorWrapped.Submit = nil
    end
    if state.conversationWrapped then
        state.conversationWrapped.EvaluateTurn = nil
    end
    state.directorWrapped = nil
    state.directorSubmitBase = nil
    state.conversationWrapped = nil
    state.conversationEvaluateBase = nil
end

local function installWrappers()
    local director = state.director
    if director and type(director.Submit) == "function" then
        local baseSubmit = director.Submit
        state.directorWrapped = director
        state.directorSubmitBase = baseSubmit
        director.Submit = function(self, spec)
            local result = baseSubmit(self, spec)
            retain("director", admissionPayload(self, spec, result))
            return result
        end
    end

    local conversation = state.conversation
    if conversation and type(conversation.EvaluateTurn) == "function" then
        local baseEvaluateTurn = conversation.EvaluateTurn
        state.conversationWrapped = conversation
        state.conversationEvaluateBase = baseEvaluateTurn
        conversation.EvaluateTurn = function(self, scene, result, social)
            local decision = baseEvaluateTurn(
                self, scene, result, social
            )
            retain(
                "conversation",
                turnPayload(scene, social, decision)
            )
            return decision
        end
    end
end

function Audit.Bind(director, conversation)
    local enabled = state.enabled == true
    if enabled then uninstallWrappers() end
    state.director = director
    state.conversation = conversation
    if enabled then installWrappers() end
    return true
end

function Audit.IsEnabled()
    return state.enabled == true
end

function Audit.SetEnabled(enabled)
    enabled = enabled == true
    if state.enabled == enabled then return true end
    if state.enabled == true then uninstallWrappers() end
    state.enabled = enabled
    if enabled then installWrappers() end
    return true
end

function Audit.Clear()
    state.rows = {}
    state.dropped = 0
    return true
end

function Audit.BuildSnapshot()
    local rows = {}
    for index = #state.rows, 1, -1 do
        rows[#rows + 1] = copy(state.rows[index])
    end
    return {
        schemaVersion = Audit.VERSION,
        enabled = state.enabled == true,
        captureMode = state.enabled == true and "ON" or "OFF",
        instrumentation = state.enabled == true
            and "runtime_wrapped" or "detached",
        maxEvents = Audit.MAX_EVENTS,
        eventCount = #state.rows,
        dropped = state.dropped,
        rows = rows,
        director = state.director
            and type(state.director.Snapshot) == "function"
            and state.director:Snapshot() or nil,
        conversation = state.conversation
            and type(state.conversation.Snapshot) == "function"
            and state.conversation:Snapshot() or nil,
    }
end

function Audit.PerformAction(args)
    args = type(args) == "table" and args or {}
    local action = tostring(
        args.socialDirectorAction or args.auditAction or args.action or ""
    )
    if action == "enable" then
        Audit.SetEnabled(true)
    elseif action == "disable" then
        Audit.SetEnabled(false)
    elseif action == "toggle" then
        Audit.SetEnabled(not state.enabled)
    elseif action == "clear" then
        Audit.Clear()
    elseif action ~= "" and action ~= "refresh" then
        return nil, "social_director_debug_action_invalid"
    end
    return Audit.BuildSnapshot(), nil
end

function Audit.ResetForTests()
    Audit.SetEnabled(false)
    Audit.Clear()
    state.sequence = 0
    state.director = nil
    state.conversation = nil
    return true
end

return Audit
