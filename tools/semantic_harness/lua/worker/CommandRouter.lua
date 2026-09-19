-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}

local capabilities = {
    "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "SNAPSHOT", "PING", "CAPABILITIES", "QUIT",
}

function CommandRouter.hello(context)
    local Runtime = context.Runtime
    return {
        ok = true,
        type = "hello",
        worker = "project_hoomans_semantic_harness",
        capabilities = capabilities,
        loadedModules = Runtime.loadedModules,
        moduleManifest = Runtime.moduleManifest,
        headlessRequires = Runtime.headlessRequires,
        translation = context.OutputProjection.translationSnapshot(context),
    }
end

function CommandRouter.dispatch(context, request)
    local Runtime = context.Runtime
    local Values = context.Values
    local command = request.command
    local payload = request.payload

    if command == "CONFIG" then
        if type(payload) ~= "table" then
            return nil, "scenario_must_be_object"
        end
        return context.ScenarioSession.reset(context, payload)
    elseif command == "RESET" then
        return context.ScenarioSession.reset(context, Values.copy(Runtime.scenario))
    elseif command == "INPUT" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.turn(context, tostring(payload))
    elseif command == "LANGUAGE" then
        if payload == nil then return nil, "language_required" end
        return context.Translations.setLanguage(context,
            type(payload) == "table" and payload.language or payload)
    elseif command == "TOOL_REPLY" then
        return context.OutputProjection.toolReply(context, payload)
    elseif command == "SNAPSHOT" then
        return context.ScenarioSession.snapshot(context)
    elseif command == "PING" then
        return {
            ok = true,
            type = "pong",
            worker = "project_hoomans_semantic_harness",
            state = "ready",
        }
    elseif command == "CAPABILITIES" then
        return {
            ok = true,
            type = "capabilities",
            protocolVersion = context.Protocol.VERSION,
            capabilities = capabilities,
            loadedModules = Runtime.loadedModules,
            moduleManifest = Runtime.moduleManifest,
            headlessRequires = Runtime.headlessRequires,
            translation = context.OutputProjection.translationSnapshot(context),
        }
    elseif command == "QUIT" then
        return { ok = true, type = "closed" }, nil, true
    end

    return nil, "unknown_command:" .. tostring(command)
end

return CommandRouter
