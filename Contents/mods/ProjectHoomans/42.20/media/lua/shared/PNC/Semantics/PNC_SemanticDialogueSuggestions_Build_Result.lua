-- Suggestion-build ranking, groups, and final bounded projection.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal
local ChoiceRanking = Internal.ChoiceRanking
local appendCampSiteCapabilityRows = Internal.appendCampSiteCapabilityRows
local isCompanionOrderAction = Internal.isCompanionOrderAction
local buildGroups = Internal.buildGroups
local ActorConversationContext = Internal.ActorConversationContext
local HubPresentation = require
    "PNC/Semantics/PNC_SemanticDialogueSuggestions_HubPresentation"

function Internal.FinalizeSuggestionBuild(state)
    -- Filter only the currently visible What's Up avenue rows. This happens
    -- before ranking and grouping so counts, ordering, and native/harness
    -- choice surfaces all agree while semantic input remains unrestricted.
    local visibleCandidates =
        HubPresentation.FilterCandidates(
            state.candidates,
            state.context,
            state.activeHubID
        )
    state.candidates = visibleCandidates

    local ranking, orderedCandidates = ChoiceRanking.Apply(
        state.candidates,
        state.capabilities,
        state.context,
        state.currentTopic
    )
    local candidates = orderedCandidates
    local groups, currentGroupID, rootGroupID = buildGroups(
        candidates,
        state.capabilities,
        state.currentTopic,
        state.revision,
        state.context
    )
    local dynamicCampCapabilities = {}
    appendCampSiteCapabilityRows(
        dynamicCampCapabilities,
        state.revision,
        state.context,
        state.ir
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
            state.capabilities[#state.capabilities + 1] = capability
            campGroup.capabilities[#campGroup.capabilities + 1] = capability
            campGroup.count = campGroup.count + 1
        end
    end
    if isCompanionOrderAction(state.currentAction) then
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
        activeHub = state.activeHubID and {
            id = state.activeHubID,
            route = "semantic_hub",
        } or nil,
        revision = state.revision,
        turnID = state.turnID,
        candidates = candidates,
        sources = {
            state.typedSource,
            state.planSource,
            state.flowSource,
            state.capabilitySource,
        },
        activeFlow = state.flowActive and {
            flowID = state.flow.flowId,
            nodeID = state.flow.toNodeId or state.flow.nodeId,
            revision = state.revision,
            responsePoolID = state.flow.responsePool,
        } or nil,
        permittedCapabilities = state.capabilities,
        groups = groups,
        currentTopic = state.currentTopic,
        currentGroupID = currentGroupID,
        rootGroupID = rootGroupID,
        allowBack = true,
        predicateTrace = state.predicateTrace,
        trace = state.trace,
        privacy = {
            playerVisible = true,
            privateFieldsInspected = false,
            unknownFieldsExposed = false,
        },
        choiceRegistry = Internal.ChoiceRegistry.Snapshot(),
        actorConversationContext = ActorConversationContext.PublicView(
            state.actorConversationContext
        ),
        ranking = ranking,
    }
end

return Suggestions
