-- Scenario session projections and bounded transport shaping.

local function install(ScenarioSession)
    local Internal = ScenarioSession.Internal

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
                collectPatches(
                    imported[key], effective[key], childPath, patches, Values
                )
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
            -- projection. Keep the production deep-copy seam here so the
            -- original values survive transport and later resets.
            data = Values.productionCopy(Runtime.sourceSnapshot),
            metadata = Values.productionCopy(Runtime.sourceMetadata),
            provenance = Values.productionCopy(Runtime.sourceProvenance),
            providerPayloads = Values.productionCopy(
                Runtime.sourceProviderPayloads
            ),
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
            or {
                state = result.relationship
                    and result.relationship.state or "unknown",
            }
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
                    and PNC.RelationshipConstants.FRIEND_BOND_APPROVAL_ENTER
                    or 80,
                respect = PNC.RelationshipConstants
                    and PNC.RelationshipConstants.FRIEND_BOND_RESPECT_ENTER
                    or 50,
                familiarity = PNC.RelationshipConstants
                    and PNC.RelationshipConstants.FRIEND_BOND_FAMILIARITY_ENTER
                    or 60,
            },
            bond = Values.copy(result.bond),
            standing = standingExplanation.state or "unknown",
            approval = relationship.approval or 0,
            respect = relationship.respect or 0,
            familiarity = relationship.familiarity or 0,
            -- Keep the complete directed relationship production-owned. The
            -- graph and presentation projections use game-owned modules.
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

    local function interactionProjection(context)
        local Runtime = context.Runtime
        local Lifecycle = PNC.Semantics
            and PNC.Semantics.InteractionLifecycle or nil
        local store = Runtime.interactionLifecycle
        if not Lifecycle or not store then return nil end
        local playerUUID = Runtime.interactionLifecyclePlayerUUID
        local npcID = Runtime.interactionLifecycleNPCID
        local pairKey = tostring(playerUUID or "") .. "|"
            .. tostring(npcID or "")
        local hasThread = store.active and store.active[pairKey]
            or store.pairs and store.pairs[pairKey]
        if not hasThread then
            return {
                schema = Lifecycle.SCHEMA,
                playerUUID = playerUUID,
                npcID = npcID,
                thread = nil,
                responseWindow = {
                    schema = Lifecycle.SCHEMA,
                    status = "EMPTY",
                    topic = nil,
                    activeBeat = nil,
                    openQuestions = {},
                    commitments = {},
                },
                metrics = Lifecycle.Metrics(store),
            }
        end
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

    Internal.SourceSnapshotProjection = sourceSnapshotProjection
    Internal.WorkingWorldProjection = workingWorldProjection
    Internal.SimulationProjection = simulationProjection
    Internal.InteractionProjection = interactionProjection
    ScenarioSession.simulationProjection = simulationProjection
    ScenarioSession.relationshipProposalProjection = relationshipProposalProjection
end

return install
