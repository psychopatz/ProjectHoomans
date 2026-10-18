-- Convert production traces and state into the harness response contract.

local OutputProjection = {}

local MAX_OBSERVATION_CANDIDATES = 8
local MAX_OBSERVATION_LOOKUPS = 32
local MAX_OBSERVATION_ACTIONS = 16
local MAX_OBSERVATION_PLAN_TURNS = 4

local function boundedCandidates(context, result)
    local Values = context.Values
    local bundle = result and result.candidates or {}
    local selected = type(bundle.selected) == "table"
        and bundle.selected or {}
    local list = type(bundle.candidates) == "table"
        and bundle.candidates or {}
    local candidates = {}
    local limit = math.min(#list, MAX_OBSERVATION_CANDIDATES)
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

local function boundedFlowSessions(snapshot)
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

local function boundedTranslation(context, translation)
    local Values = context.Values
    translation = type(translation) == "table" and translation or {}
    local source = type(translation.lookups) == "table"
        and translation.lookups or {}
    local lookups = {}
    local fallbackCount = 0
    local limit = math.min(#source, MAX_OBSERVATION_LOOKUPS)
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

local function boundedSideEffects(context, transport, toolCalls)
    local Values = context.Values
    transport = type(transport) == "table" and transport or {}
    toolCalls = type(toolCalls) == "table" and toolCalls or {}
    local commands = {}
    local limit = math.min(#transport, MAX_OBSERVATION_ACTIONS)
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
    local actionLimit = math.min(#toolCalls, MAX_OBSERVATION_ACTIONS)
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

function OutputProjection.observation(context, record)
    local Values = context.Values
    record = type(record) == "table" and record or {}
    local result = type(record.result) == "table" and record.result or {}
    local ir = type(result.ir) == "table" and result.ir or {}
    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local response = type(decision.response) == "table"
        and decision.response or {}
    local selectedCandidate = type((result.candidates or {}).selected) == "table"
        and result.candidates.selected or {}
    local responseObservation = {
        templateID = response.templateID,
        sourcePoolID = response.sourcePoolID,
        fallback = response.fallback,
        text = response.fallback,
        key = response.templateID,
        selectionSource = response.selectionSource,
        sourceFlowID = response.sourceFlowID,
        flowTransition = response.flowTransition,
        plan = Values.copy(response.plan),
        planTurnCount = type(response.plan) == "table"
            and math.min(#(response.plan.turns or {}),
                MAX_OBSERVATION_PLAN_TURNS) or 0,
        queued = {},
    }
    for _, message in ipairs(record.messages or {}) do
        if type(message) == "table" and message.speaker == "npc" then
            local payload = type(message.payload) == "table"
                and message.payload or {}
            local text = payload.text or payload.fallback
            local fallback = payload.fallback
                or responseObservation.fallback
            local queued = {
                text = text,
                fallback = fallback,
                key = payload.key or payload.translationKey,
                translationKey = payload.translationKey,
                translationKeys = Values.copy(payload.translationKeys),
                planTurn = payload.planTurn,
                planTurnID = payload.planTurnID,
                planContinuation = payload.planContinuation,
                translated = text ~= nil
                    and fallback ~= nil
                    and text ~= fallback,
            }
            if #responseObservation.queued < MAX_OBSERVATION_PLAN_TURNS then
                responseObservation.queued[#responseObservation.queued + 1] =
                    queued
            end
            if #responseObservation.queued == 1 then
                responseObservation.text = text
                responseObservation.fallback = fallback
                responseObservation.key = queued.key
                responseObservation.translationKey = queued.translationKey
                responseObservation.translationKeys = queued.translationKeys
                responseObservation.domain = payload.domain
                responseObservation.planTurn = queued.planTurn
                responseObservation.planTurnID = queued.planTurnID
                responseObservation.planContinuation = queued.planContinuation
                responseObservation.translated = queued.translated
            end
        end
    end
    responseObservation.queueCount = #responseObservation.queued
    responseObservation.composed = responseObservation.queueCount > 1
    responseObservation.flowResponsePoolID = flow.responsePool
    return {
        schemaVersion = 1,
        input = tostring(record.input or ""),
        accepted = record.accepted == true,
        reason = record.reason,
        ir = {
            intent = ir.intent,
            speechAct = ir.speechAct,
            action = ir.action,
            subject = ir.subject,
            confidence = ir.confidence,
            normalizedText = ir.normalizedText,
            pattern = ir.provenance and ir.provenance.pattern,
        },
        candidates = boundedCandidates(context, result),
        response = responseObservation,
        flow = {
            flowId = flow.flowId,
            fromNodeId = flow.fromNodeId,
            toNodeId = flow.toNodeId or flow.nodeId,
            transition = flow.transition,
            status = flow.status,
            committed = flow.committed == true,
            gateStatus = flow.gate and flow.gate.status,
            gateReason = flow.gate and flow.gate.reason,
            gate = Values.copy(flow.gate),
            responsePoolID = flow.responsePool,
            resumedFlowId = flow.resumedFlowId,
            completedFlowId = flow.completedFlowId,
            activeBefore = boundedFlowSessions(record.contextBefore),
            activeAfter = boundedFlowSessions(record.contextAfter),
        },
        translation = boundedTranslation(context, record.translation),
        sideEffects = boundedSideEffects(
            context, record.transport, record.toolCalls
        ),
        context = {
            currentTopic = record.contextAfter
                and record.contextAfter.dialogue
                and record.contextAfter.dialogue.currentTopic,
            pendingIdentityExchange = record.contextAfter
                and record.contextAfter.dialogue
                and record.contextAfter.dialogue.pendingIdentityExchange,
            engineFacts = Values.copy(record.contextAfter
                and record.contextAfter.engineFacts),
            engineEvents = Values.copy(record.contextAfter
                and record.contextAfter.engineEvents),
        },
        selectedCandidate = {
            patternID = selectedCandidate.patternID,
            score = selectedCandidate.score or selectedCandidate.confidence,
        },
    }
end

function OutputProjection.normalizedToolCalls(context, trace, transport, result, actionResult)
    local Values = context.Values
    local calls = {}
    local labels = {
        KnowledgeDisclosureRequest = "ask_name",
        SemanticIdentityRequest = "validate_identity",
        SemanticInventoryQuery = "query_inventory",
        InventoryTransfer = "transfer_item",
        CompanionCommand = "companion_command",
        AdjustRelationship = "adjust_relationship",
    }
    local function add(kind, name, values)
        name = tostring(name or "")
        if name == "" then return end
        values = type(values) == "table" and values or {}
        calls[#calls + 1] = {
            kind = kind,
            name = name,
            label = labels[name] or name,
            callID = values.callID or values.call_id or values.id,
            requestID = values.requestID or values.request_id
                or result and result.sequence,
            arguments = Values.copy(values.arguments or values.args),
            status = values.status
                or (values.accepted == true and "accepted" or nil),
            accepted = values.accepted,
            reason = values.reason,
            authority = values.authority or values.mode or "mock",
            source = values.source or "production_trace",
        }
    end

    for _, event in ipairs(trace or {}) do
        local eventName = tostring(event and event.event or "")
        local data = event and event.data or {}
        if string.find(eventName, "tool", 1, true)
            or string.find(eventName, "command.dispatch", 1, true)
            or string.find(eventName, "task.dispatch", 1, true)
        then
            add(string.find(eventName, "tool", 1, true)
                    and "tool_call" or "action_dispatch",
                data.name or data.toolName or data.tool
                    or data.action or data.commandID or data.command,
                data)
        end
    end

    if type(actionResult) == "table" then
        add("action_dispatch", actionResult.action or actionResult.commandID
            or actionResult.taskID, actionResult)
    end

    for _, event in ipairs(transport or {}) do
        local command = event and event.command
        if command == "SemanticIdentityRequest"
            or command == "KnowledgeDisclosureRequest"
            or command == "SemanticInventoryQuery"
            or command == "InventoryTransfer"
        then
            add("authority_request", command, {
                arguments = event.payload,
                authority = event.mode or "mock",
                source = "transport",
                status = "sent",
            })
        elseif event.direction == "server_to_client"
            and type(event.payload) == "table"
            and type(event.payload.relationshipDelta) == "table"
        then
            add("relationship_adjustment", "AdjustRelationship", {
                arguments = event.payload,
                authority = "server",
                source = "transport",
                status = "applied",
                accepted = true,
            })
        end
    end
    return calls
end

function OutputProjection.translationSnapshot(context)
    return context.Translations.snapshot(context)
end

function OutputProjection.toolReply(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    payload = type(payload) == "table" and payload or {}
    local results = type(payload.results) == "table"
        and payload.results or {}
    local replies = PNC.Conversation
        and PNC.Conversation.ToolReplies or nil
    if not replies or type(replies.Build) ~= "function" then
        return { ok = false, error = "tool_reply_catalog_unavailable" }
    end
    local before = #Runtime.translationLookups
    local value = replies.Build(results, payload.context or {})
    local toolName = ""
    for _, result in ipairs(results) do
        local name = tostring(result and result.name or "")
        if name == "ask_name" then
            toolName = name
            break
        end
        if toolName == "" and name == "social_react" then
            toolName = name
        elseif toolName == "" and string.sub(name, 1, 6) == "order_" then
            toolName = name
        end
    end
    local lookups = {}
    for index = before + 1, #Runtime.translationLookups do
        lookups[#lookups + 1] = Values.copy(Runtime.translationLookups[index])
    end
    return {
        ok = true,
        type = "tool_reply",
        language = context.Translations.currentLanguage(context),
        text = value,
        results = Values.copy(results),
        toolCalls = {
            {
                kind = "tool_call",
                name = toolName,
                label = toolName,
                status = "resolved",
                source = "production_tool_reply_catalog",
            },
        },
        translationLookups = lookups,
        loadedModules = Runtime.loadedModules,
    }
end

return OutputProjection
