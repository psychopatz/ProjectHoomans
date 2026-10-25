PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local boundedText = Internal.boundedText
local copyValue = Internal.copyValue
local canonicalTopic = Internal.canonicalTopic
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord

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


Internal.appendConversationRootChoices = appendConversationRootChoices

return Suggestions
