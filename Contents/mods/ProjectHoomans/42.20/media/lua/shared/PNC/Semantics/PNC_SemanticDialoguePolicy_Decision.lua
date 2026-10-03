-- Semantic dialogue policy response and decision helpers.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Policy = PNC.Semantics.DialoguePolicy
local Internal = Policy.Internal or {}
Policy.Internal = Internal
local LocalResponse = Internal.LocalResponse
local copyValue = Internal.CopyValue
local llmEnabled = Internal.LLMEnabled
local classifyGiftOffer = Internal.ClassifyGiftOffer
local registerTextFallback = Internal.RegisterTextFallback
local COMMAND_ACTIONS = Internal.CommandActions
local isInventoryQuery = Internal.IsInventoryQuery
local isIdentityClaim = Internal.IsIdentityClaim
local isIdentityEvasion = Internal.IsIdentityEvasion

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


Internal.ResponseFor = responseFor
Internal.ActionIntent = actionIntent
Internal.Decision = decision
Internal.ApplyLocalResponse = applyLocalResponse
Internal.ResolveIntentBranch = resolveIntentBranch

return Policy
