PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
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
    TAKE = true,
}

-- Fuzzy recognition is useful for low-risk conversational movement commands,
-- but a typo must not silently turn into an inventory or task side effect.
local FUZZY_SAFE_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
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
    SOCIAL_ACKNOWLEDGED = {
        templateID = "semantic.social.acknowledged",
        fallback = "Understood.",
    },
    GREET_ACKNOWLEDGED = {
        templateID = "semantic.greet.acknowledged",
        fallback = "Hey there.",
    },
    GOSSIP_RECEIVED = {
        templateID = "semantic.gossip.unknown",
        fallback = "I haven't heard anything about that yet.",
    },
    HOSTILE_REMARK_RECEIVED = {
        templateID = "semantic.social.hostile_remark",
        fallback = "Don't talk to me like that.",
    },
    THREAT_RECEIVED = {
        templateID = "semantic.social.threat",
        fallback = "Back off.",
    },
    ASK_CLARIFICATION = {
        templateID = "semantic.ask_clarification",
        fallback = "I'm not sure what you mean.",
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
    if diagnostics.unresolvedEntity == true or confidence < limits.high then
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

    local branch = "SOCIAL_ACKNOWLEDGED"
    local reason = "semantic_acknowledgement"
    if ir.intent == "GREET" or ir.speechAct == "GREET" then
        branch = "GREET_ACKNOWLEDGED"
        reason = "recognized_greeting"
    elseif ir.intent == "REQUEST" then
        if COMMAND_ACTIONS[ir.action] then
            branch = ir.action == "FETCH"
                and "REQUEST_ACKNOWLEDGED" or "COMMAND_ACCEPTED"
            reason = "recognized_request"
        else
            branch = "ASK_CLARIFICATION"
            reason = "request_without_action"
        end
    elseif ir.intent == "QUESTION" then
        branch = "QUESTION_RECEIVED"
        reason = "recognized_question"
    elseif ir.intent == "GOSSIP" then
        branch = "GOSSIP_RECEIVED"
        reason = "recognized_gossip"
    elseif ir.intent == "INSULT"
        or ir.intent == "HOSTILE_REMARK"
        or ir.speechAct == "INSULT"
        or ir.speechAct == "HOSTILE_REMARK"
    then
        branch = "HOSTILE_REMARK_RECEIVED"
        reason = "recognized_hostile_social_act"
    elseif ir.intent == "THREATEN" or ir.speechAct == "THREATEN" then
        branch = "THREAT_RECEIVED"
        reason = "recognized_threat"
    elseif ir.intent == "THANK"
        or ir.intent == "ACCEPT"
        or ir.intent == "REFUSE"
        or ir.intent == "APOLOGIZE"
    then
        branch = "SOCIAL_ACKNOWLEDGED"
        reason = "recognized_social_act"
    end

    local result = decision(ir, "deterministic", branch, reason, options)
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
