-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}

local capabilities = {
    "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "FLOW_CATALOG", "FLOW_VALIDATE",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
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
    })
    return {
        ok = true,
        type = "backstory_fact",
        fact = result,
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
