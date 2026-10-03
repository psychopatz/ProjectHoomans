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
    if type(ir) ~= "table" or type(ir.diagnostics) ~= "table"
        or ir.diagnostics.fuzzyMatch ~= true
        or ir.intent ~= "REQUEST"
    then
        return false
    end
    if type(options) == "table" and options.allowFuzzyActions == true then
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
    -- Location/seen queries are read-only and have explicit unknown and
    -- ambiguous responses, so entity resolution is not required to answer.
    return type(ir) == "table"
        and ir.intent == "QUESTION"
        and (ir.subject == "LOCATION" or ir.subject == "SEEN")
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
    return not (ir and ir.intent == "QUESTION" and ir.subject == "IDENTITY")
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
Internal.UnresolvedWorldTargetRequest = unresolvedWorldTargetRequest
Internal.IsIdentityClaim = isIdentityClaim
Internal.IsIdentityEvasion = isIdentityEvasion
Internal.GiftConsentFor = giftConsentFor

return Policy
