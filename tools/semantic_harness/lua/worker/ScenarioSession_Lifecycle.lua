-- Scenario source import, runtime configuration, and reset orchestration.

local RuntimeEnvironment = require "worker/RuntimeEnvironment"
local SemanticAdapters = require "worker/SemanticAdapters"
local InventoryFixtures = require "worker/InventoryFixtures"
local ProductionRehydration = require "worker/ProductionRehydration"
local SemanticDialogueRuntime = require
    "PNC/Semantics/PNC_SemanticDialogueRuntime"

local function install(ScenarioSession)
    local Internal = ScenarioSession.Internal

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
        -- Provider payloads include raw production save records. Keep the
        -- uncapped production copy here; diagnostic copies are bounded.
        Runtime.sourceProviderPayloads = Values.productionCopy(
            providerPayloads or {}
        )
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
        Runtime.replaceProductionDurableState = true
        local response = ScenarioSession.reset(
            context, Values.copy(Runtime.sourceSnapshot)
        )
        Runtime.replaceProductionDurableState = false
        return response
    end

    function ScenarioSession.reset(context, scenario)
        local Runtime = context.Runtime
        local Values = context.Values
        Runtime.scenario = Values.copy(scenario or {})
        Runtime.conversationOpened = false
        Runtime.conversationSuspended = false
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
                -- response path without inventing an event or gameplay effect.
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
            -- lifecycle. Point Core at the harness view so its normal result
            -- and context-recording path remains observable in headless tests.
            PsychopatzCore.Conversation.instance = Runtime.view
        end
        PNC.Network.ClientState.conversationRelationships[npc.npcID] =
            context.Conversation.relationshipSnapshot(context)
        PNC.Network.ClientState.characterPayloads[npc.npcID] = {
            inventory = {
                revision = Values.number(
                    npc.inventory and npc.inventory.revision, 1
                ),
            },
        }
        return Internal.ConfiguredPayload(context)
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
end

return install
