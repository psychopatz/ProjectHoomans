-- Command and tool registration for the Core bridge.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Internal = PNC.HoomansLLM.Internal
local Registration = Internal.BridgeRegistration or {}
Internal.BridgeRegistration = Registration
local TOOL_NAMESPACE = "projecthoomans.llm"

local function registerToolCatalog(bridge, context)
    if type(bridge.RegisterTool) ~= "function"
        or not context or type(context.GetToolDefinitions) ~= "function"
    then
        return false, "catalog_api_unavailable"
    end
    local definitions = context.GetToolDefinitions()
    for _, tool in ipairs(definitions or {}) do
        local definition = tool and tool["function"] or nil
        local name = definition and tostring(definition.name or "") or ""
        if name ~= "" then
            local ok, reason = bridge.RegisterTool(
                TOOL_NAMESPACE, name, tool, { kind = "llm_tool" }
            )
            if not ok and reason ~= "duplicate_tool" then
                return false, tostring(reason or "registration_failed")
            end
        end
    end
    return true, "registered"
end

function Registration.Register(bridge, integration, context, memorySync)
    if not bridge or type(bridge.RegisterCommand) ~= "function" then
        return false, "unavailable"
    end
    local catalogAvailable, catalogReason = registerToolCatalog(bridge, context)
    local pollOK, pollReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "pollChat", {
            readOnly = false,
            category = "LLM",
            handler = function() return integration.Poll() end,
        }
    )
    local deliverOK, deliverReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "deliverChat", {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return integration.Deliver(arguments)
            end,
        }
    )
    local pollAvailable = pollOK == true or pollReason == "duplicate_command"
    local deliverAvailable = deliverOK == true
        or deliverReason == "duplicate_command"
    local syncPollOK, syncPollReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "pollConversationSync", {
            readOnly = true,
            category = "LLM",
            handler = function() return memorySync.Poll() end,
        }
    )
    local syncAckOK, syncAckReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "ackConversationSync", {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return memorySync.Ack(arguments)
            end,
        }
    )
    local memorySyncAvailable =
        (syncPollOK == true or syncPollReason == "duplicate_command")
        and (syncAckOK == true or syncAckReason == "duplicate_command")
    local startedOK, startedReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "speechStarted", {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return integration.SpeechStarted(arguments)
            end,
        }
    )
    local finishedOK, finishedReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "speechFinished", {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return integration.SpeechFinished(arguments)
            end,
        }
    )
    local fallbackOK, fallbackReason = bridge.RegisterCommand(
        TOOL_NAMESPACE, "speechFallback", {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return integration.SpeechFallback(arguments)
            end,
        }
    )
    local speechEventsAvailable =
        (startedOK == true or startedReason == "duplicate_command")
        and (finishedOK == true or finishedReason == "duplicate_command")
        and (fallbackOK == true or fallbackReason == "duplicate_command")
    return pollAvailable and deliverAvailable,
        {
            catalogAvailable = catalogAvailable,
            catalogReason = catalogReason,
            pollReason = pollReason,
            deliverReason = deliverReason,
            syncPollReason = syncPollReason,
            syncAckReason = syncAckReason,
            startedReason = startedReason,
            finishedReason = finishedReason,
            fallbackReason = fallbackReason,
            memorySyncAvailable = memorySyncAvailable,
            speechEventsAvailable = speechEventsAvailable,
        }
end

return Registration
