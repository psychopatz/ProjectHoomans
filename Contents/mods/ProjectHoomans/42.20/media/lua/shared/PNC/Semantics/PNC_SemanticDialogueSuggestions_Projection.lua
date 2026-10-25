-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local ChoiceRegistry = Internal.ChoiceRegistry
local normalized = Internal.normalized
local normalizedText = Internal.normalizedText
local boundedText = Internal.boundedText
local copyValue = Internal.copyValue
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local canonicalTopic = Internal.canonicalTopic
local topicFromIR = Internal.topicFromIR
local semanticHubID = Internal.semanticHubID
local responseTopic = Internal.responseTopic
local sourceRecord = Internal.sourceRecord
local definitionFor = Internal.definitionFor
local definitionForSubject = Internal.definitionForSubject
local topicMatches = Internal.topicMatches
local topicGroupID = Internal.topicGroupID
local capabilityDefinitionFor = Internal.capabilityDefinitionFor
local projectedCapabilityFor = Internal.projectedCapabilityFor
local isActiveHubDefinition = Internal.isActiveHubDefinition
local isActiveHubCandidate = Internal.isActiveHubCandidate
local isCompanionOrderAction = Internal.isCompanionOrderAction
local companionAuthorityEligible = Internal.companionAuthorityEligible
local campSiteCandidateCount = Internal.campSiteCandidateCount
local addCandidate = Internal.addCandidate
local addProviderCandidate = Internal.addProviderCandidate
local addBranchOfferCandidate = Internal.addBranchOfferCandidate
local branchOfferFrame = Internal.branchOfferFrame
local predicateContextFor = Internal.predicateContextFor
local offersFromPlan = Internal.offersFromPlan
local offersFromMessages = Internal.offersFromMessages

local function appendTrace(trace, kind, status, reason, count)
    if #trace >= Suggestions.MAX_TRACE then return end
    trace[#trace + 1] = {
        source = kind,
        status = status,
        reason = reason,
        candidateCount = count,
    }
end

local function appendBranchOffers(
    candidates,
    seen,
    offers,
    kind,
    revision,
    context,
    ir,
    predicateTrace,
    defaultOrigin
)
    for _, item in ipairs(offers or {}) do
        local offer = item.offer or item
        local origin = item.origin or copyValue(defaultOrigin)
            or { kind = kind }
        addBranchOfferCandidate(
            candidates,
            seen,
            offer,
            kind,
            revision,
            "branch_offer",
            origin,
            context,
            ir,
            predicateTrace
        )
    end
end

