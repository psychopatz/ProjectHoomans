-- Suggestion-build candidate sources and topic projections.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal
local Predicates = Internal.Predicates
local ChoiceRegistry = Internal.ChoiceRegistry
local normalized = Internal.normalized
local canonicalTopic = Internal.canonicalTopic
local topicFromIR = Internal.topicFromIR
local sourceRecord = Internal.sourceRecord
local definitionFor = Internal.definitionFor
local definitionForSubject = Internal.definitionForSubject
local topicMatches = Internal.topicMatches
local isActiveHubDefinition = Internal.isActiveHubDefinition
local isActiveHubCandidate = Internal.isActiveHubCandidate
local isCompanionOrderAction = Internal.isCompanionOrderAction
local capabilityRows = Internal.capabilityRows
local appendCompanionOrderNavigation = Internal.appendCompanionOrderNavigation
local appendCompanionCampNavigation = Internal.appendCompanionCampNavigation
local appendBranchOffers = Internal.appendBranchOffers
local appendConversationChoices = Internal.appendConversationChoices
local appendConversationRootChoices = Internal.appendConversationRootChoices
local appendLandingShortcuts = Internal.appendLandingShortcuts
local appendTalkAgainAbout = Internal.appendTalkAgainAbout
local appendTrace = Internal.appendTrace
local addProviderCandidate = Internal.addProviderCandidate
local addCandidate = Internal.addCandidate
local DEFINITIONS = Internal.DEFINITIONS
local offersFromPlan = Internal.offersFromPlan
local offersFromMessages = Internal.offersFromMessages
local offersFromLifecycle = Internal.offersFromLifecycle

