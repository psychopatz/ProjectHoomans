PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local SemanticOffer = PNC.Gifts
    and PNC.Gifts.Foundation
    and PNC.Gifts.Foundation.SemanticOffer or nil
if type(SemanticOffer) ~= "table" then
    local loaded = require "PNC/Gifts/PNC_GiftSemanticOffer"
    SemanticOffer = type(loaded) == "table" and loaded or nil
end
local Policy = PNC.Semantics.DialoguePolicy or {}
PNC.Semantics.DialoguePolicy = Policy
local LocalResponse = PNC.Semantics.LocalResponse
if type(LocalResponse) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueLocalResponse"
    LocalResponse = type(loaded) == "table" and loaded or nil
end

Policy.VERSION = 1
Policy.DEFAULT_HIGH_THRESHOLD = 0.85
Policy.DEFAULT_MEDIUM_THRESHOLD = 0.60

local COMMAND_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
    GO = true,
    HELP = true,
    FETCH = true,
    GIVE = true,
    TAKE = true,
    WAIT_AT = true,
    CAMP = true,
    EAT = true,
    DRINK = true,
    REFILL = true,
    CONSUME = true,
}

function Policy.GetCommandActions()
    local actions = {}
    for action in pairs(COMMAND_ACTIONS) do
        actions[#actions + 1] = action
    end
    table.sort(actions)
    return actions
end

-- Fuzzy recognition is useful for low-risk conversational movement commands,
-- but a typo must not silently turn into an inventory or task side effect.
local FUZZY_SAFE_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
}

-- A literal item name is intentionally allowed to remain unresolved here.
-- The authoritative item selector must still classify it and find an actual
-- inventory entry before any gameplay effect can occur.
local ITEM_REQUEST_ACTIONS = {
    FETCH = true,
    GIVE = true,
    EAT = true,
    DRINK = true,
    REFILL = true,
    CONSUME = true,
}

local RESPONSE_TEMPLATES = {
    COMMAND_ACCEPTED = {
        templateID = "semantic.command.accepted",
        fallback = "Okay.",
    },
    REQUEST_ACKNOWLEDGED = {
        templateID = "semantic.request.acknowledged",
        fallback = "I'll see what I can do.",
    },
    QUESTION_RECEIVED = {
        templateID = "semantic.question.received",
        fallback = "Let me think about that.",
    },
    INVENTORY_QUERY_RECEIVED = {
        templateID = "semantic.inventory.query.pending",
        fallback = "Let me check what I have.",
    },
    SOCIAL_ACKNOWLEDGED = {
        templateID = "semantic.social.acknowledged",
        fallback = "Understood.",
    },
    GREET_ACKNOWLEDGED = {
        templateID = "semantic.greet.acknowledged",
        fallback = "Hey there.",
    },
    OFFER_RECEIVED = {
        templateID = "semantic.offer.received",
        fallback = "I'd really like one. Could I have it?",
    },
    GIFT_SELECTION_REQUIRED = {
        templateID = "semantic.gift.selection_required",
        fallback = "Oh? What did you bring me?",
    },
    GIFT_OFFER_DISPATCHED = {
        templateID = "semantic.gift.pending",
        fallback = "",
    },
    GIFT_CONSENT_DECLINED = {
        templateID = "semantic.gift.consent.declined",
        fallback = "No problem. I'll leave it with you.",
    },
    GIFT_CONSENT_AMBIGUOUS = {
        templateID = "semantic.gift.consent.ambiguous",
        fallback = "More than one of us wants it. Please offer it to one person directly.",
    },
    GOSSIP_RECEIVED = {
        templateID = "semantic.gossip.unknown",
        fallback = "I haven't heard anything about that yet.",
    },
    HOSTILE_REMARK_RECEIVED = {
        templateID = "semantic.social.hostile_remark",
        fallback = "Don't talk to me like that.",
    },
    SELF_REFLECTION_RECEIVED = {
        templateID = "semantic.social.self_reflection",
        fallback = "Don't talk about yourself like that.",
    },
    IDENTITY_CLAIM_RECEIVED = {
        templateID = "semantic.identity.exchange",
        fallback = "Nice to meet you.",
    },
    IDENTITY_NAME_EVASION = {
        templateID = "semantic.identity.evasion",
        fallback = "I asked you your name. Don't just change the subject.",
    },
    THREAT_RECEIVED = {
        templateID = "semantic.social.threat",
        fallback = "Back off.",
    },
    ASK_CLARIFICATION = {
        templateID = "semantic.ask_clarification",
        fallback = "I'm not sure what you mean.",
    },
    ACTION_UNAVAILABLE = {
        templateID = "semantic.action.unavailable",
        fallback = "I can't do that yet.",
    },
    CAMP_REQUESTED = {
        templateID = "semantic.camp.requested",
        fallback = "I'll find us a safe place to camp.",
    },
    UNKNOWN = {
        templateID = "semantic.unknown",
        fallback = "I don't understand.",
    },
}
Policy.ResponseTemplates = Policy.ResponseTemplates or {}
local function registerTextFallback(definition)
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.RegisterFallback) == "function"
        and type(definition) == "table"
    then
        text.RegisterFallback(definition.templateID, definition.fallback)
    end
