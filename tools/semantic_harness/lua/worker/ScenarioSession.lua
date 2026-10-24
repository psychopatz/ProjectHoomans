-- Worker scenario lifecycle: configure fixtures, reset, and inspect state.

local RuntimeEnvironment = require "worker/RuntimeEnvironment"
local SemanticAdapters = require "worker/SemanticAdapters"
local InventoryFixtures = require "worker/InventoryFixtures"
local ProductionRehydration = require "worker/ProductionRehydration"
local SemanticDialogueRuntime = require
    "PNC/Semantics/PNC_SemanticDialogueRuntime"

local ScenarioSession = {}

local function sortedKeys(value)
    local keys = {}
    if type(value) ~= "table" then return keys end
    for key in pairs(value) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    return keys
end

local function collectPatches(imported, effective, path, patches, Values)
    if #patches >= 512 then return end
    if type(imported) == "table" and type(effective) == "table" then
        local keys = {}
        local seen = {}
        for _, key in ipairs(sortedKeys(imported)) do
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
        for _, key in ipairs(sortedKeys(effective)) do
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            if #patches >= 512 then break end
            local childPath = path == "" and key or path .. "." .. key
            collectPatches(imported[key], effective[key], childPath, patches, Values)
        end
        return
    end
    if imported == effective then return end
    patches[#patches + 1] = {
        path = path,
        imported = Values.copy(imported),
        effective = Values.copy(effective),
        source = "HARNESS_MUTATION",
    }
end

