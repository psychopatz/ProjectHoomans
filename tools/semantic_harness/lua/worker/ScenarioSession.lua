-- Worker scenario lifecycle: configure fixtures, reset, and inspect state.

local RuntimeEnvironment = require "worker/RuntimeEnvironment"
local SemanticAdapters = require "worker/SemanticAdapters"
local InventoryFixtures = require "worker/InventoryFixtures"

local ScenarioSession = {}

local function simulationProjection(context)
    local Values = context.Values
    local scenario = context.Runtime.scenario or {}
    local player = scenario.player or {}
    local npc = scenario.npc or {}
    local world = scenario.world or {}
    local playerNeeds = type(player.needs) == "table"
        and player.needs or world
    local npcNeeds = type(npc.needs) == "table" and npc.needs or world
    return {
        schema = "semantic.simulation.actor.projection.v1",
        player = {
            needs = Values.copy(playerNeeds),
            traits = Values.copy(player.traits or player.socialTraits or {}),
            socialProfile = Values.copy(context.playerSocialProfile),
            traitConflicts = Values.copy(context.playerTraitConflicts),
            traitFingerprint = context.playerTraitFingerprint,
        },
        npc = {
            needs = Values.copy(npcNeeds),
            traits = Values.copy(npc.traits or {}),
            bond = Values.copy(npc.relationship and npc.relationship.bond),
            personality = Values.copy(context.npcPersonality),
            personalityMode = context.npcPersonalityMode or "generated",
            identitySeed = npc.identitySeed
                or npc.identity and npc.identity.seed or npc.npcID,
            archetype = npc.archetype or npc.archetypeID or "General",
        },
    }
end

ScenarioSession.initialScenario = {
    player = {
        characterUUID = "char_patrick",
        forename = "Patrick",
        surname = "Patz",
        displayName = "Patrick Patz",
        needs = {
            hunger = 0.2,
            thirst = 0.4,
            fatigue = 0.1,
            stress = 0.0,
            boredom = 0.0,
            panic = 0.0,
        },
        traits = {},
    },
    npc = {
        npcID = "npc_mara",
        forename = "Mara",
        surname = "Vale",
        identityState = "unknown",
        identitySeed = "npc_mara",
        archetype = "General",
        needs = {
            hunger = 0.2,
            thirst = 0.4,
            fatigue = 0.1,
            stress = 0.0,
            boredom = 0.0,
            panic = 0.0,
        },
        traits = { "reserved" },
        relationship = { approval = 0, respect = 0, familiarity = 0, revision = 1 },
    },
    world = {
        hunger = 0.2,
        thirst = 0.4,
        fatigue = 0.1,
        timeOfDay = 13.5,
        worldAgeHours = 49.5,
        zombieKills = 0,
    },
    conversation = { topic = "greeting", token = "harness-lease" },
    runtime = { mode = "singleplayer", language = "EN", llmEnabled = false, providerAvailable = false },
}

function ScenarioSession.configureRuntime(context)
    RuntimeEnvironment.configure(context)
    SemanticAdapters.configure(context)
    InventoryFixtures.configure(context)
end

