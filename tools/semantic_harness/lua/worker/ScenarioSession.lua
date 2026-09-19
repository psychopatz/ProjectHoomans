-- Worker scenario lifecycle: configure fixtures, reset, and inspect state.

local RuntimeEnvironment = require "worker/RuntimeEnvironment"
local SemanticAdapters = require "worker/SemanticAdapters"
local InventoryFixtures = require "worker/InventoryFixtures"

local ScenarioSession = {}

ScenarioSession.initialScenario = {
    player = {
        characterUUID = "char_patrick",
        forename = "Patrick",
        surname = "Patz",
        displayName = "Patrick Patz",
    },
    npc = {
        npcID = "npc_mara",
        forename = "Mara",
        surname = "Vale",
        identityState = "unknown",
        traits = { "reserved" },
        relationship = { approval = 0, respect = 0, familiarity = 0, revision = 1 },
    },
    world = { hunger = 0.2, thirst = 0.4, fatigue = 0.1, timeOfDay = 13.5, worldAgeHours = 49.5 },
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
    context.Translations.setLanguage(
        context, context.Translations.scenarioLanguage(context)
    )
    Runtime.view = context.Conversation.buildView(context)
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.identityTrust = {}
    PNC.Network.ClientState.semanticIdentityResults = {}
    PNC.Network.ClientState.npcPresentations = {}
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
        translation = context.OutputProjection.translationSnapshot(context),
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
        transport = Values.copy(Runtime.transport),
        trace = Values.copy(Runtime.trace),
        translation = context.OutputProjection.translationSnapshot(context),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
        moduleManifest = Values.copy(Runtime.moduleManifest),
        headlessRequires = Values.copy(Runtime.headlessRequires),
    }
end

return ScenarioSession
