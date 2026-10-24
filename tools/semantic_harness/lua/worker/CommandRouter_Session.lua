-- Session lifecycle and transport metadata for the semantic worker router.

local Session = {}
local Persona = require "worker/CommandRouter_Persona"
local Simulation = require "worker/CommandRouter_Simulation"
local Talk = require "worker/CommandRouter_Talk"

local capabilities = {
    "CONFIG", "IMPORT_SOURCE", "INSTALL_PRODUCTION_REGISTRIES",
    "INSTALL_PRODUCTION_KNOWLEDGE", "RESET", "RESET_TURN", "RESET_CONVERSATION",
    "RESET_ACTOR_MUTATIONS", "RESET_WORLD", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "MUTATION_PROJECTION", "CONVERSATION_GRAPH",
    "FLOW_CATALOG", "FLOW_VALIDATE",
    "INSPECT_ACTOR_STATE", "INSPECT_NPC_DOSSIER",
    "RELATIONSHIP_PROPOSAL", "RELATIONSHIP_PREVIEW",
    "APPLY_RUNTIME_RELATIONSHIP_BASELINE",
    "SUGGESTION_PREDICATE", "SUGGESTION_CLICK",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
    "KNOWLEDGE_BOOTSTRAP", "KNOWLEDGE_DISCOVER", "KNOWLEDGE_METRICS",
    "WORLD_KNOWLEDGE_INSPECT", "WORLD_KNOWLEDGE_PROPAGATE",
    "PERSONA_CATALOG", "PERSONA_PREVIEW",
    "SIMULATION_CONTROL_CATALOG",
    "TALK_CATALOG", "TALK_START", "TALK_OPEN", "CONVERSATION_OPEN",
    "TALK_SUSPEND", "CONVERSATION_SUSPEND", "TALK_RESUME",
    "CONVERSATION_RESUME", "TALK_CLOSE", "CONVERSATION_CLOSE",
    "TALK_EMOTE", "CONVERSATION_EMOTE",
    "TALK_MATRIX",
    "CONVERSATION_PROJECTION", "TALK_PROJECTION",
}

function Session.hello(context)
    local Runtime = context.Runtime
    return {
        ok = true,
        type = "hello",
        worker = "project_hoomans_semantic_harness",
        capabilities = capabilities,
        loadedModules = Runtime.loadedModules,
        moduleManifest = Runtime.moduleManifest,
        headlessRequires = Runtime.headlessRequires,
        personaCatalog = Persona.catalog(context),
        simulationControlCatalog = Simulation.catalog(context),
        talkCatalog = Talk.catalog(),
        simulationProjection = context.ScenarioSession
            .simulationProjection(context),
        conversationPresentation = context.Conversation.presentationProjection(
            context, Runtime.view
        ),
        suggestions = context.Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        ),
        -- The full production flow catalog is fetched through FLOW_CATALOG.
        -- Keeping the handshake bounded matters as automatic generation grows.
        translation = context.OutputProjection.translationSnapshot(context),
    }
end

function Session.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "CONFIG" then
        if type(payload) ~= "table" then
            return nil, "scenario_must_be_object"
        end
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.reset(context, payload)
        )
    elseif command == "INSTALL_PRODUCTION_REGISTRIES" then
        if type(payload) ~= "table" then
            return nil, "production_registries_must_be_object"
        end
        Runtime.pendingProductionRawRegistries = Values.productionCopy(
            payload
        )
        return {
            ok = true,
            type = "production_registries_installed",
            registryNames = {
                factions = type(payload.factions) == "table",
                communities = type(payload.communities) == "table",
            },
        }
    elseif command == "INSTALL_PRODUCTION_KNOWLEDGE" then
        if type(payload) ~= "table" then
            return nil, "production_knowledge_must_be_object"
        end
        Runtime.pendingProductionKnowledgeRegistry = Values.productionCopy(
            payload
        )
        return {
            ok = true,
            type = "production_knowledge_installed",
            registry = "PNC_NPCKnowledge",
        }
    elseif command == "IMPORT_SOURCE" then
        if type(payload) ~= "table"
            or type(payload.scenario) ~= "table"
        then
            return nil, "source_scenario_must_be_object"
        end
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.importSource(
                context,
                payload.scenario,
                payload.metadata,
                payload.provenance,
                payload.providerPayloads
            )
        )
    elseif command == "RESET" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.reset(context, Values.copy(Runtime.scenario))
        )
    elseif command == "RESET_TURN" then
        context.RuntimeState.resetTurn(Runtime)
        return context.ScenarioSession.snapshot(context)
    elseif command == "RESET_CONVERSATION" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetConversation(context)
        )
    elseif command == "RESET_ACTOR_MUTATIONS" then
        local actor = type(payload) == "table" and payload.actor or payload
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetActorMutations(context, actor)
        )
    elseif command == "RESET_WORLD" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetWorld(context)
        )
    elseif command == "SNAPSHOT" then
        -- SNAPSHOT is the explicit inspector boundary. Preserve its
        -- immutable source/provider projection; only mutation responses use
        -- the compact transport projection below.
        return context.ScenarioSession.snapshot(context)
    elseif command == "MUTATION_PROJECTION" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.mutationProjection(context)
        )
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
            personaCatalog = Persona.catalog(context),
            simulationControlCatalog = Simulation.catalog(context),
            talkCatalog = Talk.catalog(),
            simulationProjection = context.ScenarioSession
                .simulationProjection(context),
            conversationPresentation = context.Conversation.presentationProjection(
                context, Runtime.view
            ),
            suggestions = context.Values.copy(
                Runtime.view and Runtime.view.semanticSuggestions
            ),
            translation = context.OutputProjection.translationSnapshot(context),
        }
    elseif command == "QUIT" then
        return { ok = true, type = "closed" }, nil, true
    end
    return false
end

return Session
