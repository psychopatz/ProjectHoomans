-- Optional structured semantic result handoff from PBrainZ.
-- Legacy response_text and semantic_tool_calls remain valid; this module only
-- activates when the provider includes a semantic IR payload.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local SemanticResult = Internal.SemanticResult or {}
Internal.SemanticResult = SemanticResult

local function contract()
    local semantics = PNC.Semantics
    return semantics and semantics.LLMResult or nil
end

local function hasPayload(arguments)
    return type(arguments) == "table"
        and (type(arguments.semantic_ir) == "table"
            or type(arguments.semanticIR) == "table"
            or type(arguments.ir) == "table")
end

local function now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs() or 0
end

function SemanticResult.Apply(pending, arguments)
    if not hasPayload(arguments) then return nil, "semantic_ir_missing" end
    local view = pending and pending.view
    local session = view and view.session
    local semanticPending = session and session.semanticDialoguePending
    local router = session and session.semanticDialogueRouter
    if not semanticPending or not router then
        return nil, "semantic_dialogue_pending_missing"
    end

    local adapter = contract()
    if not adapter or type(adapter.Process) ~= "function" then
        return nil, "semantic_result_contract_unavailable"
    end

    local packetContext = pending.packet
        and pending.packet.conversation_context or {}
    local context = {
        rawText = semanticPending.rawText,
        normalizedText = semanticPending.normalizedText,
        requestID = pending.requestID,
        llmEnabled = true,
        actor = {
            id = packetContext.player_uuid,
        },
        recipient = {
            id = pending.npcID,
        },
        npcID = pending.npcID,
        worldContext = packetContext.world_context,
        semanticDialogueState = packetContext.semantic_dialogue_state,
        currentTopic = packetContext.current_topic,
        previousTopic = packetContext.semantic_dialogue_state
            and packetContext.semantic_dialogue_state.previousTopic,
        semanticEntityIndex = packetContext.semantic_entity_index,
        semanticFactValues = packetContext.semantic_fact_values,
    }
    local result, ir = adapter.Process(router, arguments, context, {
        timestamp = now(),
    })
    if not result or result.accepted ~= true then
        return nil, result and result.reason or "semantic_result_rejected"
    end

    local input = PNC.Semantics and PNC.Semantics.DialogueInput
    local actionResult
    if input and input.Internal
        and type(input.Internal.DispatchAction) == "function"
    then
        actionResult = input.Internal.DispatchAction(
            view, result, semanticPending.rawText)
    end
    result.actionResult = actionResult
    result.provider = "llm"
    session.semanticDialogueIR = ir
    session.semanticDialogueResult = result
    session.semanticDialoguePending = nil
    view.lastSemanticDialogueResult = result
    return result
end

return SemanticResult
