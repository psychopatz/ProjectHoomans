-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}

local capabilities = {
    "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "FLOW_CATALOG", "FLOW_VALIDATE",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
    "KNOWLEDGE_BOOTSTRAP", "KNOWLEDGE_DISCOVER", "KNOWLEDGE_METRICS",
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
        and next(canonicalKnowledge.byCharacter) ~= nil
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
        actorRecordPresent = next(actor) ~= nil,
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
    elseif command == "LANGUAGE" then
        if payload == nil then return nil, "language_required" end
        return context.Translations.setLanguage(context,
            type(payload) == "table" and payload.language or payload)
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
            translation = context.OutputProjection.translationSnapshot(context),
        }
    elseif command == "QUIT" then
        return { ok = true, type = "closed" }, nil, true
    end

    return nil, "unknown_command:" .. tostring(command)
end

return CommandRouter
