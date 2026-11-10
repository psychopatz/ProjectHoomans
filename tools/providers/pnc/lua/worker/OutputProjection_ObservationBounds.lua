-- Bounded projections used by the observation envelope.

local Bounds = {}
local TransportEvidence = require "worker/TransportEvidence"

local MAX_CANDIDATES = 8
local MAX_LOOKUPS = 32
local MAX_ACTIONS = 16

function Bounds.capabilityBinding(context, action)
    local Values = context.Values
    local catalog = PNC.Semantics and PNC.Semantics.CapabilityCatalog
    if not catalog or type(catalog.ListActions) ~= "function" then
        return nil
    end
    action = string.upper(tostring(action or ""))
    if action == "" then return nil end
    for _, row in ipairs(catalog.ListActions()) do
        if type(row) == "table" and tostring(row.id or "") == action then
            return row.binding and Values.copy(row.binding) or nil
        end
    end
    return nil
end

function Bounds.candidates(context, result)
    local Values = context.Values
    local bundle = result and result.candidates or {}
    local selected = type(bundle.selected) == "table"
        and bundle.selected or {}
    local list = type(bundle.candidates) == "table"
        and bundle.candidates or {}
    local candidates = {}
    local limit = math.min(#list, MAX_CANDIDATES)
    for index = 1, limit do
        local candidate = list[index]
        if type(candidate) == "table" then
            candidates[#candidates + 1] = {
                patternID = candidate.patternID,
                confidence = candidate.confidence,
                score = candidate.score,
                pass = candidate.pass,
                fuzzy = candidate.fuzzy == true,
                selected = candidate.selected == true,
                metadata = Values.copy(candidate.metadata),
            }
        end
    end
    local diagnostics = result and result.candidateDiagnostics or {}
    return {
        count = #list,
        truncated = #list > limit,
        selectedPattern = selected.patternID,
        selectedScore = selected.score or selected.confidence,
        selectedPass = selected.pass,
        selectedFuzzy = selected.fuzzy == true,
        reason = diagnostics.reason,
        candidates = candidates,
    }
end

function Bounds.flowSessions(snapshot)
    local sessions = {}
    local dialogue = type(snapshot) == "table" and snapshot.dialogue or nil
    local flowSessions = type(dialogue) == "table"
        and dialogue.flowSessions or nil
    if type(flowSessions) ~= "table" then return sessions end
    for _, session in ipairs(flowSessions) do
        if type(session) == "table" then
            local active = type(session.active) == "table"
                and session.active or {}
            local suspended = {}
            if type(session.suspended) == "table" then
                for _, value in ipairs(session.suspended) do
                    if type(value) == "table" then
                        suspended[#suspended + 1] = {
                            flowId = value.flowId,
                            nodeId = value.nodeId,
                        }
                    end
                end
            end
            sessions[#sessions + 1] = {
                key = session.key,
                speakerID = session.speakerID,
                addresseeID = session.addresseeID,
                flowId = active.flowId,
                nodeId = active.nodeId,
                lastTransition = session.lastTransition,
                resumedFlowId = session.resumedFlowId,
                completedFlowId = session.completedFlowId,
                revision = session.revision,
                suspended = suspended,
            }
        end
    end
    return sessions
end

local MAX_DIRECTOR_BEATS = 12
local MAX_DIRECTOR_BEHAVIORS = 12
local MAX_DIRECTOR_TRACE = 24

local function directorTrace(Values, source)
    local output = {}
    source = type(source) == "table" and source or {}
    local limit = math.min(#source, MAX_DIRECTOR_TRACE)
    for index = 1, limit do
        local row = source[index]
        if type(row) == "table" then
            output[#output + 1] = {
                id = row.id,
                kind = row.kind,
                path = row.path,
                op = row.op,
                expected = Values.copy(row.expected),
                actual = Values.copy(row.actual),
                passed = row.passed == true,
                reason = row.reason,
            }
        end
    end
    return {
        rows = output,
        count = #source,
        truncated = #source > limit,
    }
end

function Bounds.director(context, director, before, after)
    local Values = context.Values
    director = type(director) == "table" and director or {}
    local beatRows = {}
    local sourceBeats = type(director.beatCandidates) == "table"
        and director.beatCandidates or {}
    local beatLimit = math.min(#sourceBeats, MAX_DIRECTOR_BEATS)
    for index = 1, beatLimit do
        local row = sourceBeats[index]
        if type(row) == "table" then
            beatRows[#beatRows + 1] = {
                id = row.id,
                group = row.group,
                status = row.status,
                eligible = row.eligible == true,
                score = row.score,
                reason = row.reason,
                labelKey = row.labelKey,
                descriptionKey = row.descriptionKey,
                predicateTrace = directorTrace(
                    Values, row.predicateTrace
                ),
            }
        end
    end

    local function projectBehaviorRows(sourceBehaviors)
        local behaviorRows = {}
        sourceBehaviors = type(sourceBehaviors) == "table"
            and sourceBehaviors or {}
        local behaviorLimit = math.min(
            #sourceBehaviors, MAX_DIRECTOR_BEHAVIORS
        )
        for index = 1, behaviorLimit do
            local row = sourceBehaviors[index]
            if type(row) == "table" then
                local modifiers = {}
                local sourceModifiers = type(row.modifiers) == "table"
                    and row.modifiers or {}
                local modifierLimit = math.min(#sourceModifiers, 16)
                for modifierIndex = 1, modifierLimit do
                    local modifier = sourceModifiers[modifierIndex]
                    if type(modifier) == "table" then
                        modifiers[#modifiers + 1] = {
                            reason = modifier.reason,
                            matched = modifier.matched == true,
                            delta = modifier.delta,
                            configuredDelta = modifier.configuredDelta,
                            predicateTrace = directorTrace(
                                Values, modifier.predicateTrace
                            ),
                        }
                    end
                end
                behaviorRows[#behaviorRows + 1] = {
                    id = row.id,
                    act = row.act,
                    mode = row.mode,
                    eligible = row.eligible == true,
                    stimuli = Values.copy(row.stimuli),
                    requiredCapabilities = Values.copy(
                        row.requiredCapabilities
                    ),
                    outputs = Values.copy(row.outputs),
                    dialogueAct = row.dialogueAct,
                    contentTemplateID = row.contentTemplateID,
                    baseRelevance = row.baseRelevance,
                    beatRelevance = row.beatRelevance,
                    score = row.score,
                    eligibility = Values.copy(row.eligibility),
                    eligibilityTrace = directorTrace(
                        Values, row.eligibilityTrace
                    ),
                    modifiers = modifiers,
                    modifiersTruncated = #sourceModifiers > modifierLimit,
                }
            end
        end
        return behaviorRows, #sourceBehaviors, behaviorLimit
    end

    local behaviorRows, behaviorCount, behaviorLimit =
        projectBehaviorRows(director.behaviorCandidates)
    local oneShotRows, oneShotCount, oneShotLimit =
        projectBehaviorRows(director.oneShotBehaviorCandidates)

    local beforeDialogue = type(before) == "table"
        and type(before.dialogue) == "table" and before.dialogue or {}
    local afterDialogue = type(after) == "table"
        and type(after.dialogue) == "table" and after.dialogue or {}
    return {
        kind = director.kind,
        committed = director.committed == true,
        sequence = director.sequence,
        stimulus = Values.copy(director.stimulus),
        pragmatic = Values.copy(director.pragmatic),
        metrics = Values.copy(director.metrics),
        activeBefore = Values.copy(director.activeBefore),
        activeAfter = Values.copy(director.activeAfter),
        entered = Values.copy(director.entered),
        exited = Values.copy(director.exited),
        selectedBeat = Values.copy(director.selectedBeat),
        selectedBehavior = Values.copy(director.selectedBehavior),
        behaviorSource = director.behaviorSource,
        beatCandidates = beatRows,
        beatCandidateCount = #sourceBeats,
        beatCandidatesTruncated = #sourceBeats > beatLimit,
        behaviorCandidates = behaviorRows,
        behaviorCandidateCount = behaviorCount,
        behaviorCandidatesTruncated = behaviorCount > behaviorLimit,
        oneShotBehaviorCandidates = oneShotRows,
        oneShotBehaviorCandidateCount = oneShotCount,
        oneShotBehaviorCandidatesTruncated = oneShotCount > oneShotLimit,
        contextBefore = Values.copy(beforeDialogue.director),
        contextAfter = Values.copy(afterDialogue.director),
        stateRevision = director.stateRevision,
    }
end

function Bounds.translation(context, translation)
    translation = type(translation) == "table" and translation or {}
    local source = type(translation.lookups) == "table"
        and translation.lookups or {}
    local lookups = {}
    local fallbackCount = 0
    local limit = math.min(#source, MAX_LOOKUPS)
    for index = 1, limit do
        local lookup = source[index]
        if type(lookup) == "table" then
            lookups[#lookups + 1] = {
                kind = lookup.kind,
                key = lookup.key,
                value = lookup.value,
                fallback = lookup.fallback,
                fallbackUsed = lookup.fallbackUsed == true,
                language = lookup.language,
            }
            if lookup.fallbackUsed == true then
                fallbackCount = fallbackCount + 1
            end
        end
    end
    return {
        language = translation.language,
        lookupCount = #source,
        fallbackCount = fallbackCount,
        truncated = #source > limit,
        lookups = lookups,
    }
end

function Bounds.sideEffects(context, transport, toolCalls)
    local Values = context.Values
    transport = type(transport) == "table" and transport or {}
    toolCalls = type(toolCalls) == "table" and toolCalls or {}
    local dispatches, facts = TransportEvidence.partition(transport)
    local function boundedEvents(events)
        local rows = {}
        for index = 1, math.min(#events, MAX_ACTIONS) do
            local event = events[index]
            if type(event) == "table" then
                rows[#rows + 1] = {
                    direction = event.direction, command = event.command,
                    eventName = event.eventName, mode = event.mode,
                }
            end
        end
        return rows
    end
    local commands = {}
    local limit = math.min(#transport, MAX_ACTIONS)
    for index = 1, limit do
        local event = transport[index]
        if type(event) == "table" then
            commands[#commands + 1] = {
                direction = event.direction,
                command = event.command,
                eventName = event.eventName,
                mode = event.mode,
            }
        end
    end
    local actions = {}
    local actionLimit = math.min(#toolCalls, MAX_ACTIONS)
    for index = 1, actionLimit do
        actions[#actions + 1] = Values.copy(toolCalls[index])
    end
    return {
        none = #transport == 0 and #toolCalls == 0,
        noGameplayEffects = #dispatches == 0 and #toolCalls == 0,
        factTransportCount = #facts,
        dispatchTransportCount = #dispatches,
        actionCount = #toolCalls,
        transportCount = #transport,
        actionsTruncated = #toolCalls > actionLimit,
        transportTruncated = #transport > limit,
        actions = actions,
        transport = commands,
        dispatchTransport = boundedEvents(dispatches),
        factTransport = boundedEvents(facts),
    }
end

return Bounds
