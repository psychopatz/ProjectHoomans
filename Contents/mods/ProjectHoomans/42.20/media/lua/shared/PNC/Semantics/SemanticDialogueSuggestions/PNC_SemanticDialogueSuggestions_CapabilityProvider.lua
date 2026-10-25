-- Project Hoomans' companion/task capability choice provider.
--
-- The provider declares the choice contract only.  CapabilityCatalog and the
-- existing action adapters remain authoritative for dispatch and effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueCapabilityChoiceProvider or {}
PNC.Semantics.DialogueCapabilityChoiceProvider = Provider

-- These rows share one contextual Orders hub.  The authoritative command
-- registry and adapter still own the actual execution; this table only
-- describes which semantic capability may be projected into the hub.
local function companionOrderConstraints(extra)
    local constraints = {
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
        },
    }
    for _, predicate in ipairs(extra or {}) do
        constraints.all[#constraints.all + 1] = predicate
    end
    return constraints
end

Provider.id = "projecthoomans.capabilities"
Provider.sourceKind = "permitted_capability"
Provider.order = 80

Provider.Definitions = {
    FOLLOW = {
        id = "action.follow",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Follow_Label",
        labelFallback = "Follow me.",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Follow_Utterance",
        utteranceFallback = "Follow me.",
        groupID = "companion.orders",
        -- Follow/Stay are a toggle: expose only the actionable side of the
        -- durable order, rather than rendering the opposite side disabled.
        showWhenUnavailable = false,
        constraints = companionOrderConstraints({
            {
                path = "npcState.orderKind",
                op = "not_in",
                values = { "follow" },
            },
        }),
    },
    STAY = {
        id = "action.stay",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Stay_Label",
        labelFallback = "Wait here.",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Stay_Utterance",
        utteranceFallback = "Wait here.",
        groupID = "companion.orders",
        -- Follow/Stay are a toggle: expose only the actionable side of the
        -- durable order, rather than rendering the opposite side disabled.
        showWhenUnavailable = false,
        constraints = companionOrderConstraints({
            {
                path = "npcState.orderKind",
                op = "eq",
                value = "follow",
            },
        }),
    },
    WAIT_AT = {
        id = "action.wait_at",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_WaitAt_Label",
        labelFallback = "Ask them to wait there",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WaitAt_Utterance",
        utteranceFallback = "Wait there.",
        -- WAIT_AT remains a typed/world-target capability.  It is never a
        -- generic menu row; explicit destination requests are resolved by
        -- the existing task adapter and authority path.
        groupID = "companion.orders",
        menuOnlyWhenDestination = false,
        constraints = companionOrderConstraints({
            { path = "suggestion.destination", op = "exists" },
        }),
    },
    GO = {
        id = "action.go_home",
        topic = "movement",
        requiresOwnedCompanion = true,
        -- Keep this known owned action visible when no base exists so the
        -- semantic UI can explain why it is unavailable.
        showWhenUnavailable = true,
        unavailableReasonCode = "base_required",
        unavailableReasonPath = "baseEstablished",
        unavailableReasonKey =
            "UI_PNC_Conversation_Suggestion_GoHome_NoBase_Tooltip",
        unavailableReasonFallback =
            "Go Home is unavailable because no base has been established.",
        labelKey = "UI_PNC_CommandReturnHome",
        labelFallback = "Go home.",
        utteranceKey = "UI_PNC_CommandReturnHome",
        utteranceFallback = "Go home.",
        destination = { category = "HOME" },
        groupID = "companion.orders",
        constraints = companionOrderConstraints({
            {
                path = "baseEstablished",
                op = "eq",
                value = true,
            },
            {
                path = "npcState.activeBehavior",
                op = "not_in",
                values = { "AtHome", "AtHome:returning" },
            },
        }),
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