local function patchProjection(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local patches = {}
    collectPatches(
        Runtime.sourceWorkingBaseline or Runtime.sourceSnapshot or {},
        Runtime.scenario or {},
        "",
        patches,
        Values
    )
    local baseSource = Runtime.sourceMetadata
        and Runtime.sourceMetadata.sourceKind or "MISSING"
    for _, patch in ipairs(patches) do
        patch.baseSource = baseSource
    end
    return patches
end

local function sourceSnapshotProjection(context)
    local Runtime = context.Runtime
    local Values = context.Values
    return {
        schema = "semantic.imported_source_snapshot.v1",
        schemaVersion = 1,
        immutable = true,
        -- Source state is an imported record, not a bounded diagnostic
        -- projection.  Keep the production deep-copy seam here so the
        -- original values survive transport and later working-world resets.
        data = Values.productionCopy(Runtime.sourceSnapshot),
        metadata = Values.productionCopy(Runtime.sourceMetadata),
        provenance = Values.productionCopy(Runtime.sourceProvenance),
        providerPayloads = Values.productionCopy(Runtime.sourceProviderPayloads),
    }
end

local function workingWorldProjection(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local patches = patchProjection(context)
    return {
        schema = "semantic.harness_working_world.v1",
        schemaVersion = 1,
        sourceSnapshotID = Runtime.sourceMetadata
            and Runtime.sourceMetadata.sourceID or nil,
        effective = Values.productionCopy(Runtime.scenario),
        baseline = Values.productionCopy(
            Runtime.sourceWorkingBaseline or Runtime.sourceSnapshot
        ),
        patches = patches,
        provenance = {
            schema = "semantic.provenance.v1",
            defaultSource = Runtime.sourceMetadata
                and Runtime.sourceMetadata.sourceKind or "MISSING",
            overrides = Values.copy(patches),
        },
        resetCount = Runtime.workingResetCount or 0,
        revision = Runtime.workingWorldRevision or 0,
    }
end

local function compactTransportScenario(value)
    if type(value) == "table" and type(value.npc) == "table" then
        value.npc.social = nil
    end
    return value
end

function ScenarioSession.compactTransportResponse(context, response)
    if type(response) ~= "table" then return response end
    compactTransportScenario(response.scenario)
    local source = response.sourceSnapshot
    if type(source) == "table" then
        source.data = nil
        source.providerPayloads = nil
    end
    local working = response.workingWorld
    if type(working) == "table" then
        compactTransportScenario(working.effective)
        working.baseline = nil
    end
    return response
end

local function relationshipProposalProjection(context)
    local Values = context.Values
    local npc = context.Runtime.scenario
        and context.Runtime.scenario.npc or {}
    local evaluate = PNC.Relationships
        and PNC.Relationships.EvaluateProposal
    if type(evaluate) ~= "function" then
        return {
            schema = "semantic.relationship.proposal.v1",
            action = "RELATIONSHIP_PROPOSAL",
            eligible = false,
            reason = "relationship_proposal_unavailable",
        }
    end
    local result = evaluate(npc.npcID)
    if type(result) ~= "table" then
        return {
            schema = "semantic.relationship.proposal.v1",
            action = "RELATIONSHIP_PROPOSAL",
            eligible = false,
            reason = "relationship_proposal_unavailable",
        }
    end
    local standingExplanation = PNC.RelationshipStates
        and type(PNC.RelationshipStates.ExplainState) == "function"
        and PNC.RelationshipStates.ExplainState(result.relationship)
        or { state = result.relationship and result.relationship.state or "unknown" }
    local relationship = type(result.relationship) == "table"
        and result.relationship or {}
    local relationshipSummary = PNC.RelationshipPresentation
        and type(PNC.RelationshipPresentation.Summarize) == "function"
        and PNC.RelationshipPresentation.Summarize(
            relationship,
            result.relationship ~= nil
        ) or nil
    local relationshipGraph = PNC.RelationshipGraph
        and type(PNC.RelationshipGraph.Evaluate) == "function"
        and PNC.RelationshipGraph.Evaluate(
            relationship.approval,
            relationship.respect,
            "inspect"
        ) or nil
    return {
        schema = "semantic.relationship.proposal.v1",
        action = result.action or "RELATIONSHIP_PROPOSAL",
        eligible = result.eligible == true,
        compatible = result.compatible == true,
        available = result.available == true,
        reason = standingExplanation.reason or result.reason,
        proposalReason = result.reason,
        cooldownUntil = result.cooldownUntil,
        cooldownRemaining = result.cooldownRemaining,
        thresholds = Values.copy(result.thresholds),
        friendBondThresholds = {
            approval = PNC.RelationshipConstants
                and PNC.RelationshipConstants.FRIEND_BOND_APPROVAL_ENTER or 80,
            respect = PNC.RelationshipConstants
                and PNC.RelationshipConstants.FRIEND_BOND_RESPECT_ENTER or 50,
            familiarity = PNC.RelationshipConstants
                and PNC.RelationshipConstants.FRIEND_BOND_FAMILIARITY_ENTER or 60,
        },
        bond = Values.copy(result.bond),
        standing = standingExplanation.state or "unknown",
        approval = relationship.approval or 0,
        respect = relationship.respect or 0,
        familiarity = relationship.familiarity or 0,
        -- Keep the complete directed relationship production-owned.  The
        -- graph and presentation projections are generated by the same
        -- modules used by the game UI/server.
        record = Values.copy(relationship),
        productionGraph = Values.copy(relationshipGraph),
        productionPresentation = Values.copy(relationshipSummary),
    }
end

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
        relationship = relationshipProposalProjection(context),
    }
end

ScenarioSession.initialScenario = {
    player = {
        characterUUID = "char_patrick",
        forename = "Patrick",
        surname = "Patz",
        displayName = "Patrick Patz",
        gender = "male",
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
        gender = "female",
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
        seedString = "semantic-harness-default-save",
        hunger = 0.2,
        thirst = 0.4,
        fatigue = 0.1,
        timeOfDay = 13.5,
        worldAgeHours = 49.5,
        zombieKills = 0,
    },
    conversation = { topic = "greeting", token = "harness-lease" },
    runtime = {
        mode = "singleplayer",
        language = "EN",
        llmEnabled = false,
        providerAvailable = false,
        semanticDialogueEnabled = true,
    },
}

function ScenarioSession.configureRuntime(context)
    InventoryFixtures.restoreProduction(context)
    RuntimeEnvironment.configure(context)
    local rehydrated, reason = ProductionRehydration.configure(context)
    if not rehydrated then
        error("production_rehydration_failed:" .. tostring(reason))
    end
    SemanticAdapters.configure(context)
    InventoryFixtures.configure(context)
    ProductionRehydration.refreshDiagnostics(context)
end

local function interactionProjection(context)
    local Runtime = context.Runtime
    local Lifecycle = PNC.Semantics
        and PNC.Semantics.InteractionLifecycle or nil
    local store = Runtime.interactionLifecycle
    if not Lifecycle or not store then return nil end
    local playerUUID = Runtime.interactionLifecyclePlayerUUID
    local npcID = Runtime.interactionLifecycleNPCID
    local projected = Lifecycle.Project(store, playerUUID, npcID)
    local window = Lifecycle.ResponseWindow(store, playerUUID, npcID)
    return {
        schema = Lifecycle.SCHEMA,
        playerUUID = playerUUID,
        npcID = npcID,
        thread = projected and projected.thread or nil,
        responseWindow = window,
        metrics = projected and projected.metrics
            or Lifecycle.Metrics(store),
    }
end

function ScenarioSession.importSource(
    context, scenario, metadata, provenance, providerPayloads
)
    local Runtime = context.Runtime
    local Values = context.Values
    local sourceMetadata = Values.copy(metadata or {})
    sourceMetadata.schemaVersion = 1
    sourceMetadata.sourceKind = sourceMetadata.sourceKind or "FIXTURE"
    sourceMetadata.sourceID = sourceMetadata.sourceID
        or "fixture:synthetic-scenario"
    sourceMetadata.mode = sourceMetadata.mode or "developer_test"
    sourceMetadata.immutable = true
    Runtime.sourceSnapshot = Values.copy(scenario or {})
    Runtime.sourceMetadata = sourceMetadata
    Runtime.sourceProvenance = Values.copy(provenance or {
        schema = "semantic.provenance.v1",
        defaultSource = sourceMetadata.sourceKind,
        paths = {},
    })
    -- Provider payloads include raw production save records.  Keep the
    -- uncapped production copy here; the diagnostic copy would truncate Core
    -- FULL inventory envelopes before the production deserializer sees them.
    Runtime.sourceProviderPayloads = Values.productionCopy(providerPayloads or {})
    local providerHoomans = Runtime.sourceProviderPayloads.ProjectHoomans
    local transportedRegistries = type(providerHoomans) == "table"
        and providerHoomans.rawRegistries or nil
    if type(transportedRegistries) ~= "table"
        and type(Runtime.pendingProductionRawRegistries) == "table"
    then
        providerHoomans = type(providerHoomans) == "table"
            and providerHoomans or {}
        providerHoomans.rawRegistries = Values.productionCopy(
            Runtime.pendingProductionRawRegistries
        )
        Runtime.sourceProviderPayloads.ProjectHoomans = providerHoomans
    end
    if type(Runtime.pendingProductionKnowledgeRegistry) == "table" then
        providerHoomans = type(providerHoomans) == "table"
            and providerHoomans or {}
        providerHoomans.rawRegistries = type(providerHoomans.rawRegistries)
            == "table" and providerHoomans.rawRegistries or {}
        providerHoomans.rawRegistries.npcKnowledge = Values.productionCopy(
            Runtime.pendingProductionKnowledgeRegistry
        )
        Runtime.sourceProviderPayloads.ProjectHoomans = providerHoomans
    end
    Runtime.pendingProductionRawRegistries = nil
    Runtime.pendingProductionKnowledgeRegistry = nil
    Runtime.productionRawRegistries = type(providerHoomans) == "table"
        and Values.productionCopy(providerHoomans.rawRegistries) or nil
    Runtime.sourceWorkingBaseline = nil
    Runtime.captureWorkingBaseline = true
    Runtime.workingResetCount = 0
    Runtime.workingWorldRevision = (Runtime.workingWorldRevision or 0) + 1
    return ScenarioSession.reset(context, Values.copy(Runtime.sourceSnapshot))
end

function ScenarioSession.reset(context, scenario)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.scenario = Values.copy(scenario or {})
    Runtime.workingWorldRevision = (Runtime.workingWorldRevision or 0) + 1
    context.RuntimeState.resetContainers(Runtime)
    ScenarioSession.configureRuntime(context)
    if Runtime.captureWorkingBaseline == true then
        Runtime.sourceWorkingBaseline = Values.copy(Runtime.scenario)
        Runtime.captureWorkingBaseline = false
    end
    local runtime = Runtime.scenario.runtime or {}
    local lifecycle = PNC.Semantics
        and PNC.Semantics.InteractionLifecycle or nil
    if lifecycle and type(lifecycle.New) == "function" then
        local player = Runtime.scenario.player or {}
        local npc = Runtime.scenario.npc or {}
        Runtime.interactionLifecycle = lifecycle.New({
            authoritative = true,
            worldHour = Runtime.scenario.world
                and Runtime.scenario.world.worldAgeHours or 0,
        })
        Runtime.interactionLifecyclePlayerUUID = tostring(
            player.characterUUID or player.playerUUID or "player-one"
        )
        Runtime.interactionLifecycleNPCID = tostring(
            npc.npcID or npc.id or "harness-npc"
        )
    end
    SemanticDialogueRuntime.SetHarnessOverride(
        runtime.semanticDialogueEnabled ~= false
    )
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
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.identityTrust = {}
    PNC.Network.ClientState.semanticIdentityResults = {}
    PNC.Network.ClientState.semanticQuestResults = {}
    PNC.Network.ClientState.semanticQuestResultOrder = {}
    PNC.Network.ClientState.npcPresentations = {}
    PNC.Network.ClientState.pendingDisclosure = {}
    PNC.Network.ClientState.npcKnowledge = {}
    local npc = Runtime.scenario.npc or {}
    -- Native Talk seeds this client presentation after the adapter reset.
    -- Seeding before the reset made owned companions look like strangers.
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local npcID = tostring(npc.npcID or npc.id or "")
    if clientState and npcID ~= "" then
        clientState.npcPresentations = clientState.npcPresentations or {}
        local authority = type(npc.actorAuthority) == "table"
            and npc.actorAuthority or {}
        local owned = authority.owned == true or npc.ownedByPlayer == true
        local recruited = npc.recruited == true
        local identityState = tostring(npc.identityState or "unknown")
        if identityState ~= "known" and owned and recruited then
            identityState = "known"
        end
        clientState.npcPresentations[npcID] = {
            npcID = npcID,
            state = identityState,
            canAskName = identityState ~= "known",
            requestState = identityState == "known" and nil or "ready",
        }
    end
    Runtime.view = context.Conversation.buildView(context)
    if PsychopatzCore and PsychopatzCore.Conversation then
        -- The production disclosure receiver owns the live conversation
        -- lifecycle. Point Core at the harness view so its normal result and
        -- context-recording path remains observable in headless tests.
        PsychopatzCore.Conversation.instance = Runtime.view
    end
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
        scenario = Values.copy(Runtime.scenario),
        sourceSnapshot = sourceSnapshotProjection(context),
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
        workingWorld = workingWorldProjection(context),
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
        interactionLifecycle = interactionProjection(context),
    }
