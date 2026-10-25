-- Companion and semantic task command adapters for the harness.

return function(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local runtime = deps.runtime
    local PNC = _G.PNC

    PNC.Client.SendCompanionCommand = function(
        commandID, npcID, scope, commandContext
    )
        local responses = runtime.commandResponses or {}
        local configured = responses[tostring(commandID)]
        local accepted = true
        local reason = "network_queued"
        local targets = { tostring(npcID or "") }
        local details = {}
        if configured == false then
            accepted = false
            reason = "mock_command_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            reason = tostring(configured.reason
                or (accepted and "network_queued" or "mock_command_rejected"))
            targets = Values.copy(configured.targets or targets)
            details = Values.copy(configured.details or {})
        end
        if accepted and type(configured) == "table"
            and type(configured.state) == "table"
        then
            local patch = configured.state
            local scenario = Runtime.scenario or {}
            local npcState = type(patch.npc) == "table" and patch.npc or nil
            if npcState and type(scenario.npc) == "table" then
                for key, value in pairs(npcState) do
                    scenario.npc[key] = Values.copy(value)
                end
            end
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "CompanionCommand",
            payload = {
                commandID = tostring(commandID or ""),
                id = tostring(npcID or ""),
                scope = tostring(scope or ""),
                requestID = commandContext and commandContext.requestID,
                commandSource = commandContext and commandContext.commandSource,
                campSiteHint = commandContext
                    and Values.copy(commandContext.campSiteHint),
            },
        }
        return accepted, reason, targets, details
    end

    PNC.Client.RequestSemanticTask = function(request, context)
        request = type(request) == "table" and request or {}
        context = type(context) == "table" and context or {}
        local action = string.upper(tostring(request.action or ""))
        local responses = runtime.taskResponses or {}
        local configured = responses[action]
        local accepted = true
        local reason = "network_queued"
        local details = {}
        local target = request.target
        if action == "WAIT_AT"
            and (type(target) ~= "table"
                or target.unresolved == true
                or target.ambiguous == true)
        then
            accepted = false
            reason = "target_unresolved"
            details = { status = "rejected" }
        elseif configured == false then
            accepted = false
            reason = "mock_task_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            reason = tostring(configured.reason
                or (accepted and "network_queued" or "mock_task_rejected"))
            details = Values.copy(configured.details or {})
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticTaskRequest",
            payload = {
                action = action,
                npcID = request.npcID or context.npcID or context.targetID,
                scope = request.scope or context.scope or "single",
                requestID = request.requestID or context.requestID,
                commandSource = context.commandSource or "semantic_dialogue",
                target = Values.copy(target),
            },
        }
        return accepted, reason, details
    end
end
