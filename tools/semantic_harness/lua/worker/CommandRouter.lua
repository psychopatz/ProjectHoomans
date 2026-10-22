-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return true end
    return false
end

local capabilities = {
    "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "FLOW_CATALOG", "FLOW_VALIDATE",
    "SUGGESTION_PREDICATE", "SUGGESTION_CLICK",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
    "KNOWLEDGE_BOOTSTRAP", "KNOWLEDGE_DISCOVER", "KNOWLEDGE_METRICS",
    "WORLD_KNOWLEDGE_INSPECT", "WORLD_KNOWLEDGE_PROPAGATE",
}

local function backstorySnapshot(payload)
    local memory = PNC.Conversation and PNC.Conversation.Memory
    if not memory or type(memory.GetBackstoryProfile) ~= "function" then
        return nil, "backstory_memory_unavailable"
    end
    payload = type(payload) == "table" and payload or {}
    local record = {
        id = tostring(payload.npcID or "harness-backstory-npc"),
        tacticalClass = tostring(payload.tacticalClass or "colonist"),
        identity = {
            seed = payload.identitySeed,
        },
    }
    local profile = memory.GetBackstoryProfile(record)
    if type(profile) ~= "table" then
        return nil, "backstory_profile_unavailable"
    end
    local facts = {}
    for kind, fact in pairs(profile.facts or {}) do
        if type(fact) == "table" then
            facts[kind] = {
                id = fact.id,
                kind = fact.kind,
                class = fact.class,
                value = fact.value,
                textKey = fact.textKey,
            }
        end
    end
    return {
        ok = true,
        type = "backstory",
        profile = {
            identitySeed = profile.identitySeed,
            tacticalClass = profile.tacticalClass,
            facts = facts,
        },
    }
end

local function backstoryFact(payload)
    local facts = PNC.Semantics and PNC.Semantics.DialogueFacts
    local result
    payload = type(payload) == "table" and payload or {}
    if not facts or type(facts.Resolve) ~= "function" then
        return nil, "dialogue_fact_registry_unavailable"
    end
    result = facts.Resolve({
        subject = "NPC_BACKSTORY",
        slots = { kind = payload.kind or payload.topic },
    }, nil, {
        npcRecord = {
            id = tostring(payload.npcID or "harness-backstory-npc"),
            tacticalClass = tostring(payload.tacticalClass or "colonist"),
            identitySeed = payload.identitySeed,
            identity = { seed = payload.identitySeed },
        },
        language = payload.language,
        authoritativeBackstoryAccess = true,
    })
    return {
        ok = true,
        type = "backstory_fact",
        fact = result,
    }
end