end

function ScenarioSession.resetConversation(context)
    local Runtime = context.Runtime
    return ScenarioSession.reset(context, Runtime.scenario or {})
end

function ScenarioSession.resetWorld(context)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.workingResetCount = (Runtime.workingResetCount or 0) + 1
    return ScenarioSession.reset(
        context,
        Values.copy(
            Runtime.sourceWorkingBaseline
                or Runtime.sourceSnapshot or Runtime.scenario or {}
        )
    )
end

function ScenarioSession.resetActorMutations(context, actor)
    local Runtime = context.Runtime
    local Values = context.Values
    local working = Values.copy(Runtime.scenario or {})
    local source = Runtime.sourceWorkingBaseline
        or Runtime.sourceSnapshot or {}
    local actorID = tostring(actor or "npc")
    if source[actorID] ~= nil then
        working[actorID] = Values.copy(source[actorID])
    end
    return ScenarioSession.reset(context, working)
end

function ScenarioSession.snapshot(context)
    local Runtime = context.Runtime
    local Values = context.Values
    ProductionRehydration.refreshProjection(context)
    ProductionRehydration.refreshDiagnostics(context)
    return {
        ok = true,
        type = "snapshot",
        scenario = Values.copy(Runtime.scenario),
        sourceSnapshot = sourceSnapshotProjection(context),
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
        workingWorld = workingWorldProjection(context),
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
        interactionLifecycle = interactionProjection(context),
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

ScenarioSession.simulationProjection = simulationProjection
ScenarioSession.relationshipProposalProjection = relationshipProposalProjection

return ScenarioSession
