-- Shared scenario response payload assembly.

local ProductionRehydration = require "worker/ProductionRehydration"

local function install(ScenarioSession)
    local Internal = ScenarioSession.Internal

    local function basePayload(context, responseType)
        local Runtime = context.Runtime
        local Values = context.Values
        return {
            ok = true,
            type = responseType,
            scenario = Values.copy(Runtime.scenario),
            sourceSnapshot = Internal.SourceSnapshotProjection(context),
            productionRehydration = Values.copy(Runtime.productionRehydration),
            productionFactionRehydration = Values.copy(
                Runtime.productionFactionRehydration
            ),
            productionPlayerRehydration = Values.copy(
                Runtime.productionPlayerRehydration
            ),
            productionKnowledgeRehydration = Values.copy(
                Runtime.productionKnowledgeRehydration
            ),
            runtimeRelationshipOverrides = Values.copy(
                Runtime.runtimeRelationshipOverrides
            ),
            productionFactionContext = Values.copy(
                Runtime.productionFactionContext
            ),
            workingWorld = Internal.WorkingWorldProjection(context),
        }
    end

    local function worldKnowledgePayload(context)
        local Values = context.Values
        return {
            worldKnowledge = Values.copy(context.Runtime.worldKnowledgeScenario),
            worldKnowledgeLastContext = Values.copy(
                context.Runtime.worldKnowledgeLastContext
            ),
            worldKnowledgeClient = Values.copy(
                PNC.Network and PNC.Network.ClientState
                    and PNC.Network.ClientState.semanticWorldKnowledgeGossip
                    or nil
            ),
            worldKnowledgeClientDebug = Values.copy(
                PNC.Network and PNC.Network.ClientState
                    and PNC.Network.ClientState.semanticWorldKnowledgeDebug
                    or nil
            ),
            worldKnowledgeRoute = {
                clientApply = PNC.Semantics and PNC.Semantics.CognitionClient
                    and type(PNC.Semantics.CognitionClient.ApplyPayload)
                    or nil,
                handler = PNC.Client and PNC.Client.Internal
                    and PNC.Client.Internal.ServerCommandHandlers
                    and PNC.Client.Internal.ServerCommandHandlers[
                        PNC.Const and PNC.Const.CMD_SEMANTIC_COGNITION or ""
                    ] ~= nil,
            },
        }
    end

    local function addSessionPresentation(response, context)
        local Runtime = context.Runtime
        local Values = context.Values
        response.suggestions = Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        )
        response.context = context.Conversation.contextSnapshot(
            context, Runtime.view
        )
        response.choiceSurface = Values.copy(
            Runtime.view and Runtime.view.session
                and Runtime.view.session.choicePresentationState
        )
        response.conversationPresentation = Values.copy(
            context.Conversation.presentationProjection(
                context, Runtime.view
            )
        )
        return response
    end

    local function addRuntimeDiagnostics(response, context)
        local Runtime = context.Runtime
        local Values = context.Values
        for key, value in pairs(worldKnowledgePayload(context)) do
            response[key] = value
        end
        response.loadedModules = Runtime.loadedModules
        response.moduleManifest = Values.copy(Runtime.moduleManifest)
        response.headlessRequires = Values.copy(Runtime.headlessRequires)
        response.questBoundary = Runtime.questBoundary
        response.translation = context.OutputProjection.translationSnapshot(context)
        response.dynamicTradingLoad = Values.copy(Runtime.dynamicTradingLoad)
        return response
    end

    local function configuredPayload(context)
        local response = basePayload(context, "configured")
        addRuntimeDiagnostics(response, context)
        addSessionPresentation(response, context)
        response.simulationProjection = Internal.SimulationProjection(context)
        response.interactionLifecycle = Internal.InteractionProjection(context)
        return response
    end

    local function snapshotPayload(context)
        local Runtime = context.Runtime
        local Values = context.Values
        if context.RuntimeState
            and type(context.RuntimeState.compactDiagnostics) == "function"
        then
            context.RuntimeState.compactDiagnostics(Runtime)
        end
        ProductionRehydration.refreshProjection(context)
        ProductionRehydration.refreshDiagnostics(context)
        local response = basePayload(context, "snapshot")
        response.transcript = Values.copy(Runtime.transcript)
        response.queued = Values.copy(Runtime.queued)
        response.relationship = context.Conversation.relationshipSnapshot(context)
        response.context = context.Conversation.contextSnapshot(
            context, Runtime.view
        )
        response.conversationGraph = Values.copy(
            context.Conversation.graphProjection(Runtime.view)
        )
        response.transport = Values.copy(Runtime.transport)
        response.trace = Values.copy(Runtime.trace)
        response.llmCalls = Runtime.llmCalls
        response.interactionLifecycle = Internal.InteractionProjection(context)
        addRuntimeDiagnostics(response, context)
        addSessionPresentation(response, context)
        response.simulationProjection = Internal.SimulationProjection(context)
        return response
    end

    local function mutationPayload(context)
        local Values = context.Values
        if context.RuntimeState
            and type(context.RuntimeState.compactDiagnostics) == "function"
        then
            context.RuntimeState.compactDiagnostics(context.Runtime)
        end
        ProductionRehydration.refreshProjection(context)
        ProductionRehydration.refreshDiagnostics(context)
        local response = basePayload(context, "mutation_projection")
        response.context = context.Conversation.contextSnapshot(
            context, context.Runtime.view
        )
        response.conversationPresentation = Values.copy(
            context.Conversation.presentationProjection(
                context, context.Runtime.view
            )
        )
        response.simulationProjection = Internal.SimulationProjection(context)
        response.provenance = Values.productionCopy(
            context.Runtime.sourceProvenance
        )
        return response
    end

    Internal.ConfiguredPayload = configuredPayload
    Internal.SnapshotPayload = snapshotPayload
    Internal.MutationPayload = mutationPayload
end

return install
