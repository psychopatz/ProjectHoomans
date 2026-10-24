-- Bounded projections used by the observation envelope.

local Bounds = {}

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
        actionCount = #toolCalls,
        transportCount = #transport,
        actionsTruncated = #toolCalls > actionLimit,
        transportTruncated = #transport > limit,
        actions = actions,
        transport = commands,
    }
end

return Bounds