local function knowledgeMetrics(context, payload)
    local knowledge = PNC.NPCKnowledge
    local syntheticNPCs = math.min(
        1000,
        math.max(0, math.floor(tonumber(
            type(payload) == "table" and payload.syntheticNPCs or 0
        ) or 0))
    )
    local factsPerNPC = math.min(
        32,
        math.max(1, math.floor(tonumber(
            type(payload) == "table" and payload.factsPerNPC or 1
        ) or 1))
    )
    local descriptorIDs = {
        "personality.social_style",
        "personality.compassion",
        "personality.sociability",
        "personality.forgiveness",
        "personality.bravery",
        "personality.materialism",
        "personality.aggression",
        "personality.loyalty",
        "personality.compassion",
        "personality.sociability",
    }
    local recorded = 0
    local index
    local factIndex
    if not knowledge or type(knowledge.EnsureLoaded) ~= "function"
        or type(knowledge.RecordEvidence) ~= "function"
    then
        return nil, "knowledge_metrics_unavailable"
    end
    knowledge.EnsureLoaded()
    for index = 1, syntheticNPCs do
        for factIndex = 1, factsPerNPC do
            local descriptorID = descriptorIDs[
                ((factIndex - 1) % #descriptorIDs) + 1
            ]
            local result = knowledge.RecordEvidence({
                characterUUID = context.playerData.characterUUID,
                npcID = "harness-synthetic-npc-" .. tostring(index),
                descriptorID = descriptorID,
                sourceType = "observed_behavior",
                direction = 1,
                strength = 0.5,
                reliability = 0.75,
                sourceEventID = "harness-metrics-"
                    .. tostring(index) .. "-" .. tostring(factIndex),
                payload = { observedValue = "synthetic" },
            })
            if result then recorded = recorded + 1 end
        end
    end
    if recorded > 0 and type(knowledge.Save) == "function" then
        knowledge.Save(false)
    end

    local raw = ModData and type(ModData.get) == "function"
        and ModData.get("PNC_NPCKnowledge") or nil
    local canonicalKnowledge = type(knowledge.Registry) == "table"
        and knowledge.Registry or raw
    local hasKnowledge = canonicalKnowledge
        and type(canonicalKnowledge.byCharacter) == "table"
        and hasEntries(canonicalKnowledge.byCharacter)
    local knowledgeSerialized = hasKnowledge
        and context.Protocol.encode(canonicalKnowledge) or ""
    local modDataSerialized = raw and context.Protocol.encode(raw) or ""
    local registry = PNC.Registry
    local actor = registry and type(registry.Get) == "function"
        and registry.Get(context.npcData and context.npcData.npcID) or nil
    actor = type(actor) == "table" and actor or context.npcData or {}
    local backstoryMetadata = type(actor.identity) == "table"
        and actor.identity.backstory or nil
    local actorSerialized = context.Protocol.encode(actor)
    local backstorySerialized = backstoryMetadata
        and context.Protocol.encode(backstoryMetadata) or ""
    local combinedSerialized = context.Protocol.encode({
        npc = actor,
        playerKnowledge = hasKnowledge and canonicalKnowledge or nil,
    })
    local characterCount = 0
    local npcCount = 0
    local evidenceCount = 0
    local knowledgeRegistry = hasKnowledge
        and canonicalKnowledge.byCharacter or {}
    for _ in pairs(knowledgeRegistry) do characterCount = characterCount + 1 end
    for _, character in pairs(knowledgeRegistry) do
        for _, note in pairs(character.byNPC or {}) do
            npcCount = npcCount + 1
            evidenceCount = evidenceCount + #(note.evidence or {})
        end
    end
    return {
        ok = true,
        type = "knowledge_metrics",
        modDataKey = "PNC_NPCKnowledge",
        serializedBytes = #knowledgeSerialized,
        actorStorageBytes = #actorSerialized,
        backstoryMetadataBytes = #backstorySerialized,
        knowledgeStorageBytes = #knowledgeSerialized,
        combinedStorageBytes = #combinedSerialized,
        modDataSnapshotBytes = #modDataSerialized,
        actorRecordPresent = hasEntries(actor),
        backstoryMetadataPresent = backstoryMetadata ~= nil,
        persisted = raw ~= nil,
        characterCount = characterCount,
        npcCount = npcCount,
        evidenceCount = evidenceCount,
        syntheticNPCsRequested = syntheticNPCs,
        syntheticEvidenceRecorded = recorded,
        encoding = "worker_protocol_json_of_production_npc_and_moddata_tables",
        registryRevision = raw and raw.revision or 0,
    }
end

local function knowledgeDiscover(context, payload)
    local knowledge = PNC.NPCKnowledge
    payload = type(payload) == "table" and payload or {}
    if not knowledge or type(knowledge.DiscoverTopicForPlayer) ~= "function" then
        return nil, "knowledge_discovery_unavailable"
    end
    local topicID = tostring(payload.topicID or "")
    if topicID == "" then return nil, "knowledge_topic_required" end
    local result, reason = knowledge.DiscoverTopicForPlayer(
        context.player,
        tostring(payload.npcID or context.npcData.npcID),
        topicID,
        tonumber(payload.worldAgeHours or context.world.worldAgeHours) or 0,
        "direct_disclosure",
        false
    )
    if not result then return nil, reason end
    return {
        ok = true,
        type = "knowledge_discovery",
        topicID = topicID,
        result = result,
    }
end

local function worldKnowledgeInspect(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    local adapter = PNC.WorldKnowledge
    local core = adapter and adapter.Core or nil
    local ledger
    local knowledge
    local facts
    local actors = {}
    local actorID
    local actorRecord
    local worldContext
    payload = type(payload) == "table" and payload or {}
    if not core or not core.LedgerState or not core.KnowledgeState then
        return nil, "world_knowledge_unavailable"
    end
    ledger = core.Ledger
    knowledge = core.ActorKnowledge
    facts = ledger.Query(core.LedgerState, {
        max = math.min(64, math.max(1, math.floor(
            tonumber(payload.maxFacts) or 32))),
    })
    for id, entry in pairs(core.KnowledgeState.byActor or {}) do
        local row = { actorID = id, references = {}, explanations = {} }
        for index = 1, math.min(#(entry.order or {}), 64) do
            local factID = entry.order[index]
            local reference = knowledge.Get(core.KnowledgeState,
                id, factID)
            if reference then
                row.references[#row.references + 1] = reference
                local explanation = core.Explain(id, factID, Runtime.now)
                if explanation then
                    row.explanations[#row.explanations + 1] = explanation
                end
            end
        end
        actors[#actors + 1] = row
        if tostring(payload.actorID or "") ~= ""
            and tostring(payload.actorID) == tostring(id)
        then
            actorID = id
        end
    end
    table.sort(actors, function(left, right)
        return tostring(left.actorID) < tostring(right.actorID)
    end)
    if actorID then
        actorRecord = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(actorID) or nil
        if actorRecord and type(adapter.BuildConversationContext) == "function" then
            worldContext = adapter.BuildConversationContext(actorRecord, {
                language = (Runtime.scenario and Runtime.scenario.runtime
                    and Runtime.scenario.runtime.language) or "EN",
                now = Runtime.now,
                max = 4,
            })
        end
    end
    local realization = worldContext and worldContext.npcGossip or {
        statements = {}, factRefs = {},
    }
    realization.source = "world_knowledge"
    realization.language = (Runtime.scenario and Runtime.scenario.runtime
        and Runtime.scenario.runtime.language) or "EN"
    return {
        ok = true,
        type = "world_knowledge_inspection",
        actorID = actorID,
        scenarioOwned = Runtime.worldKnowledgeScenario ~= nil,
        ledger = {
            facts = facts,
            metrics = Values.copy(core.LedgerState.metrics),
            maxFacts = core.LedgerState.maxFacts,
            revision = core.LedgerState.revision,
        },
        actorKnowledge = actors,
        propagationTrace = Values.copy(adapter.PropagationTrace),
        corePropagationTrace = Values.copy(core.Trace),
        candidates = worldContext and worldContext.worldKnowledge
            and worldContext.worldKnowledge.candidates or {},
        finalRealization = realization,
        explanation = actorID and payload.factID
            and core.Explain(actorID, payload.factID, Runtime.now) or nil,
    }
end

local function worldKnowledgePropagate(context, payload)
    local Values = context.Values
    local adapter = PNC.WorldKnowledge
    local registry = PNC.Registry
    local from = registry and registry.Get
        and registry.Get(payload and payload.fromActorID) or nil
    local to = registry and registry.Get
        and registry.Get(payload and payload.toActorID) or nil
    local transferred
    local reason
    if adapter and type(adapter.PropagateConversation) == "function" then
        transferred, reason = adapter.PropagateConversation(from, to, {
            authorized = payload and payload.authorized == true,
            channel = payload and payload.channel or "conversation",
            now = payload and payload.now or context.Runtime.now,
            max = payload and payload.max or 3,
        })
    else
        reason = "world_knowledge_unavailable"
    end
    return {
        ok = transferred ~= nil,
        type = "world_knowledge_propagation",
        transferred = Values.copy(transferred or {}),
        reason = reason,
        trace = Values.copy(adapter and adapter.PropagationTrace or {}),
    }
end

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
        suggestions = context.Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        ),
        -- The full production flow catalog is fetched through FLOW_CATALOG.
        -- Keeping the handshake bounded matters as automatic generation grows.
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
    elseif command == "PREVIEW" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.preview(context, tostring(payload))
    elseif command == "SUGGESTION_PREDICATE" then
        local predicates = PNC.Semantics
            and PNC.Semantics.SuggestionPredicates or nil
        local view = context.Runtime and context.Runtime.view or nil
        if not predicates or type(predicates.Evaluate) ~= "function" then
            return nil, "suggestion_predicates_unavailable"
        end
        if type(payload) ~= "table" or type(payload.predicate) ~= "table" then
            return nil, "suggestion_predicate_required"
        end
        return {
            ok = true,
            type = "suggestion_predicate",
            result = predicates.Evaluate(
                payload.predicate,
                view and view.spec and view.spec.context or {}
            ),
        }
    elseif command == "SUGGESTION_CLICK" then
        local view = context.Runtime and context.Runtime.view or nil
        if type(payload) ~= "table" or type(payload.frame) ~= "table" then
            return nil, "suggestion_frame_required"
        end
        if not view or not view.session then
            return nil, "conversation_unavailable"
        end
        local suggestions = PNC.Semantics
            and PNC.Semantics.DialogueSuggestions or nil
        if suggestions
            and (
                (type(suggestions.IsConversationCategoryFrame) == "function"
                    and suggestions.IsConversationCategoryFrame(payload.frame))
                or (type(suggestions.IsConversationChoiceFrame) == "function"
                    and suggestions.IsConversationChoiceFrame(payload.frame))
                or (type(suggestions.IsConversationRootChoiceFrame)
                    == "function"
                    and suggestions.IsConversationRootChoiceFrame(payload.frame))
            )
        then
            return context.Conversation.semanticClick(
                context,
                Values.copy(payload.frame)
            )
        end
        context.Runtime.semanticClickFrame = Values.copy(payload.frame)
        return context.Conversation.turn(
            context,
            tostring(payload.frame.textFallback or payload.frame.candidateID or "")
        )
    elseif command == "LANGUAGE" then
        if payload == nil then return nil, "language_required" end
        local response = context.Translations.setLanguage(context,
            type(payload) == "table" and payload.language or payload)
        context.Conversation.refreshViewContext(context)
        local view = context.Runtime.view
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        local suggestions
        if view and view.lastSemanticDialogueResult
            and internal and type(internal.RefreshSuggestions) == "function"
        then
            suggestions = internal.RefreshSuggestions(
                view, view.lastSemanticDialogueResult
            )
        elseif internal
            and type(internal.RefreshRootSuggestions) == "function"
        then
            suggestions = internal.RefreshRootSuggestions(view)
        end
        response.suggestions = context.Values.copy(suggestions)
        return response
    elseif command == "TOOL_REPLY" then
        return context.OutputProjection.toolReply(context, payload)
    elseif command == "SNAPSHOT" then
        return context.ScenarioSession.snapshot(context)
    elseif command == "FLOW_CATALOG" then
        return context.FlowEditor.catalog(context)
    elseif command == "FLOW_VALIDATE" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.validate(context, payload)
    elseif command == "FLOW_REGISTER" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.register(context, payload)
    elseif command == "FLOW_GENERATE" or command == "FLOW_COVERAGE" then
        return context.FlowEditor.generate(context)
    elseif command == "REPLAY_SEMANTIC_QUEST" then
        if type(payload) ~= "table" then
            return nil, "quest_request_must_be_object"
        end
        local router = PNC.ServerCommandRouter
        local handled = router and type(router.Handle) == "function"
            and router.Handle(
                PNC.Const.CMD_SEMANTIC_QUEST_REQUEST,
                context.player,
                payload
            ) or false
        return { ok = true, type = "semantic_quest_replay", handled = handled }
    elseif command == "COMMITMENT" then
        if type(payload) ~= "table" then
            return nil, "commitment_request_must_be_object"
        end
        return context.Commitments.dispatch(context, payload)
    elseif command == "BACKSTORY" then
        return backstorySnapshot(payload)
    elseif command == "BACKSTORY_FACT" then
        return backstoryFact(payload)
    elseif command == "KNOWLEDGE_BOOTSTRAP" then
        local callback = PNC.PlayerKnowledgeCommands
            and PNC.PlayerKnowledgeCommands.HandleBootstrap
        if type(callback) ~= "function" then
            return nil, "knowledge_bootstrap_unavailable"
        end
        local args = Values.copy(type(payload) == "table" and payload or {})
        args.requestID = args.requestID
            or "harness-bootstrap-" .. tostring(Runtime.now)
        args.scope = "all"
        local result = callback(context.player, args)
        return {
            ok = true,
            type = "knowledge_bootstrap",
            result = Values.copy(result),
        }
    elseif command == "KNOWLEDGE_DISCOVER" then
        return knowledgeDiscover(context, payload)
    elseif command == "KNOWLEDGE_METRICS" then
        return knowledgeMetrics(context, payload)
    elseif command == "WORLD_KNOWLEDGE_INSPECT" then
        return worldKnowledgeInspect(context, payload)
    elseif command == "WORLD_KNOWLEDGE_PROPAGATE" then
        return worldKnowledgePropagate(context, payload)
    elseif command == "FACT_CATALOG" then
        return {
            ok = true,
            type = "fact_catalog",
            facts = context.EngineFacts and context.EngineFacts.List
                and context.EngineFacts.List() or {},
        }
    elseif command == "EVENT_CATALOG" then
        return {
            ok = true,
            type = "event_catalog",
            events = context.EngineEvents and context.EngineEvents.ListTypes
                and context.EngineEvents.ListTypes() or {},
        }
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
            suggestions = context.Values.copy(
                Runtime.view and Runtime.view.semanticSuggestions
            ),
            translation = context.OutputProjection.translationSnapshot(context),
        }
    elseif command == "QUIT" then
        return { ok = true, type = "closed" }, nil, true
    end

    return nil, "unknown_command:" .. tostring(command)
end

return CommandRouter