end

for branch, definition in pairs(RESPONSE_TEMPLATES) do
    local stored = Policy.ResponseTemplates[branch]
    if not stored then
        stored = definition
    elseif stored.templateID == definition.templateID
        and (stored.fallback == nil
            or stored.fallback == ""
            or stored.fallback == stored.templateID)
    then
        -- Repair response tables left in memory by an older hot-reloaded
        -- build that accidentally used the template ID as its fallback.
        stored.fallback = definition.fallback
    end
    Policy.ResponseTemplates[branch] = stored
    registerTextFallback(stored)
end

function Policy.RegisterTextFallbacks()
    local count = 0
    for _, definition in pairs(Policy.ResponseTemplates) do
        registerTextFallback(definition)
        count = count + 1
    end
    return count
end

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

local function responseFor(branch, ir)
    local definition = Policy.ResponseTemplates[branch]
        or Policy.ResponseTemplates.UNKNOWN
    return {
        kind = "semantic_template",
        templateID = definition.templateID,
        fallback = definition.fallback,
        args = {
            intent = ir and ir.intent,
            action = ir and ir.action,
            subject = ir and ir.subject,
        },
    }
end

function Policy.RegisterResponse(branch, definition)
    if type(branch) ~= "string" or branch == ""
        or type(definition) ~= "table"
    then
        return false, "invalid_response_template"
    end
    if type(definition.templateID) ~= "string"
        or definition.templateID == ""
    then
        return false, "response_requires_template_id"
    end
    Policy.ResponseTemplates[branch] = {
        templateID = definition.templateID,
        fallback = tostring(definition.fallback or ""),
    }
    registerTextFallback(Policy.ResponseTemplates[branch])
    return true, Policy.ResponseTemplates[branch]
end

local function actionIntent(ir)
    if not ir.action then return nil end
    return {
        kind = "gameplay_request",
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        object = copyValue(ir.object),
        source = copyValue(ir.source),
        destination = copyValue(ir.destination),
        target = copyValue(ir.target),
        modifiers = copyValue(ir.modifiers) or {},
        confidence = ir.confidence,
    }
end

local function decision(ir, route, branch, reason, options)
    local result = {
        schemaVersion = Policy.VERSION,
        kind = "semantic_dialogue_decision",
        route = route,
        branch = branch,
        confidence = tonumber(ir and ir.confidence) or 0,
        intent = ir and ir.intent,
        speechAct = ir and ir.speechAct,
        action = ir and ir.action,
        actionIntent = actionIntent(ir),
        inventoryQuery = copyValue(ir and ir.inventoryQuery),
        giftOffer = copyValue(classifyGiftOffer(ir)),
        response = responseFor(branch, ir),
        diagnostics = {
            reason = reason,
            llmEligible = llmEnabled(nil, options),
        },
    }
    return result
