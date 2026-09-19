-- Shared diagnostic and tracing hooks for companion client actions.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal

local function publishLLMCommandResult(commandID, npcID, context,
        accepted, reason, targets)
    local feedback
    if type(context) ~= "table"
        or tostring(context.origin or context.commandSource or "")
            ~= "llm_tool"
    then
        return
    end
    feedback = PNC.NameplateToolFeedback
    if not feedback or not feedback.PushResult then
        pcall(require, "PNC/UI/Nameplates/PNC_NameplateToolFeedback")
        feedback = PNC.NameplateToolFeedback
    end
    if feedback and feedback.PushResult then
        feedback.PushResult({
            npcID = npcID,
            commandID = commandID,
            accepted = accepted == true,
            reason = reason,
            requestID = context.requestID,
            callID = context.callID,
            commandSource = "llm_tool",
            targets = targets,
        })
    end
end

local function traceCompanionCommand(commandID, npcId, scope, context, result)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if not trace or not trace.IsEnabled or not trace.IsEnabled() then
        return
    end
    local requestID = type(context) == "table" and context.requestID or nil
    trace.Record({
        source = "ProjectHoomans",
        event = "game.companion_command",
        requestID = requestID,
        data = {
            commandID = tostring(commandID or ""),
            npcID = npcId and tostring(npcId) or nil,
            scope = scope and tostring(scope) or nil,
            origin = type(context) == "table" and context.origin or nil,
            result = result,
        },
    })
end

local function campDiagnostics()
    local perceptionDebug = PNC.PerceptionDebug
    local diagnostics = perceptionDebug and perceptionDebug.CampDiagnostics or nil
    if diagnostics and type(diagnostics.RecordClient) == "function" then
        return diagnostics
    end
    pcall(require,
        "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics")
    debug = PNC.PerceptionDebug
    diagnostics = perceptionDebug and perceptionDebug.CampDiagnostics or nil
    return diagnostics
end

local function recordCampClient(status, reason, commandID, npcId, scope,
    context, hint)
    local diagnostics
    if tostring(commandID or "") ~= "camp" then return end
    diagnostics = campDiagnostics()
    if diagnostics and type(diagnostics.RecordClient) == "function" then
        diagnostics.RecordClient(status, reason, {
            commandID = commandID,
            npcID = npcId,
            scope = scope,
            requestID = type(context) == "table"
                and context.requestID or nil,
            commandSource = type(context) == "table" and (
                context.commandSource or context.source or context.origin)
                or nil,
        }, hint)
    end
end

local function recordCampServer(commandID, npcId, scope, context, accepted,
    reason, hint, details)
    local diagnostics
    if tostring(commandID or "") ~= "camp" then return end
    diagnostics = campDiagnostics()
    if diagnostics and type(diagnostics.RecordServer) == "function" then
        diagnostics.RecordServer({
            commandID = commandID,
            npcID = npcId,
            scope = scope,
            requestID = type(context) == "table"
                and context.requestID or nil,
            commandSource = type(context) == "table" and (
                context.commandSource or context.source or context.origin)
                or nil,
            accepted = accepted == true,
            reason = reason,
            campSiteHint = hint,
            details = details,
        })
    end
end

Internal.PublishLLMCommandResult = publishLLMCommandResult
Internal.TraceCompanionCommand = traceCompanionCommand
Internal.RecordCampClient = recordCampClient
Internal.RecordCampServer = recordCampServer

return Internal

