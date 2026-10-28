-- Semantic dialogue policy classifiers and gift consent helpers.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Policy = PNC.Semantics.DialoguePolicy
local Internal = Policy.Internal or {}
Policy.Internal = Internal
local SemanticOffer = Internal.SemanticOffer
local FUZZY_SAFE_ACTIONS = Internal.FuzzySafeActions
local ITEM_REQUEST_ACTIONS = Internal.ItemRequestActions

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function thresholds(options)
    options = type(options) == "table" and options or {}
    local values = type(options.thresholds) == "table"
        and options.thresholds or {}
    return {
        high = tonumber(values.high) or Policy.DEFAULT_HIGH_THRESHOLD,
        medium = tonumber(values.medium)
            or Policy.DEFAULT_MEDIUM_THRESHOLD,
    }
end

local function llmEnabled(context, options)
    return type(options) == "table" and options.llmEnabled == true
        or type(context) == "table" and (
            context.llmEnabled == true or context.llmAvailable == true
        )
end

local function fuzzyActionNeedsConfirmation(ir, options)
    if type(ir) ~= "table" or ir.intent ~= "REQUEST" then
        return false
    end
    local diagnostics = type(ir.diagnostics) == "table"
        and ir.diagnostics or {}
    local provenance = type(ir.provenance) == "table"
        and ir.provenance or {}
    local fuzzy = diagnostics.fuzzyMatch == true
    local recovered = diagnostics.recoveredMatch == true
        or type(provenance.surfaceRecovery) == "table"
    if not fuzzy and not recovered then return false end

    options = type(options) == "table" and options or {}
    if fuzzy and not recovered and options.allowFuzzyActions == true then
        return false
    end
    if recovered and options.allowRecoveredActions == true then
        return false
    end
    return not FUZZY_SAFE_ACTIONS[ir.action]
end

local function unresolvedItemRequest(ir)
    local object = ir and ir.object
    if ir and ir.intent ~= "REQUEST"
        or not ITEM_REQUEST_ACTIONS[ir and ir.action]
        or type(object) ~= "table"
        or object.reference ~= nil
    then
        return false
    end
    if object.unresolved ~= true then return false end
    return tostring(object.text or object.value or "") ~= ""
end

local function unresolvedOffer(ir)
    local object = ir and ir.object
    return ir and ir.intent == "OFFER"
        and type(object) == "table"
        and object.unresolved == true
        and tostring(object.text or object.value or "") ~= ""
end

local function classifyGiftOffer(ir)
    if not SemanticOffer
        or type(SemanticOffer.Classify) ~= "function"
    then
        return nil
    end
    local ok, offer = pcall(SemanticOffer.Classify, ir)
    return ok and type(offer) == "table" and offer or nil
end

local function isInventoryQuery(ir)
    return type(ir) == "table"
        and ir.intent == "QUESTION"
        and ir.subject == "INVENTORY"
        and type(ir.inventoryQuery) == "table"
end

local function isLocalFactQuestion(ir)
    -- Read-only fact questions have explicit unknown responses, so entity
    -- resolution is not required before a local provider can answer.
    local subjects = {
        LOCATION = true,
        SEEN = true,
        NPC_RESIDENCE = true,
        NPC_HEALTH_STATE = true,
        NPC_KNOWLEDGE = true,
        RELATIONSHIP_STATUS = true,
    }
    return type(ir) == "table"
        and ir.intent == "QUESTION"
        and subjects[ir.subject] == true
end

local function isBackstoryContextQuestion(ir, context)
    if type(ir) ~= "table"
        or ir.intent ~= "QUESTION"
        or ir.subject ~= "CONTEXT_REFERENCE"
    then
        return false
    end
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    local questionKind = extensions.contextQuestion
    if questionKind ~= "BACKSTORY_LOCATION"
        and questionKind ~= "BACKSTORY_MISS"
    then
        return false
    end

    -- A generated context-reference pattern may intentionally leave a
    -- short target such as "where" unresolved.  It is safe to route that
    -- question to the bounded backstory responder only when this same
    -- conversation has a recent NPC backstory answer.  This preserves the
    -- normal clarification gate for every other unresolved reference.
    local dialogue = type(context) == "table" and (
        context.semanticContextState or context.semanticDialogueContext
    ) or nil
    if type(dialogue) ~= "table" then return false end
    if dialogue.lastBackstoryKind ~= nil then return true end

    local turns = dialogue.recentTurns
    if type(turns) ~= "table" then return false end
    local index
    local turn
    for index = 1, #turns do
        turn = turns[index]
        if type(turn) == "table"
            and turn.speaker == "npc"
            and turn.speechAct == "ANSWER"
            and turn.subject == "NPC_BACKSTORY"
        then
            return true
        end
    end
    return false
