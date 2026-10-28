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
local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"

local function flowResponseEligible(result, context)
    local flow = result and result.flow or nil
    if type(flow) ~= "table" or flow.matched ~= true
        or type(flow.responsePool) ~= "string"
        or flow.responsePool == ""
        or result.action ~= nil
    then
        return false
    end
    -- Identity claims and other authoritative turns must keep their existing
    -- server-result response path. A verified identity also keeps the
    -- known-name presentation instead of reopening the strangers' pool.
    if result.branch == "IDENTITY_CLAIM_RECEIVED"
        or result.branch == "GIFT_OFFER_DISPATCHED"
        or result.branch == "GIFT_SELECTION_REQUIRED"
        or result.branch == "GIFT_CONSENT_GRANTED"
    then
        return false
    end
    return not (type(context) == "table"
        and context.identityState == "known"
        and context.identityClaimVerified == true)
end

local function applyFlowResponse(result, ir, state, context)
    if not flowResponseEligible(result, context)
        or not LocalResponse
        or type(LocalResponse.ResolveFlow) ~= "function"
    then
        return false
    end
    local response, reason = LocalResponse.ResolveFlow(
        ir, state, context, result.flow
    )
    if type(response) ~= "table" then
        result.diagnostics.flowResponse = {
            selected = false,
            poolID = result.flow.responsePool,
            reason = reason or "flow_response_unavailable",
        }
        return false
    end
    result.response = response
    result.diagnostics.flowResponse = {
        selected = true,
        poolID = result.flow.responsePool,
        templateID = response.templateID,
        flowID = result.flow.flowId,
        transition = result.flow.transition,
    }
    return true
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
    local flowOwned = flowResponseEligible(result, context)
    local flowSelected = flowOwned
        and applyFlowResponse(result, ir, state, context) or false
    if not flowSelected and LocalResponse
        and type(LocalResponse.Resolve) == "function"
    then
        local ok, response = pcall(
            LocalResponse.Resolve, ir, state, context, result.branch
        )
        if ok and type(response) == "table" then result.response = response end
    end
    if ResponsePlan and type(ResponsePlan.Attach) == "function"
        and type(result.response) == "table"
    then
        local interactionPlan = type(result.interactionPlan) == "table"
            and result.interactionPlan or nil
        local dialogueAct = result.branch
        if not flowSelected
            and result.action == nil
            and interactionPlan
            and type(interactionPlan.dialogueAct) == "string"
        then
            dialogueAct = interactionPlan.dialogueAct
            if type(interactionPlan.contentTemplateID) == "string"
                and interactionPlan.contentTemplateID ~= ""
            then
                result.response.templateID =
                    interactionPlan.contentTemplateID
            end
            result.diagnostics.interactionPlan = {
                applied = true,
                behaviorID = interactionPlan.behaviorID,
                beatID = interactionPlan.beatID,
                dialogueAct = interactionPlan.dialogueAct,
                contentTemplateID = interactionPlan.contentTemplateID,
            }
        elseif interactionPlan then
            result.diagnostics.interactionPlan = {
                applied = false,
                behaviorID = interactionPlan.behaviorID,
                beatID = interactionPlan.beatID,
                reason = flowSelected
                    and "flow_response_authority"
                    or "authoritative_action_response",
            }
        end
        ResponsePlan.Attach(
            result.response,
            dialogueAct,
            flowSelected and result.flow and result.flow.responsePool or nil
        )
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
