-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local DialogueRuntime = Internal.DialogueRuntime
local Predicates = Internal.Predicates
local IR = Internal.IR
local ChoiceRegistry = Internal.ChoiceRegistry
local ActorConversationContext = Internal.ActorConversationContext
local ChoiceRanking = Internal.ChoiceRanking
local normalized = Internal.normalized
local canonicalTopic = Internal.canonicalTopic
local topicFromIR = Internal.topicFromIR
local semanticHubID = Internal.semanticHubID
local responseTopic = Internal.responseTopic
local privateResult = Internal.privateResult
local revisionFor = Internal.revisionFor
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
local appendCampSiteCapabilityRows = Internal.appendCampSiteCapabilityRows
local appendTrace = Internal.appendTrace
local buildGroups = Internal.buildGroups
local addProviderCandidate = Internal.addProviderCandidate
local addCandidate = Internal.addCandidate
local DEFINITIONS = Internal.DEFINITIONS
local offersFromPlan = Internal.offersFromPlan
local offersFromMessages = Internal.offersFromMessages

function Suggestions.Build(result, context, messages)
    if not DialogueRuntime.IsEnabled() then
        return {
            schemaVersion = Suggestions.VERSION,
            kind = "semantic_dialogue_suggestions",
            revision = 0,
            turnID = 0,
            candidates = {},
            sources = {},
            permittedCapabilities = {},
            groups = {},
            currentTopic = nil,
            currentGroupID = nil,
            rootGroupID = nil,
            allowBack = false,
            predicateTrace = {},
            trace = {{
                source = "semantic_runtime",
                status = "disabled",
                reason = "semantic_dialogue_disabled",
            }},
        }
    end
    result = type(result) == "table" and result or {}
    context = type(context) == "table" and context or {}
    local revision, turnID = revisionFor(result)
    local candidates = {}
    local seen = {}
    local trace = {}
    local ir = type(result.ir) == "table" and result.ir or {}
    local pendingIdentity = context.pendingIdentityExchange
        or context.semanticContextState
        and context.semanticContextState.pendingIdentityExchange
        or context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
    local activeHubID = semanticHubID(ir)
    local currentAction = normalized(ir.action)
    local capabilities, capabilitySource, predicateTrace = capabilityRows(
        revision, currentAction, context, ir
    )
    local actorConversationContext = context.actorConversationContext
    if type(actorConversationContext) ~= "table" then
        actorConversationContext = ActorConversationContext.Build(context)
    end

    if privateResult(result) then
        appendTrace(trace, "typed_input", "hidden", "private_or_secret", 0)
        appendTrace(trace, "npc_response_plan", "hidden", "private_or_secret", 0)
        return {
            schemaVersion = Suggestions.VERSION,
            kind = "semantic_dialogue_suggestions",
            revision = revision,
            turnID = turnID,
            candidates = {},
            sources = {},
            permittedCapabilities = {},
            groups = {},
            currentTopic = nil,
            currentGroupID = nil,
            rootGroupID = nil,
            allowBack = true,
            predicateTrace = {},
            trace = trace,
            choiceRegistry = ChoiceRegistry.Snapshot(),
            actorConversationContext = ActorConversationContext.PublicView(
                actorConversationContext
            ),
        }
    end

    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowActive = flow.flowId ~= nil
        and (flow.committed == true or flow.matched == true)
    -- Keep the production landing choices in the projection even while a
    -- child topic/flow is active. They stay out of the selected child group,
    -- but this lets the shared Back frame return to a real landing surface
    -- instead of a synthetic empty page.
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
        offersFromMessages(messages),
        "npc_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )

    -- All optional/domain providers use the generic registry lane. The
    -- registry filters raw legacy definitions, so static/capability choices
    -- still pass through their existing authoritative adapters above while
    -- canonical Dynamic Trading and contextual social candidates are
    -- discovered without provider-specific calls here.
    local providerTopic = topicFromIR(ir, nil)
        or canonicalTopic(context.currentTopic)
    local providerContext = context
    local currentContextTopic = tostring(context.currentTopic or "")
    local needsProviderContext = activeHubID ~= nil
        or providerTopic ~= nil
            and currentContextTopic ~= tostring(providerTopic)
    if needsProviderContext then
        -- Providers receive the current typed topic without mutating the
        -- read-only projection shared by the remaining suggestion sources.
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
        local pendingIdentity = context.pendingIdentityExchange
            or context.semanticContextState
            and context.semanticContextState.pendingIdentityExchange
            or context.semanticDialogueContext
            and context.semanticDialogueContext.pendingIdentityExchange
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

    local topic = responseTopic(result, messages)
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
    local flowTopic = responseTopic({ decision = { flow = flow } })
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

    local ranking, orderedCandidates = ChoiceRanking.Apply(
        candidates, capabilities, context, currentTopic
    )
    candidates = orderedCandidates
    local groups, currentGroupID, rootGroupID = buildGroups(
        candidates, capabilities, currentTopic, revision, context
    )
    local dynamicCampCapabilities = {}
    appendCampSiteCapabilityRows(
        dynamicCampCapabilities, revision, context, ir
    )
    local campGroup
    for _, group in ipairs(groups or {}) do
        if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
            campGroup = group
            break
        end
    end
    if campGroup then
        for _, capability in ipairs(dynamicCampCapabilities) do
            -- Keep dynamic destinations in the camp group and in the
            -- authoritative capability projection, but add them after
            -- ranking so they can never leak onto the landing surface.
            capabilities[#capabilities + 1] = capability
            campGroup.capabilities[#campGroup.capabilities + 1] = capability
            campGroup.count = campGroup.count + 1
        end
    end
    if isCompanionOrderAction(currentAction) then
        for _, group in ipairs(groups or {}) do
            if group.id == Suggestions.COMPANION_ORDERS_GROUP_ID then
                currentGroupID = group.id
                break
            end
        end
    end

    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_dialogue_suggestions",
        activeHub = activeHubID and {
            id = activeHubID,
            route = "semantic_hub",
        } or nil,
        revision = revision,
        turnID = turnID,
        candidates = candidates,
        sources = {
            typedSource,
            planSource,
            flowSource,
            capabilitySource,
        },
        activeFlow = flowActive and {
            flowID = flow.flowId,
            nodeID = flow.toNodeId or flow.nodeId,
            revision = revision,
            responsePoolID = flow.responsePool,
        } or nil,
        permittedCapabilities = capabilities,
        groups = groups,
        currentTopic = currentTopic,
        currentGroupID = currentGroupID,
        rootGroupID = rootGroupID,
        allowBack = true,
        predicateTrace = predicateTrace,
        trace = trace,
        privacy = {
            playerVisible = true,
            privateFieldsInspected = false,
            unknownFieldsExposed = false,
        },
        choiceRegistry = ChoiceRegistry.Snapshot(),
        actorConversationContext = ActorConversationContext.PublicView(
            actorConversationContext
        ),
        ranking = ranking,
    }
end

