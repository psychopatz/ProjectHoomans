PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local resolvedText = Internal.resolvedText
local topicGroupID = Internal.topicGroupID
local Content = PNC.Semantics.ConversationRegistry
    or require "PNC/Semantics/Generated/Conversation/Registry"
local WhatsUpContent = Content.PlayerChoice
    and Content.PlayerChoice("conversation.landing:whats_up") or {}

local GROUP_LABELS = {
    whats_up = {
        key = WhatsUpContent.labelKey
            or "UI_PNC_Conversation_Suggestion_Group_WhatsUp_Label",
        fallback = "What's up",
    },
    wellbeing = {
        key = "UI_PNC_Conversation_Suggestion_Group_Wellbeing_Label",
        fallback = "Wellbeing",
    },
    needs = {
        key = "UI_PNC_Conversation_Suggestion_Group_Needs_Label",
        fallback = "Needs",
    },
    medical = {
        key = "UI_PNC_Conversation_Suggestion_Group_Medical_Label",
        fallback = "Medical",
    },
    identity = {
        key = "UI_PNC_Conversation_Suggestion_Group_Identity_Label",
        fallback = "Identity",
    },
    time = {
        key = "UI_PNC_Conversation_Suggestion_Group_Time_Label",
        fallback = "Time and date",
    },
    date = {
        key = "UI_PNC_Conversation_Suggestion_Group_Time_Label",
        fallback = "Time and date",
    },
    weather = {
        key = "UI_PNC_Conversation_Suggestion_Group_Weather_Label",
        fallback = "Weather",
    },
    movement = {
        key = "UI_PNC_Conversation_Suggestion_Group_Movement_Label",
        fallback = "Owned companion actions",
    },
    companion_orders = {
        key = "UI_PNC_Conversation_Suggestion_CompanionOrders_Label",
        fallback = "I need you to do something...",
    },
    companion_camp = {
        key = "UI_PNC_Conversation_Suggestion_CompanionCamp_Label",
        fallback = "Let's camp...",
    },
}

local function groupPresentation(id, topic)
    if id == Suggestions.ROOT_GROUP_ID then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Landing_Label",
                "Talk"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Landing_Label",
            allowBack = true,
        }
    end
    if id == Suggestions.CONTEXT_INDEX_GROUP_ID then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label",
                "Talk again about"
            ),
            labelKey =
                "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label",
            allowBack = true,
        }
    end
    if id == "semantic_hub.whats_up" then
        local label = GROUP_LABELS.whats_up
        return {
            id = id,
            topic = "whats_up",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
        }
    end
    if id == Suggestions.COMPANION_ORDERS_GROUP_ID then
        local label = GROUP_LABELS.companion_orders
        return {
            id = id,
            topic = "movement",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
            allowBack = true,
        }
    end
    if id == Suggestions.COMPANION_CAMP_GROUP_ID then
        local label = GROUP_LABELS.companion_camp
        return {
            id = id,
            topic = "movement",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
            allowBack = true,
        }
    end
    local label = GROUP_LABELS[topic]
    if label then
        return {
            id = id,
            topic = topic,
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
        }
    end
    if id == "active_flow" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
                "Current conversation branch"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
        }
    end
    if id == "conversation_branch" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
                "Current conversation branch"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
        }
    end
    if id == "npc_response_plan" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Response_Label",
                "NPC reply"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Response_Label",
        }
    end
    if string.sub(tostring(id or ""), 1, 6) == "topic:" then
        local topicID = tostring(topic or string.sub(id, 7))
        local key = "category." .. topicID
        local categoryLabel = resolvedText(key, topicID)
        local text = PsychopatzCore and PsychopatzCore.Conversation
            and PsychopatzCore.Conversation.Text or nil
        if text and type(text.Resolve) == "function" then
            local ok, value = pcall(text.Resolve, {
                key = key,
                domain = "pnc.system.shared.categories",
                fallback = categoryLabel,
            })
            if ok and type(value) == "string" and value ~= "" then
                categoryLabel = value
            end
        end
        return {
            id = id,
            topic = topicID,
            label = categoryLabel,
            labelKey = key,
        }
    end
    if id == "conversation_actions" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Actions_Label",
                "Conversation actions"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Actions_Label",
        }
    end
    if id == "conversation_utilities" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Utilities_Label",
                "Conversation utilities"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Utilities_Label",
        }
    end
    return { id = id, label = id }
end