function Internal.CollectSuggestionBuildSources(state)
    local result = state.result
    local context = state.context
    local ir = state.ir
    local candidates = state.candidates
    local seen = state.seen
    local trace = state.trace
    local revision = state.revision
    local activeHubID = state.activeHubID
    local currentAction = state.currentAction
    local pendingIdentity = state.pendingIdentity

    local capabilities, capabilitySource, predicateTrace = capabilityRows(
        revision, currentAction, context, ir
    )
    state.capabilities = capabilities
    state.capabilitySource = capabilitySource
    state.predicateTrace = predicateTrace

    -- Keep the production landing choices in the projection even while a
    -- child topic/flow is active. They stay out of the selected child group,
    -- but this lets the shared Back frame return to a real landing surface.
    appendConversationRootChoices(
        candidates, seen, context, revision, predicateTrace
    )
    appendLandingShortcuts(
        candidates, seen, revision, predicateTrace
    )
    appendTalkAgainAbout(
        candidates, seen, context, revision, predicateTrace
    )
    appendConversationChoices(
        candidates, seen, context, revision, predicateTrace
    )
    appendCompanionOrderNavigation(
        candidates, seen, context, revision, predicateTrace
    )
    appendCompanionCampNavigation(
        candidates, seen, context, revision, predicateTrace
    )

    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowActive = flow.flowId ~= nil
        and (flow.committed == true or flow.matched == true)
    state.decision = decision
    state.flow = flow
    state.flowActive = flowActive
    if flowActive then
        appendBranchOffers(
            candidates,
            seen,
            flow.branchOffers,
            "active_flow",
            revision,
            context,
            ir,
            predicateTrace,
            {
                kind = "active_flow",
                flowID = flow.flowId,
                nodeID = flow.toNodeId or flow.nodeId,
            }
        )
    end

    local response = type(decision.response) == "table"
        and decision.response or {}
    state.response = response
    -- An NPC event beat is the durable authority for its follow-up window.
    -- Project it before the transient response payload so identical offer
    -- IDs cannot be claimed by a rendered/transient plan origin.
    appendBranchOffers(
        candidates,
        seen,
        offersFromLifecycle(context),
        "npc_event_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )
    appendBranchOffers(
        candidates,
        seen,
        offersFromPlan(response.plan),
        "npc_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )
    appendBranchOffers(
        candidates,
        seen,
        offersFromMessages(state.messages),
        "npc_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )

    -- All optional/domain providers use the generic registry lane. The
    -- registry filters raw definitions, so providers remain outside this
    -- orchestration spoke and retain their authoritative adapters.
    local providerTopic = topicFromIR(ir, nil)
        or canonicalTopic(context.currentTopic)
    local providerContext = context
    local currentContextTopic = tostring(context.currentTopic or "")
    local needsProviderContext = activeHubID ~= nil
        or providerTopic ~= nil
            and currentContextTopic ~= tostring(providerTopic)
    if needsProviderContext then
        providerContext = {}
        for key, value in pairs(context) do
            providerContext[key] = value
        end
    end
    if providerTopic ~= nil
        and currentContextTopic ~= tostring(providerTopic)
    then
        providerContext.currentTopic = providerTopic
    end
    if activeHubID ~= nil then
        providerContext.activeHubID = activeHubID
    end
    local providerCandidates = ChoiceRegistry.Collect(
        providerContext, Suggestions.MAX_CANDIDATES
    )
    for _, candidate in ipairs(providerCandidates or {}) do
        if isActiveHubCandidate(candidate, activeHubID) then
            appendTrace(
                trace, "semantic_hub", "consumed", "hub_already_active",
                #candidates
            )
        else
            addProviderCandidate(candidates, seen, candidate, revision)
        end
    end
    if activeHubID ~= nil then
        appendTrace(
            trace, "semantic_hub", "active", "reviewed_hub_activation",
            #candidates
        )
    end

    local subject = normalized(ir.subject)
    local typedTopic = topicFromIR(ir, nil)
    local currentTopic = typedTopic or canonicalTopic(context.currentTopic)
    local typedReason = subject ~= "" and "interpreted_frame" or "no_subject"
    local typedSource = sourceRecord("typed_input", revision, typedReason)
    local typedEligible = result.accepted == true
        and subject ~= ""
        and ir.kind ~= "semantic_click_frame"
    if typedEligible and currentTopic then
        if subject == "WELLBEING" then
            addCandidate(
                candidates, seen, definitionFor("question.wellbeing_detail"),
                "typed_input", revision, "wellbeing_follow_up"
            )
        end
        for _, definition in ipairs(DEFINITIONS) do
            if topicMatches(definition, currentTopic)
                and definition.hubOnly ~= true
                and not (pendingIdentity and subject == "IDENTITY")
            then
                if isActiveHubDefinition(definition, activeHubID) then
                    appendTrace(
                        trace, "typed_input", "consumed",
                        "semantic_hub_already_active", #candidates
                    )
                else
                    addCandidate(
                        candidates, seen, definition,
                        "typed_input", revision, "topic_branch"
                    )
                end
            end
        end
        appendTrace(trace, "typed_input", "allowed", typedReason, #candidates)
    else
        appendTrace(trace, "typed_input", "skipped", typedReason, #candidates)
    end

    local topic = Internal.responseTopic(result, state.messages)
    local responseTopicID = canonicalTopic(topic)
    if not typedTopic then currentTopic = responseTopicID or currentTopic end
    local planSource = sourceRecord(
        "npc_response_plan", revision,
        topic and "known_safe_topic" or "topic_unknown"
    )
    if topic then
        local followUp = topic == "WELLBEING"
        local definition = definitionForSubject(topic, followUp)
        if not (pendingIdentity and normalized(topic) == "IDENTITY") then
            addCandidate(
                candidates, seen, definition,
                "npc_response_plan", revision, "response_plan_topic"
            )
            appendTrace(
                trace, "npc_response_plan", "allowed", topic, #candidates
            )
        else
            appendTrace(
                trace,
                "npc_response_plan",
                "consumed",
                "identity_exchange_choices_active",
                #candidates
            )
        end
    else
        appendTrace(trace, "npc_response_plan", "skipped", "topic_unknown", #candidates)
    end

    local flowSource = sourceRecord(
        "active_flow", revision,
        flowActive and "active_flow" or "no_active_flow"
    )
    local flowTopic = Internal.responseTopic({ decision = { flow = flow } })
    if flowActive and flowTopic then
        if not (pendingIdentity and normalized(flowTopic) == "IDENTITY") then
            addCandidate(
                candidates, seen, definitionForSubject(flowTopic, false),
                "active_flow", revision, "active_flow_response_pool"
            )
            appendTrace(
                trace, "active_flow", "allowed", "active_flow", #candidates
            )
        else
            appendTrace(
                trace,
                "active_flow",
                "consumed",
                "identity_exchange_choices_active",
                #candidates
            )
        end
    else
        appendTrace(
            trace, "active_flow", "skipped",
            flow.flowId and "flow_topic_unknown" or "no_active_flow",
            #candidates
        )
    end

    if #capabilities > 0 then
        appendTrace(
            trace, "permitted_capability", "allowed",
            "registered_dispatchable", #candidates
        )
    else
        appendTrace(
            trace, "permitted_capability", "skipped",
            "none_registered", #candidates
        )
    end

    state.currentTopic = currentTopic
    state.typedSource = typedSource
    state.planSource = planSource
    state.flowSource = flowSource
    return state
end

return Suggestions
