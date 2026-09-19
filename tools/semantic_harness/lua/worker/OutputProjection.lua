-- Convert production traces and state into the harness response contract.

local OutputProjection = {}

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
