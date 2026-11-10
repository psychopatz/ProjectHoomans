-- Scenario-backed cognition adapter with production transport semantics.

return function(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local npcData = deps.npcData
    local runtime = deps.runtime
    local PNC = _G.PNC

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
        local expectedTarget = type(configured) == "table"
            and (configured.targetID or configured.target) or nil
        if configured == nil or configured == false then
            return false, "cognition_unavailable"
        end
        if expectedTarget ~= nil
            and tostring(args.targetID or "") ~= tostring(expectedTarget)
        then
            return false, "cognition_target_unavailable"
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticCognitionRequest",
            payload = Values.copy(args),
        }
        local projection = {}
        local worldKnowledge = runtime.worldKnowledge
        if type(worldKnowledge) == "table"
            and PNC.WorldKnowledge
            and type(PNC.WorldKnowledge.BuildConversationContext) == "function"
        then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(args.npcID) or npcData
            local context = PNC.WorldKnowledge.BuildConversationContext(record, {
                language = runtime.language,
                now = Runtime.now,
                max = 4,
            })
            local worldGossip = context and context.npcGossip or {}
            projection._worldKnowledgeGossip = {
                subject = "world",
                statements = Values.copy(worldGossip.statements or {}),
                factRefs = Values.copy(worldGossip.factRefs or {}),
                candidates = context and context.worldKnowledge
                    and Values.copy(context.worldKnowledge.candidates) or {},
                scenarioOwned = true,
            }
            Runtime.worldKnowledgeLastContext = Values.copy(context)
        elseif type(gossip) == "table" then
            projection._memoryGossip = {
                subject = gossip.subject,
                codes = Values.copy(gossip.codes or {}),
            }
        end
        local network = PNC.Network
        if network and type(network.SendSemanticCognition) == "function" then
            local responseRequestID = type(configured) == "table"
                and (configured.responseRequestID or args.requestID)
                or args.requestID
            local responseTargetID = type(configured) == "table"
                and (configured.responseTargetID or args.targetID)
                or args.targetID
            network.SendSemanticCognition(
                dispatchPlayer,
                projection,
                tostring(configured.reason or "harness_authoritative"),
                responseRequestID,
                args.npcID,
                responseTargetID
            )
            return true, "harness_authoritative"
        end
        return false, "cognition_transport_unavailable"
    end
end
