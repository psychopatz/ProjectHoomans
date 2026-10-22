-- Project Hoomans' companion/task capability choice provider.
--
-- The provider declares the choice contract only.  CapabilityCatalog and the
-- existing action adapters remain authoritative for dispatch and effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueCapabilityChoiceProvider or {}
PNC.Semantics.DialogueCapabilityChoiceProvider = Provider

Provider.id = "projecthoomans.capabilities"
Provider.sourceKind = "permitted_capability"
Provider.order = 80

Provider.Definitions = {
    FOLLOW = {
        id = "action.follow",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Follow_Label",
        labelFallback = "Ask them to follow",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Follow_Utterance",
        utteranceFallback = "Follow me.",
        constraints = {
            all = {
                { path = "actorAuthority.owned", op = "eq", value = true },
                { path = "actorAuthority.companion", op = "eq", value = true },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.followState.mode",
                    op = "not_in",
                    values = { "following", "follow" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
            },
        },
    },
    STAY = {
        id = "action.stay",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Stay_Label",
        labelFallback = "Ask them to stay",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Stay_Utterance",
        utteranceFallback = "Stay here.",
        constraints = {
            all = {
                { path = "actorAuthority.owned", op = "eq", value = true },
                { path = "actorAuthority.companion", op = "eq", value = true },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.followState.mode",
                    op = "not_in",
                    values = { "staying", "stay" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
            },
        },
    },
    WAIT_AT = {
        id = "action.wait_at",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_WaitAt_Label",
        labelFallback = "Ask them to wait there",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WaitAt_Utterance",
        utteranceFallback = "Wait there.",
        constraints = {
            all = {
                { path = "actorAuthority.owned", op = "eq", value = true },
                { path = "actorAuthority.companion", op = "eq", value = true },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
                { path = "suggestion.destination", op = "exists" },
            },
        },
    },
}

function Provider.Find(id)
    return Provider.Definitions[id]
end

function Provider.collect()
    local output = {}
    for action, definition in pairs(Provider.Definitions) do
        output[#output + 1] = {
            id = definition.id,
            action = action,
            topic = definition.topic,
            source = { kind = Provider.sourceKind },
        }
    end
    table.sort(output, function(left, right)
        return tostring(left.action) < tostring(right.action)
    end)
    return output
end

return Provider
