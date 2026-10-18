local Provider = {}

function Provider.configure(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local number = deps.number
    local playerData = deps.playerData
    local npcData = deps.npcData
    local runtime = deps.runtime
    local player = deps.player
    local identityName = deps.identityName
    local relationshipFor = deps.relationshipFor
    local relationshipSnapshotFor = deps.relationshipSnapshotFor
    local PNC = _G.PNC

    -- The server-side semantic validators and client result router stay real.
    PNC.Client = PNC.Client or {}
    PNC.Client.Internal = PNC.Client.Internal or {}
    PNC.Core.IsClientOnly = function()
        return runtime.mode == "multiplayer"
    end
    PNC.Client.RequestNPCKnowledgeTopic = function(npcID, topicID, options)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "KnowledgeDisclosureRequest",
            payload = {
                npcID = npcID,
                topicID = topicID,
                options = Values.copy(options),
            },
        }
        return true
    end
    local Commands = PNC.PlayerKnowledgeCommands
    if not Commands.__semanticIdentityHarnessBridge then
        local handleIdentity = Commands.HandleSemanticIdentity
        if type(handleIdentity) == "function" then
            Commands.HandleSemanticIdentity = function(
                dispatchPlayer, args
            )
                Runtime.transport[#Runtime.transport + 1] = {
                    direction = "client_to_server",
                    mode = (Runtime.scenario
                        and Runtime.scenario.runtime or {}).mode,
                    command = PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST,
                    payload = Values.copy(args),
                }
                return handleIdentity(dispatchPlayer, args)
            end
            Commands.__semanticIdentityHarnessBridge = true
        end
    end

    -- Model the already-authoritative cognition service at the worker
    -- boundary. The response is scenario-owned test evidence; production
    -- cognition still arrives through the normal client request and server
    -- payload path, and no client-side fact is invented.
    PNC.Semantics = PNC.Semantics or {}
    PNC.Semantics.CognitionService = PNC.Semantics.CognitionService or {}
    PNC.Semantics.CognitionService.HandleRequest = function(
        dispatchPlayer, args
    )
        args = type(args) == "table" and args or {}
        local responses = runtime.semanticCognitionResponses or {}
        local configured = responses[string.upper(tostring(args.subject or ""))]
        local gossip = type(configured) == "table"
            and configured.gossip or nil
        if configured == nil or configured == false then
            return false, "cognition_unavailable"
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticCognitionRequest",
            payload = Values.copy(args),
        }
        local projection = {}
        if type(gossip) == "table" then
            projection._memoryGossip = {
                subject = gossip.subject,
                codes = Values.copy(gossip.codes or {}),
            }
        end
        local network = PNC.Network
        if network and type(network.SendSemanticCognition) == "function" then
            network.SendSemanticCognition(
                dispatchPlayer,
                projection,
                tostring(configured.reason or "harness_authoritative"),
                args.requestID,
                args.npcID
            )
            return true, "harness_authoritative"
        end
        return false, "cognition_transport_unavailable"
    end

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

return Provider