end

local function unresolvedWorldTargetRequest(ir)
    local target = ir and ir.target
    return type(ir) == "table"
        and ir.intent == "REQUEST"
        and (ir.action == "WAIT_AT" or ir.action == "CAMP")
        and type(target) == "table"
        and target.unresolved == true
        and tostring(target.text or target.value or "") ~= ""
end

local function isIdentityClaim(ir)
    return type(ir) == "table"
        and type(ir.socialContext) == "table"
        and ir.socialContext.identityClaim == true
end

local ENTITY_INDEPENDENT_SOCIAL_ACTS = {
    GREET = true,
    COMPLIMENT = true,
    SELF_REFLECTION = true,
    INSULT = true,
    HOSTILE_REMARK = true,
    THREATEN = true,
    THANK = true,
    ACKNOWLEDGE = true,
    APOLOGIZE = true,
    AGREE = true,
    DISAGREE = true,
    ACCEPT = true,
    REFUSE = true,
}

local function isEntityIndependentSocialAct(ir)
    if type(ir) ~= "table" then return false end
    local intent = tostring(ir.intent or "")
    local speechAct = tostring(ir.speechAct or "")
    if ENTITY_INDEPENDENT_SOCIAL_ACTS[intent] ~= true
        and ENTITY_INDEPENDENT_SOCIAL_ACTS[speechAct] ~= true
    then
        return false
    end
    -- These acts are conversationally meaningful without resolving a world
    -- entity. A trailing typo may be exposed as an unresolved parser token,
    -- but it must not erase a high-confidence social interpretation such as
    -- directed profanity. Gameplay actions still use their own stricter gates.
    return ir.action == nil
end

local function pendingIdentityExchange(state, context)
    local semanticState = context and context.semanticContextState
    local pending = context and context.pendingIdentityExchange
        or semanticState and semanticState.pendingIdentityExchange
        or context and context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
    if type(pending) == "table" then return pending end
    local question = state and state.pendingQuestion
    if type(question) == "table" and question.subject == "IDENTITY" then
        return question
    end
    return nil
end

local function isIdentityEvasion(ir, state, context)
    if not pendingIdentityExchange(state, context)
        or isIdentityClaim(ir)
    then
        return false
    end
    -- An interruption is not an evasion.  Only an explicit refusal or
    -- disagreement resolves the pending identity obligation as evasion;
    -- ordinary questions, state reports, and social turns remain harmless.
    return ir and (ir.intent == "REFUSE" or ir.intent == "DISAGREE")
end

local function giftConsentFor(ir, context)
    local pending = context and context.pendingGiftConsent or nil
    if type(pending) ~= "table" then return nil end

    local accepts = ir and (ir.intent == "ACCEPT" or ir.intent == "AGREE")
    local refuses = ir and (ir.intent == "REFUSE" or ir.intent == "DISAGREE")
    if not accepts and not refuses then return nil end

    local candidates = type(pending.candidates) == "table"
        and pending.candidates or {}
    if #candidates == 0 then return nil end

    local output = {
        groupID = pending.groupID,
        query = pending.query,
        quantity = pending.quantity,
        candidateCount = #candidates,
    }
    if refuses then
        output.status = "declined"
        if #candidates == 1 then
            output.recipientID = candidates[1].npcID
            output.recipientName = candidates[1].name
        end
        return output
    end

    if pending.overflow == true or #candidates ~= 1 then
        output.status = "ambiguous"
        return output
    end

    local recipientID = tostring(candidates[1].npcID or "")
    if recipientID == "" then return nil end
    output.status = "granted"
    output.recipientID = recipientID
    output.recipientName = candidates[1].name
    output.offer = {
        mode = "explicit",
        query = pending.query,
        quantity = pending.quantity,
    }
    return output
end


Internal.CopyValue = copyValue
Internal.Thresholds = thresholds
Internal.LLMEnabled = llmEnabled
Internal.FuzzyActionNeedsConfirmation = fuzzyActionNeedsConfirmation
Internal.UnresolvedItemRequest = unresolvedItemRequest
Internal.UnresolvedOffer = unresolvedOffer
Internal.ClassifyGiftOffer = classifyGiftOffer
Internal.IsInventoryQuery = isInventoryQuery
Internal.IsLocalFactQuestion = isLocalFactQuestion
Internal.IsBackstoryContextQuestion = isBackstoryContextQuestion
Internal.UnresolvedWorldTargetRequest = unresolvedWorldTargetRequest
Internal.IsIdentityClaim = isIdentityClaim
Internal.IsEntityIndependentSocialAct = isEntityIndependentSocialAct
Internal.IsIdentityEvasion = isIdentityEvasion
Internal.GiftConsentFor = giftConsentFor

return Policy
