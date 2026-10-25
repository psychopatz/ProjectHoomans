PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local copyValue = Internal.copyValue
local canonicalTopic = Internal.canonicalTopic
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local addBranchOfferCandidate = Internal.addBranchOfferCandidate

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


Internal.appendTrace = appendTrace
Internal.appendBranchOffers = appendBranchOffers
Internal.appendConversationChoices = appendConversationChoices

return Suggestions
