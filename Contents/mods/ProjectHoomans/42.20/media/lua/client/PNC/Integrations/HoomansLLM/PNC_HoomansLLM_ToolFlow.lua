-- Semantic tool dispatch and shared tool-catalog validation.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolFlow = Internal.ToolFlow or {}
Internal.ToolFlow = ToolFlow
Internal.ToolHandlers = Internal.ToolHandlers or {}
local Handlers = Internal.ToolHandlers
local Trace = PsychopatzCore and PsychopatzCore.DebugTrace

function ToolFlow.Exposed(packet, name)
    local context = packet and packet.conversation_context or {}
    local tools = context.available_tools or {}
    for _, tool in ipairs(tools) do
        local definition = tool and tool["function"] or nil
        if definition and tostring(definition.name or "") == name then
            return true
        end
    end
    local toolIDs = context.available_tool_ids or {}
    local expectedID = "projecthoomans.llm:" .. tostring(name or "")
    for _, toolID in ipairs(toolIDs) do
        if tostring(toolID) == expectedID then return true end
    end
    return false
end

local function handlerFor(name)
    local handler = Handlers[name]
    if not handler and string.find(name, "^order_") == 1 then
        handler = Handlers.order
    end
    return handler
end

function ToolFlow.Apply(packet, arguments, npcID, session)
    local calls = arguments and arguments.semantic_tool_calls
    local results = {}
    if type(calls) ~= "table" then return results end
    Runtime.Log(
        "tool_calls_received",
        "npc=" .. tostring(npcID)
            .. " request=" .. tostring(packet and packet.request_id)
            .. " count=" .. tostring(#calls)
    )
    for index, call in ipairs(calls) do
        local name = Runtime.Trim(call and call.name)
        local callID = Runtime.Trim(call and call.id)
        if callID == "" then callID = "tool_" .. tostring(index) end
        local callArguments = call and type(call.arguments) == "table"
            and call.arguments or {}
        local result = {
            id = callID,
            name = name,
            accepted = false,
        }
        local handler = handlerFor(name)
        if handler then
            handler(result, packet, npcID, callArguments, callID)
        else
            result.reason = "tool_not_exposed"
        end
        Runtime.Log(
            "tool_call_result",
            "npc=" .. tostring(npcID)
                .. " request=" .. tostring(packet and packet.request_id)
                .. " id=" .. tostring(callID)
                .. " name=" .. tostring(name)
                .. " reaction=" .. tostring(result.reaction or "")
                .. " accepted=" .. tostring(result.accepted == true)
                .. " reason=" .. tostring(result.reason or "")
        )
        results[#results + 1] = result
    end
    if session then session.llmSemanticResults = results end
    if Runtime.TraceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.tool_results",
            requestID = packet and packet.request_id,
            data = {
                npcID = npcID,
                calls = calls,
                results = results,
            },
        })
    end
    return results
end

return ToolFlow
