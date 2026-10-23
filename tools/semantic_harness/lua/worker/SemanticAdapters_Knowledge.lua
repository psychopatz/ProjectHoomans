local Provider = {}
Provider.productionQuestRequest = nil

local function configureWorldKnowledge(context, Runtime, Values, npcData, runtime)
    local Adapter = PNC.WorldKnowledge
    local core = Adapter and Adapter.Core or nil
    if not core then return end
    if type(core.Reset) == "function" then
        core.Reset({
            maxFacts = runtime.worldKnowledge
                and runtime.worldKnowledge.maxFacts or nil,
            maxRefs = runtime.worldKnowledge
                and runtime.worldKnowledge.maxRefs or nil,
        })
    end
    if type(Adapter.ResetWorldStateRuntime) == "function" then
        Adapter.ResetWorldStateRuntime()
    end
    Runtime.worldKnowledgeScenario = nil
    local fixture = runtime.worldKnowledge
    if type(fixture) ~= "table" then return end

    local records = {}
    local originalGet = PNC.Registry and PNC.Registry.Get
    local function addRecord(record)
        if type(record) ~= "table" then return end
        record.id = record.id or record.npcID
        record.npcID = record.npcID or record.id
        record.coreActorID = record.coreActorID
            or ("actor:" .. tostring(record.id or "unknown"))
        records[tostring(record.id or "")] = record
        records[tostring(record.coreActorID or "")] = record
    end
    -- SAVE imports must expose the production-hydrated record to knowledge
    -- and downstream services. The scenario projection remains an engine/UI
    -- view, never a second Hoomans registry record.
    addRecord(Runtime.hydratedNpcRecord or npcData)
    if type(fixture.actors) == "table" then
        for key, value in pairs(fixture.actors) do
            if type(value) == "table" then
                value.id = value.id or (type(key) == "string" and key or nil)
                addRecord(value)
            end
        end
    end
    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Get = function(id)
        return records[tostring(id or "")]
            or (type(originalGet) == "function" and originalGet(id) or nil)
    end

    local facts = {}
    local factByIndex = {}
    if type(fixture.facts) == "table" then
        for index = 1, #fixture.facts do
            local specification = Values.copy(fixture.facts[index])
            if type(specification) == "table" then
                specification.producer = specification.producer
                    or "semantic_lab:scenario"
                specification.payload = specification.payload or {}
                specification.payload.scenarioOwned = true
                local fact = core.Publish(specification)
                if fact then
                    facts[#facts + 1] = fact
                    factByIndex[index] = fact
                end
            end
        end
    end
    local acquisitions = {}
    if type(fixture.acquisitions) == "table" then
        for index = 1, #fixture.acquisitions do
            local item = fixture.acquisitions[index]
            local fact = item and factByIndex[item.factIndex]
            local target = item and records[tostring(item.actorID or "")]
            if fact and target then
                local reference = core.Acquire(target.coreActorID, fact.factID, {
                    authorized = true,
                    provenance = item.provenance or "witnessed",
                    confidence = item.confidence or 0.9,
                    sourceActorID = item.sourceActorID,
                    source = item.source or "semantic_lab_scenario",
                    acquisitionPath = item.acquisitionPath or "scenario_authority",
                    learnedAt = item.learnedAt or Runtime.now,
                })
                if reference then
                    acquisitions[#acquisitions + 1] = {
                        actorID = target.coreActorID,
                        factID = fact.factID,
                        reference = reference,
                    }
                end
            end
        end
    end
    Runtime.worldKnowledgeScenario = {
        scenarioOwned = true,
        facts = Values.copy(facts),
        actors = Values.copy(records),
        acquisitions = Values.copy(acquisitions),
    }
end

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

    configureWorldKnowledge(context, Runtime, Values, npcData, runtime)

    -- The server-side semantic validators and client result router stay real.
    PNC.Client = PNC.Client or {}
    PNC.Client.Internal = PNC.Client.Internal or {}
    if type(Runtime.productionQuestRequest) == "function" then
        Provider.productionQuestRequest = Runtime.productionQuestRequest
    elseif #Runtime.loadedModules > 0
        and type(PNC.Client.RequestSemanticQuest) == "function"
    then
        Provider.productionQuestRequest = PNC.Client.RequestSemanticQuest
    end
    PNC.Core.IsClientOnly = function()
        return runtime.mode == "multiplayer"
    end
    -- The worker is a dual-role production boundary: multiplayer client
    -- calls are queued through the client transport, while the same worker
    -- hosts the canonical server handlers for the authoritative leg. Keep
    -- the server-side Core predicate explicit instead of inheriting the
    -- native headless runtime role, which has no game server process.
    PNC.Core.IsAuthority = function()
        return true
    end
    -- Exercise the real Knowledge commit path while keeping the worker
    -- independent from the native world-save coordinator. This is a bounded
    -- persistence seam, not a second journal or a replacement authority.
    PNC.PersistenceCoordinator = PNC.PersistenceCoordinator or {}
    PNC.PersistenceCoordinator.Commit = function(reason)
        Runtime.persistenceCommits = Runtime.persistenceCommits or {}
        Runtime.persistenceCommits[#Runtime.persistenceCommits + 1] =
            tostring(reason or "worker")
        local knowledge = PNC.NPCKnowledge
        if not knowledge or type(knowledge.Save) ~= "function" then
            return false, "knowledge_persistence_unavailable"
        end
        local saved, saveReason = knowledge.Save(false)
        if saved == false and saveReason == "not_dirty" then
            return true, "not_dirty"
        end
        return saved, saveReason
    end
    PNC.MedicalCareService = PNC.MedicalCareService or {}
    PNC.MedicalCareService.List = function()
        if runtime.questEligible == false then return {} end
        return {
            {
                id = "medical-supply-task-1",
                status = "WAITING_FOR_SUPPLY",
                blockedReason = "missing_bandage",
                supplyRequesterId = npcData.npcID,
            },
        }
    end
    PNC.Tasking = PNC.Tasking or {}
    PNC.Tasking.Events = PNC.Tasking.Events or {}
    if type(PNC.Tasking.Events.Emit) ~= "function" then
        PNC.Tasking.Events.Emit = function() return true end
    end
    local productionKnowledgeRequest = Runtime.productionKnowledgeRequest
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
        if type(productionKnowledgeRequest) == "function" then
            return productionKnowledgeRequest(npcID, topicID, options)
        end
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

    -- The worker keeps the production semantic/action/response path intact
    -- and replaces only the remote authoritative quest reply with bounded
    -- scenario data, just as it does for companion and task handlers.
    local harnessRequestSemanticQuest = function(request, context)
        request = type(request) == "table" and request or {}
        context = type(context) == "table" and context or {}
        local operation = string.lower(tostring(request.operation or ""))
        local configured = runtime.questResponses
            and runtime.questResponses[operation]
        local accepted = true
        local status = operation == "offer" and "available"
            or operation == "accept" and "accepted"
            or operation == "status" and "active"
            or operation == "turn_in" and "rewarded" or "failed"
        local reason = operation == "offer" and "available"
            or operation == "accept" and "accepted"
            or operation == "status" and "status_returned"
            or operation == "turn_in" and "rewarded" or "quest_operation_invalid"
        local details = {}
        if configured == false then
            accepted = false
            status = "rejected"
            reason = "mock_quest_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            status = tostring(configured.status or status)
            reason = tostring(configured.reason
                or (accepted and reason or "mock_quest_rejected"))
            details = Values.copy(configured)
        end
        local result = details.result and Values.copy(details.result)
            or details
        result.accepted = accepted
        result.status = status
        result.reason = reason
        result.requestID = result.requestID or request.requestID
        result.npcID = result.npcID or request.npcID or context.npcID
        result.giverNPCID = result.giverNPCID or result.npcID
        result.questID = result.questID
            or request.questID or "pnc.quest.clinic_supplies"
        result.operation = result.operation or operation
        result.responsePoolID = result.responsePoolID
            or "semantic.quest.clinic_supplies." .. operation
        result.objective = result.objective or {
            id = "deliver_bandage",
            required = 1,
            delivered = (status == "ready" or status == "rewarded") and 1 or 0,
            itemFullType = "Base.Bandage",
            direction = "player_to_npc",
        }
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticQuestRequest",
            payload = Values.copy(request),
        }
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = runtime.mode,
            command = "SemanticQuestResult",
            payload = Values.copy(result),
        }
        return accepted, reason, result
    end
    if runtime.mode == "multiplayer"
        and type(Provider.productionQuestRequest) == "function"
    then
        Runtime.questBoundary = "production"
        local productionRequest = Provider.productionQuestRequest
        local productionWrapper = function(request, context)
            return productionRequest(request, context)
        end
        Runtime.questProductionWrapper = productionWrapper
        PNC.Client.RequestSemanticQuest = productionWrapper
    else
        Runtime.questBoundary = "harness"
        PNC.Client.RequestSemanticQuest = harnessRequestSemanticQuest
    end
end

return Provider