local function buildGroups(
    candidates, capabilities, currentTopic, revision, context
)
    local groups = {}
    local byID = {}
    local function ensure(id, topic)
        if not id then return nil end
        if not byID[id] then
            local group = groupPresentation(id, topic)
            group.candidates = {}
            group.capabilities = {}
            group.count = 0
            group.allowBack = true
            group.frame = Suggestions.BuildGroupFrame(group, revision)
            byID[id] = group
            groups[#groups + 1] = group
        end
        return byID[id]
    end
    for _, candidate in ipairs(candidates or {}) do
        local group = ensure(
            candidate.groupID or candidate.topic and "topic:" .. candidate.topic
                or candidate.source and candidate.source.kind,
            candidate.topic
        )
        if group then
            group.candidates[#group.candidates + 1] = candidate
            group.count = group.count + 1
            if candidate.allowBack == false
                or candidate.frame and candidate.frame.allowBack == false
                or candidate.frame and type(candidate.frame.extensions)
                    == "table"
                    and candidate.frame.extensions.allowBack == false
            then
                group.allowBack = false
            end
        end
    end
    for _, capability in ipairs(capabilities or {}) do
        local group = ensure(capability.groupID or "owned_actions", "movement")
        if group then
            group.capabilities[#group.capabilities + 1] = capability
            group.count = group.count + 1
            if capability.allowBack == false then group.allowBack = false end
        end
    end
    if byID[Suggestions.COMPANION_ORDERS_GROUP_ID] then
        -- The camp branch is a semantic navigation surface even before its
        -- dynamic site rows are projected. P12F fills it from live CampSite
        -- discovery; no room or Java object is retained here.
        ensure(Suggestions.COMPANION_CAMP_GROUP_ID, "movement")
    end
    context.semanticGroupParents = type(context.semanticGroupParents) == "table"
        and context.semanticGroupParents or {}
    context.semanticGroupParents[Suggestions.COMPANION_ORDERS_GROUP_ID] =
        Suggestions.ROOT_GROUP_ID
    context.semanticGroupParents[Suggestions.COMPANION_CAMP_GROUP_ID] =
        Suggestions.COMPANION_ORDERS_GROUP_ID
    local rootGroupID = byID[Suggestions.ROOT_GROUP_ID]
        and Suggestions.ROOT_GROUP_ID or nil
    -- The authored greeting is the opening lifecycle state, not a selected
    -- semantic topic. Keep the first Talk surface on the landing page.
    local semanticTopicActive = currentTopic
        and tostring(currentTopic) ~= "greeting"
    local requestedGroupID = context and context.activeSuggestionGroupID
    local requestedNonRootGroup = requestedGroupID
        and requestedGroupID ~= Suggestions.ROOT_GROUP_ID
    local currentGroupID = requestedNonRootGroup and byID[requestedGroupID]
        and requestedGroupID
        or not semanticTopicActive and rootGroupID
        or currentTopic == "whats_up"
        and byID["semantic_hub.whats_up"]
        and "semantic_hub.whats_up" or topicGroupID(currentTopic)
    if not byID[currentGroupID] then
        currentGroupID = byID.conversation_branch and "conversation_branch"
            or byID.active_flow and "active_flow"
            or byID.npc_response_plan and "npc_response_plan"
            or byID.owned_actions and "owned_actions"
            or groups[1] and groups[1].id
    end
    if rootGroupID then
        for index, group in ipairs(groups) do
            if group.id == rootGroupID and index ~= 1 then
                table.remove(groups, index)
                table.insert(groups, 1, group)
                break
            end
        end
    end
    -- Navigation is part of the shared projection, not a renderer-only
    -- convenience. Native Core and Semantic Lab must receive the same typed
    -- presentation frame and the same allowBack gate.
    for _, group in ipairs(groups) do
        group.navigation = {}
        if rootGroupID
            and group.id ~= rootGroupID
            and group.allowBack ~= false
            and Suggestions.BuildBackFrame
        then
            local frame = Suggestions.BuildBackFrame(revision, group.id, context)
            if frame then
                group.navigation[#group.navigation + 1] = {
                    id = frame.candidateID,
                    frame = frame,
                    display = {
                        label = frame.labelFallback,
                        labelFallback = frame.labelFallback,
                    },
                    source = {
                        kind = "semantic_back_navigation",
                        revision = revision,
                        fromGroupID = group.id,
                    },
                }
            end
        end
    end
    return groups, currentGroupID, rootGroupID

end

Internal.buildGroups = buildGroups

return Suggestions
