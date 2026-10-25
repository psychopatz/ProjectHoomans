-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local IR = Internal.IR
local Identity = Internal.Identity
local boundedText = Internal.boundedText
local copyValue = Internal.copyValue
local normalized = Internal.normalized
local normalizedText = Internal.normalizedText
local resolvedText = Internal.resolvedText

function Suggestions.IsConversationCategoryFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "conversation_category"
        and string.sub(tostring(extensions.categoryID or ""), 1, 15)
            == "projecthoomans:"
        and tostring(extensions.topic or "") ~= ""
end

function Suggestions.IsConversationCategoryAvailable(frame, context)
    if not Suggestions.IsConversationCategoryFrame(frame) then
        return false, "conversation_category_frame_invalid"
    end
    local categoryID = frame.extensions.categoryID
    local preflight = type(context) == "table"
        and context.conversationCategoryPreflight or nil
    if type(preflight) == "table"
        and tostring(preflight.categoryID or categoryID) == categoryID
    then
        return preflight.visible == true,
            preflight.reason or "category_preflight"
    end
    for _, diagnostic in ipairs(
        type(context) == "table" and context.categoryDiagnostics or {}
    ) do
        if type(diagnostic) == "table"
            and tostring(diagnostic.id or "") == categoryID
        then
            return diagnostic.visible == true,
                diagnostic.reason or "category_diagnostic"
        end
    end
    return false, "category_preflight_unknown"
end

function Suggestions.BuildGroupFrame(group, revision)
    group = type(group) == "table" and group or {}
    local groupID = tostring(group.id or "")
    if groupID == "" then return nil end
    local utterance = group.utterance
        or group.textFallback
        or group.label
        or group.labelFallback
        or groupID
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_group_click_frame",
        candidateID = "semantic.group:" .. groupID,
        groupID = groupID,
        parentGroupID = group.parentGroupID,
        topic = group.topic,
        labelKey = group.labelKey,
        labelFallback = group.label or groupID,
        textFallback = utterance,
        utteranceFallback = utterance,
        utterance = utterance,
        navigationExchange = true,
        navigationKind = group.navigationKind or "topic",
        navigationSubject = group.navigationSubject or "CONVERSATION_TOPIC",
        requestRevision = tonumber(revision) or 0,
    }
end

function Suggestions.BuildShortcutFrame(options, revision)
    options = type(options) == "table" and options or {}
    local candidateID = tostring(options.candidateID or "")
    local utterance = boundedText(
        options.utterance or options.textFallback or "", 160
    )
    if candidateID == "" or utterance == "" then return nil end
    local labelFallback = boundedText(
        options.labelFallback or utterance, 160
    )
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_shortcut_frame",
        candidateID = candidateID,
        topic = options.topic,
        intent = options.intent or "QUESTION",
        speechAct = options.speechAct or "QUESTION",
        subject = options.subject or "CONVERSATION_TOPIC",
        textFallback = utterance,
        utteranceFallback = utterance,
        utterance = utterance,
        labelKey = options.labelKey,
        labelFallback = labelFallback,
        extensions = copyValue(options.extensions) or {},
        requestRevision = tonumber(revision) or 0,
        allowBack = options.allowBack,
    }
end

function Suggestions.IsShortcutFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_shortcut_frame"
        and tostring(frame.candidateID or "") ~= ""
        and tostring(frame.textFallback or frame.utterance or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.BuildBackFrame(revision, fromGroupID, context)
    fromGroupID = tostring(fromGroupID or "")
    if fromGroupID == "" then return nil end
    context = type(context) == "table" and context or {}
    local parents = type(context.semanticGroupParents) == "table"
        and context.semanticGroupParents or {}
    local targetGroupID = tostring(
        parents[fromGroupID] or Suggestions.ROOT_GROUP_ID
    )
    local labelKey =
        "UI_PNC_Conversation_Suggestion_TalkSomethingElse_Label"
    local label = resolvedText(labelKey, "Let's talk something else")
    local seed = context.saveSeed
        or context.playerIdentitySeed
        or context.npcID
        or "semantic_navigation"
    local replies = {
        "Let's talk about something else.",
        "Maybe we should change the subject.",
        "There's something else I wanted to discuss.",
    }
    local reply = replies[Identity.Index(
        seed,
        table.concat({
            "semantic_back_reply",
            tostring(context.playerIdentitySeed or "player"),
            tostring(context.npcID or "npc"),
            fromGroupID,
        }, ":"),
        #replies
    )]
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_back_click_frame",
        candidateID = "semantic.back_to_root:" .. fromGroupID,
        groupID = targetGroupID,
        fromGroupID = fromGroupID,
        utterance = reply,
        textFallback = reply,
        utteranceFallback = reply,
        playerReply = true,
        navigationReply = true,
        navigationExchange = true,
        navigationKind = "subject_change",
        navigationSubject = "CONVERSATION_TOPIC",
        labelKey = labelKey,
        labelFallback = label,
        requestRevision = tonumber(revision) or 0,
    }
end

function Suggestions.IsBackFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_back_click_frame"
        and tostring(frame.candidateID or "") ~= ""
        and tostring(frame.fromGroupID or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.IsGroupFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_group_click_frame"
        and tostring(frame.groupID or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.IsNavigationFrame(frame)
    return (Suggestions.IsBackFrame(frame)
            or Suggestions.IsGroupFrame(frame))
        and frame.navigationExchange ~= false
end

function Suggestions.NavigationFrameToIR(frame, view)
    if not Suggestions.IsNavigationFrame(frame) then
        return nil, "navigation_frame_invalid"
    end
    local actorID = view and view.spec and view.spec.npcID or nil
    local value = Suggestions.ResolveFrameText(frame)
    if value == "" then return nil, "navigation_frame_text_missing" end
    return IR.New({
        kind = "semantic_navigation_frame",
        rawText = value,
        normalizedText = normalizedText(value),
        intent = "NAVIGATE",
        speechAct = "NAVIGATE",
        subject = frame.navigationSubject or "CONVERSATION_TOPIC",
        target = {
            kind = "actor",
            id = actorID,
            source = "conversation",
        },
        slots = {
            npcID = actorID,
        },
        extensions = {
            topic = frame.topic or "conversation_navigation",
            navigationKind = frame.navigationKind or "topic",
            fromGroupID = frame.fromGroupID or frame.parentGroupID,
            toGroupID = frame.groupID,
            candidateID = frame.candidateID,
        },
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_navigation_frame",
            pattern = frame.navigationKind or "semantic_navigation",
            candidateID = frame.candidateID,
        },
    })
end

function Suggestions.IsConversationChoiceFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "conversation_choice"
        and string.sub(tostring(extensions.categoryID or ""), 1, 15)
            == "projecthoomans:"
        and tostring(extensions.blockID or "") ~= ""
        and tostring(extensions.nodeID or "") ~= ""
        and tostring(extensions.choiceID or "") ~= ""
end

function Suggestions.IsConversationRootChoiceFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    if extensions.origin ~= "conversation_root"
        or (extensions.route ~= "conversation_category"
            and extensions.route ~= "conversation_root_choice")
        or tostring(extensions.rootNodeID or "") == ""
    then
        return false
    end
    if extensions.route == "conversation_category" then
        return Suggestions.IsConversationCategoryFrame(frame)
            and tostring(extensions.rootChoiceID or "") ~= ""
    end
    return tostring(extensions.actionID or "") ~= ""
end