function ScenarioSession.reset(context, scenario)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.scenario = scenario
    context.RuntimeState.resetContainers(Runtime)
    ScenarioSession.configureRuntime(context)
    local runtime = scenario.runtime or {}
    if context.ProductionModules
        and type(context.ProductionModules.loadOptional) == "function"
    then
        local loaded, reason = context.ProductionModules.loadOptional(context)
        Runtime.dynamicTradingLoad = {
            requested = runtime.availableMods
                and runtime.availableMods.DTHoomans == true or false,
            loaded = loaded == true,
            reason = reason,
            logs = Values.copy(Runtime.productionLogs),
        }
    end
    PNC.Client = PNC.Client or {}
    Runtime.productionSocialRequest = Runtime.productionSocialRequest
        or PNC.Client.RequestSemanticSocialInteraction
    if Runtime.productionSocialRequest then
        local runtime = scenario.runtime or {}
        if runtime.socialTransportAvailable == false then
            -- Harness-only boundary control: exercise the real production
            -- response path without inventing a server event or effect.
            PNC.Client.RequestSemanticSocialInteraction = nil
        else
            PNC.Client.RequestSemanticSocialInteraction =
                Runtime.productionSocialRequest
        end
    end
    if runtime.mode == "multiplayer"
        and type(Runtime.questProductionWrapper) == "function"
    then
        PNC.Client.RequestSemanticQuest = Runtime.questProductionWrapper
    end
    context.Translations.setLanguage(
        context, context.Translations.scenarioLanguage(context)
    )
    Runtime.view = context.Conversation.buildView(context)
    if PsychopatzCore and PsychopatzCore.Conversation then
        -- The production disclosure receiver owns the live conversation
        -- lifecycle. Point Core at the harness view so its normal result and
        -- context-recording path remains observable in headless tests.
        PsychopatzCore.Conversation.instance = Runtime.view
    end
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.identityTrust = {}
    PNC.Network.ClientState.semanticIdentityResults = {}
    PNC.Network.ClientState.semanticQuestResults = {}
    PNC.Network.ClientState.semanticQuestResultOrder = {}
    PNC.Network.ClientState.npcPresentations = {}
    PNC.Network.ClientState.pendingDisclosure = {}
    PNC.Network.ClientState.npcKnowledge = {}
    local npc = scenario.npc or {}
    PNC.Network.ClientState.conversationRelationships[npc.npcID] =
        context.Conversation.relationshipSnapshot(context)
    PNC.Network.ClientState.characterPayloads[npc.npcID] = {
        inventory = {
            revision = Values.number(npc.inventory and npc.inventory.revision, 1),
        },
    }
    return {
        ok = true,
        type = "configured",
        scenario = Values.copy(scenario),
        loadedModules = Runtime.loadedModules,
        moduleManifest = Values.copy(Runtime.moduleManifest),
        headlessRequires = Values.copy(Runtime.headlessRequires),
        questBoundary = Runtime.questBoundary,
        worldKnowledge = Values.copy(Runtime.worldKnowledgeScenario),
        worldKnowledgeLastContext = Values.copy(Runtime.worldKnowledgeLastContext),
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
                and type(PNC.Semantics.CognitionClient.ApplyPayload) or nil,
            handler = PNC.Client and PNC.Client.Internal
                and PNC.Client.Internal.ServerCommandHandlers
                and PNC.Client.Internal.ServerCommandHandlers[
                    PNC.Const and PNC.Const.CMD_SEMANTIC_COGNITION or ""
                ] ~= nil,
        },
        suggestions = Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        ),
        context = context.Conversation.contextSnapshot(
            context, Runtime.view
        ),
        choiceSurface = Values.copy(
            Runtime.view and Runtime.view.session
                and Runtime.view.session.choicePresentationState
        ),
        translation = context.OutputProjection.translationSnapshot(context),
        dynamicTradingLoad = Values.copy(Runtime.dynamicTradingLoad),
        simulationProjection = simulationProjection(context),
    }
end

function ScenarioSession.snapshot(context)
    local Runtime = context.Runtime
    local Values = context.Values
    return {
        ok = true,
        type = "snapshot",
        scenario = Values.copy(Runtime.scenario),
        transcript = Values.copy(Runtime.transcript),
        queued = Values.copy(Runtime.queued),
        relationship = context.Conversation.relationshipSnapshot(context),
        context = context.Conversation.contextSnapshot(context, Runtime.view),
        conversationGraph = Values.copy(
            context.Conversation.graphProjection(Runtime.view)
        ),
        transport = Values.copy(Runtime.transport),
        trace = Values.copy(Runtime.trace),
        translation = context.OutputProjection.translationSnapshot(context),
        dynamicTradingLoad = Values.copy(Runtime.dynamicTradingLoad),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
        moduleManifest = Values.copy(Runtime.moduleManifest),
        headlessRequires = Values.copy(Runtime.headlessRequires),
        questBoundary = Runtime.questBoundary,
        worldKnowledge = Values.copy(Runtime.worldKnowledgeScenario),
        worldKnowledgeLastContext = Values.copy(Runtime.worldKnowledgeLastContext),
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
                and type(PNC.Semantics.CognitionClient.ApplyPayload) or nil,
            handler = PNC.Client and PNC.Client.Internal
                and PNC.Client.Internal.ServerCommandHandlers
                and PNC.Client.Internal.ServerCommandHandlers[
                    PNC.Const and PNC.Const.CMD_SEMANTIC_COGNITION or ""
                ] ~= nil,
        },
        suggestions = Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        ),
        choiceSurface = Values.copy(
            Runtime.view and Runtime.view.session
                and Runtime.view.session.choicePresentationState
        ),
        simulationProjection = simulationProjection(context),
    }
end

return ScenarioSession