local function appendConversationChoices(
    output, seen, context, revision, predicateTrace
)
    local block = type(context) == "table"
        and type(context.conversationBlock) == "table"
        and context.conversationBlock or nil
    if not block or type(block.choices) ~= "table" then return end
    for _, choice in ipairs(block.choices) do
        if type(choice) == "table" and tostring(choice.id or "") ~= "" then
            local candidateID = table.concat({
                "conversation.choice", tostring(block.blockID),
                tostring(block.nodeID), tostring(choice.id),
            }, ":")
            if not seen[candidateID] and #output < Suggestions.MAX_CANDIDATES then
                local text = tostring(choice.text or choice.id)
                local enabled = choice.enabled == true
                local status = enabled and "allowed" or "disabled"
                local reason = enabled and "production_choice_eligible"
                    or choice.lockedReasonKey or "production_choice_ineligible"
                predicateTrace[#predicateTrace + 1] = {
                    candidateID = candidateID,
                    source = "conversation_registry",
                    path = "conversationBlock.choices." .. tostring(choice.id),
                    status = enabled and "allowed" or "hidden",
                    reason = reason,
                }
                local frame = {
                    schemaVersion = Suggestions.VERSION,
                    kind = "semantic_click_frame",
                    candidateID = candidateID,
                    topic = canonicalTopic(block.topic) or "whats_up",
                    intent = "REQUEST",
                    speechAct = "REQUEST",
                    subject = "CONVERSATION_TOPIC",
                    extensions = {
                        route = "conversation_choice",
                        categoryID = block.categoryID,
                        blockID = block.blockID,
                        nodeID = block.nodeID,
                        choiceID = choice.id,
                    },
                    textKey = choice.textKey,
                    textFallback = text,
                    labelKey = choice.textKey,
                    requestRevision = revision,
                }
                local source = sourceRecord(
                    "conversation_registry", revision, reason
                )
                local candidate = {
                    id = candidateID,
                    topic = canonicalTopic(block.topic) or "whats_up",
                    groupID = "conversation_branch",
                    rank = #output + 1,
                    source = source,
                    sources = { source },
                    frame = frame,
                    enabled = enabled,
                    display = {
                        labelKey = choice.textKey,
                        labelFallback = text,
                        label = text,
                        utteranceKey = choice.textKey,
                        utteranceFallback = text,
                        utterance = text,
                    },
                    visibility = "player",
                    eligibility = {
                        status = enabled and "allowed" or "unavailable",
                        allowed = enabled,
                        reason = reason,
                    },
                }
                candidate = normalizeCandidate(
                    candidate, "conversation_registry", #output + 1
                )
                output[#output + 1] = candidate
                seen[candidateID] = candidate
            end
        end
    end
end

local function appendConversationRootChoices(
    output, seen, context, revision, predicateTrace
)
    local root = type(context) == "table"
        and type(context.conversationRoot) == "table"
        and context.conversationRoot or nil
    if not root or type(root.choices) ~= "table" then return end
    for _, choice in ipairs(root.choices) do
        local semantic = type(choice) == "table" and choice.semantic or nil
        local choiceID = type(choice) == "table"
            and tostring(choice.id or "") or ""
        if type(semantic) == "table" and choiceID ~= ""
            and (semantic.route == "conversation_category"
                or semantic.route == "conversation_root_choice")
            and not (
                choiceID == "show_debug_text"
                or choiceID == "view_dossier"
                or semantic.categoryID == "projecthoomans:set_territory"
                or semantic.categoryID == "projecthoomans:trade"
            )
            and #output < Suggestions.MAX_CANDIDATES
        then
            local candidateID = table.concat({
                "conversation.root", tostring(root.nodeID), choiceID,
            }, ":")
            if not seen[candidateID] then
                local topic = tostring(semantic.topic or "")
                -- Categories are a second-level context index. Direct root
                -- actions remain on the landing page. The authored choice
                -- still carries its original route, so the composer remains
                -- the owner when a category is selected.
                local directCategory = choiceID == "ceasefire"
                local groupID = semantic.route == "conversation_category"
                    and not directCategory
                    and Suggestions.CONTEXT_INDEX_GROUP_ID
                    or Suggestions.ROOT_GROUP_ID
                local text = boundedText(choice.text or choiceID, 160)
                local enabled = choice.enabled == true
                local reason = enabled and "production_root_choice_eligible"
                    or choice.tooltip or "production_root_choice_ineligible"
                if #predicateTrace < Predicates.MAX_TRACE then
                    predicateTrace[#predicateTrace + 1] = {
                        candidateID = candidateID,
                        source = "conversation_root",
                        path = "conversationRoot.choices." .. choiceID,
                        status = enabled and "allowed" or "hidden",
                        reason = reason,
                    }
                end
                local extensions = copyValue(semantic) or {}
                extensions.origin = "conversation_root"
                extensions.rootNodeID = root.nodeID
                extensions.rootChoiceID = choiceID
                local frame = {
                    schemaVersion = Suggestions.VERSION,
                    kind = "semantic_click_frame",
                    candidateID = candidateID,
                    topic = topic ~= "" and topic or nil,
                    intent = "REQUEST",
                    speechAct = "REQUEST",
                    subject = semantic.route == "conversation_category"
                        and "CONVERSATION_TOPIC" or "CONVERSATION_ACTION",
                    extensions = extensions,
                    textKey = choice.textKey,
                    textFallback = text,
                    labelKey = choice.textKey,
                    requestRevision = revision,
                }
                local source = sourceRecord(
                    "conversation_root", revision, reason
                )
                local candidate = {
                    id = candidateID,
                    topic = topic ~= "" and topic or nil,
                    groupID = groupID,
                    rank = #output + 1,
                    source = source,
                    sources = { source },
                    frame = frame,
                    enabled = enabled,
                    display = {
                        labelKey = choice.textKey,
                        labelFallback = text,
                        label = text,
                        utteranceKey = choice.textKey,
                        utteranceFallback = text,
                        utterance = text,
                    },
                    visibility = "player",
                    eligibility = {
                        status = enabled and "allowed" or "unavailable",
                        allowed = enabled,
                        reason = reason,
                    },
                }
                candidate = normalizeCandidate(
                    candidate, "conversation_root", #output + 1
                )
                output[#output + 1] = candidate
                seen[candidateID] = candidate
            end
        end
    end
end

local function hasConversationHistory(context)
    context = type(context) == "table" and context or {}
    local function isNonGreeting(topic)
        return topic ~= nil and tostring(topic) ~= "greeting"
    end
    if isNonGreeting(context.currentTopic)
        or isNonGreeting(context.previousTopic)
    then
        return true
    end
    local semantic = context.semanticDialogueContext
    if type(semantic) ~= "table" then return false end
    return isNonGreeting(semantic.currentTopic)
        or isNonGreeting(semantic.previousTopic)
        or #(semantic.priorTopics or {}) > 0
end

local function appendLandingShortcuts(
    output, seen, revision, predicateTrace
)
    local candidateID = "conversation.landing:whats_up"
    if seen[candidateID] or #output >= Suggestions.MAX_CANDIDATES then
        return
    end
    local labelKey = "UI_PNC_Conversation_Suggestion_WhatsUp_Label"
    local label = resolvedText(labelKey, "What's up?")
    local utterance = "What's up?"
    local frame = Suggestions.BuildShortcutFrame({
        candidateID = candidateID,
        topic = "whats_up",
        labelKey = labelKey,
        labelFallback = label,
        utterance = utterance,
        extensions = {
            route = "semantic_hub",
            hubID = "whats_up",
            canonicalConcept = "WHATS_UP",
            origin = "conversation_landing",
        },
    }, revision)
    if not frame then return end
    local source = sourceRecord(
        "conversation_root", revision, "conversation_landing_shortcut"
    )
    local candidate = {
        id = candidateID,
        topic = "whats_up",
        groupID = Suggestions.ROOT_GROUP_ID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = true,
        display = {
            labelKey = labelKey,
            labelFallback = label,
            label = label,
            utteranceFallback = utterance,
            utterance = utterance,
        },
        visibility = "player",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "conversation_landing_shortcut",
        },
    }
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "conversationLanding.whatsUp",
            status = "allowed",
            reason = "conversation_landing_shortcut",
        }
    end
    candidate = normalizeCandidate(
        candidate, "conversation_root", #output + 1
    )
    output[#output + 1] = candidate
    seen[candidateID] = candidate
end

local function appendTalkAgainAbout(
    output, seen, context, revision, predicateTrace
)
    local candidateID = "conversation.landing:talk_again_about"
    if seen[candidateID]
        or not hasConversationHistory(context)
        or #output >= Suggestions.MAX_CANDIDATES
    then
        return
    end
    local labelKey =
        "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label"
    local label = resolvedText(labelKey, "Talk again about")
    local frame = Suggestions.BuildGroupFrame({
        id = Suggestions.CONTEXT_INDEX_GROUP_ID,
        label = label,
        labelKey = labelKey,
        allowBack = true,
    }, revision)
    if not frame then return end
    local source = sourceRecord(
        "conversation_root", revision, "conversation_context_index"
    )
    local candidate = {
        id = candidateID,
        groupID = Suggestions.ROOT_GROUP_ID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = true,
        display = {
            labelKey = labelKey,
            labelFallback = label,
            label = label,
        },
        visibility = "player",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "conversation_context_history",
        },
    }
    candidate = normalizeCandidate(
        candidate, "conversation_root", #output + 1
    )
    output[#output + 1] = candidate
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "conversationLanding.contextIndex",
            status = "allowed",
            reason = "conversation_context_history",
        }
    end
    seen[candidateID] = output[#output]
end

local GROUP_LABELS = {
    whats_up = {
        key = "UI_PNC_Conversation_Suggestion_Group_WhatsUp_Label",
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


Internal.appendTrace = appendTrace
Internal.appendBranchOffers = appendBranchOffers
Internal.appendConversationChoices = appendConversationChoices
Internal.appendConversationRootChoices = appendConversationRootChoices
Internal.appendLandingShortcuts = appendLandingShortcuts
Internal.appendTalkAgainAbout = appendTalkAgainAbout
Internal.buildGroups = buildGroups