end

local function applyLocalResponse(result, ir, state, context)
    if LocalResponse and type(LocalResponse.Resolve) == "function" then
        local ok, response = pcall(
            LocalResponse.Resolve, ir, state, context, result.branch
        )
        if ok and type(response) == "table" then result.response = response end
    end
    return result
end

local makeIntentBranchResolver = require
    "PNC/Semantics/PNC_SemanticDialoguePolicy_IntentBranch"
local resolveIntentBranch = makeIntentBranchResolver({
    commandActions = COMMAND_ACTIONS,
    isInventoryQuery = isInventoryQuery,
    isIdentityClaim = isIdentityClaim,
    isIdentityEvasion = isIdentityEvasion,
})

function Policy.Decide(ir, state, context, options)
    options = type(options) == "table" and options or {}
    local limits = thresholds(options)
    local hasLLM = llmEnabled(context, options)

    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        local result = decision(
            { confidence = 0 },
            hasLLM and "llm_fallback" or "deterministic",
            hasLLM and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            validationReason or "invalid_ir",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    local diagnostics = ir.diagnostics or {}
    local confidence = tonumber(ir.confidence) or 0
    local giftOffer = classifyGiftOffer(ir)
    if diagnostics.noMatch == true or confidence < limits.medium then
        local result = decision(
            ir,
            hasLLM and "llm_fallback" or "deterministic",
            hasLLM and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            diagnostics.noMatch == true and "no_match" or "low_confidence",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    -- A resolvable reference is required before a semantic action can be
    -- handed to a downstream command adapter. The policy itself never
    -- resolves world entities; it chooses clarification or fallback.
    if (diagnostics.unresolvedEntity == true
            and not unresolvedItemRequest(ir)
            and not unresolvedOffer(ir)
            and not isInventoryQuery(ir)
            and not isLocalFactQuestion(ir)
            and not unresolvedWorldTargetRequest(ir)
            and not isIdentityClaim(ir))
        or (confidence < limits.high and not giftOffer)
    then
        local result = decision(
            ir,
            "deterministic",
            "ASK_CLARIFICATION",
            diagnostics.unresolvedEntity == true
                and "unresolved_reference" or "medium_confidence",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    if fuzzyActionNeedsConfirmation(ir, options) then
        local result = decision(
            ir,
            "deterministic",
            "ASK_CLARIFICATION",
            "fuzzy_action_requires_confirmation",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        result.diagnostics.fuzzyActionRequiresConfirmation = true
        return applyLocalResponse(result, ir, state, context)
    end

    local branch, reason = resolveIntentBranch(ir, state, context, giftOffer)
    local giftConsent = giftConsentFor(ir, context)
    if giftConsent then
        if giftConsent.status == "granted" then
            branch = "GIFT_CONSENT_GRANTED"
            reason = "gift_offer_confirmed"
        elseif giftConsent.status == "declined" then
            branch = "GIFT_CONSENT_DECLINED"
            reason = "gift_offer_declined"
        else
            branch = "GIFT_CONSENT_AMBIGUOUS"
            reason = "gift_offer_recipient_ambiguous"
        end
    end

    local result = decision(ir, "deterministic", branch, reason, options)
    result.giftConsent = giftConsent
    result.diagnostics.llmEligible = hasLLM
    if state then
        result.diagnostics.stateSequence = state.sequence
        result.diagnostics.currentTopic = state.currentTopic
    end
    return applyLocalResponse(result, ir, state, context)
end

function Policy.Process(text, state, context, options)
    local ir = Semantic.Parser.Parse(text, options)
    if state then
        local recorded, recordReason = state:Record(ir, options)
        if not recorded then
            return ir, nil, recordReason
        end
    end
    local result = Policy.Decide(ir, state, context, options)
    if state and type(state.CompletePending) == "function" then
        -- Preserve pending context through decision/response composition, then
        -- retire an obligation answered by this turn.
        state:CompletePending(ir)
    end
    return ir, result
end

return Policy
