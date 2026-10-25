-- Build response-specific presentation receipts and rejection payloads.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Payloads"
local ResponseAdapter = Internal.ResponseAdapter or {}
Internal.ResponseAdapter = ResponseAdapter

function ResponseAdapter.IdentityExchangeUnavailable()
    return ResponseAdapter.Payload({
        response = {
            templateID = "semantic.identity.exchange.unavailable",
            fallback = "I couldn't verify your name just now. Could you tell me again?",
        },
    })
end

function ResponseAdapter.IdentityQuestion(context, state)
    local localResponse = PNC.Semantics
        and PNC.Semantics.LocalResponse or nil
    local response
    if localResponse and type(localResponse.Resolve) == "function" then
        response = localResponse.Resolve(
            { intent = "QUESTION", subject = "IDENTITY" },
            state,
            type(context) == "table" and context or {},
            "QUESTION_RECEIVED"
        )
    end
    if type(response) ~= "table" then
        response = {
            templateID = "semantic.question.identity",
            fallback = "I'll tell you my name once we've established some trust. What's your name?",
        }
    end
    return ResponseAdapter.Payload({ response = response }, context)
end

function ResponseAdapter.CampAcknowledgement(result, actionResult)
    local decision = result and result.decision or {}
    local action = string.upper(tostring(decision.action
        or actionResult and actionResult.action or ""))
    if action ~= "CAMP" or not actionResult
        or actionResult.accepted ~= true
        or type(Internal.CampResponseFor) ~= "function"
    then
        return nil
    end
    local phase = (actionResult.status == "pending"
        or actionResult.reason == "network_queued")
        and "pending" or "admitted"
    local text = Internal.CampResponseFor(
        actionResult,
        decision,
        phase
    )
    if not text then return nil end
    return {
        key = "semantic.camp.requested",
        domain = "pnc.system.shared.categories",
        text = text,
        fallback = text,
    }
end

function ResponseAdapter.ActionRejected(result, actionResult)
    if type(actionResult) ~= "table"
        or actionResult.accepted ~= false
        or actionResult.status == "unmapped"
        or actionResult.status == "skipped"
    then
        return nil
    end
    local action = string.upper(tostring(
        result and result.ir and result.ir.action
        or actionResult.action or ""
    ))
    local speechAct = string.upper(tostring(
        result and result.ir
        and (result.ir.speechAct or result.ir.intent) or ""
    ))
    local socialAct = speechAct == "INSULT"
        or speechAct == "HOSTILE_REMARK"
        or speechAct == "THREATEN"
    if socialAct then
        local reason = tostring(actionResult.reason or "")
        local unavailable = string.find(reason, "unavailable", 1, true)
            or string.find(reason, "transport", 1, true)
            or actionResult.status == "semantic_social_dispatch_unavailable"
        local templateID = unavailable
            and "semantic.social.interaction.unavailable"
            or "semantic.social.interaction.rejected"
        local fallback = unavailable
            and "I heard you, but I couldn't send that social reaction right now."
            or "I heard you, but I couldn't apply that social reaction."
        return ResponseAdapter.Payload({
            response = {
                templateID = templateID,
                fallback = fallback,
                args = {
                    reason = reason,
                    speechAct = speechAct,
                },
            },
        })
    end
    local binding = actionResult.binding
    local bindingPools = type(binding) == "table"
        and binding.responsePools or nil
    local bindingFailed = actionResult.status == "failed"
        or type(actionResult.details) == "table"
        and actionResult.details.status == "failed"
    local bindingOutcome = bindingFailed and "failed" or "rejected"
    local bindingResponse = type(bindingPools) == "table"
        and bindingPools[bindingOutcome] or nil
    if type(bindingResponse) == "table"
        and type(bindingResponse.key) == "string"
        and bindingResponse.key ~= ""
    then
        return ResponseAdapter.Payload({
            response = {
                templateID = bindingResponse.key,
                fallback = bindingResponse.en or bindingResponse.fallback,
                args = {
                    action = action,
                    reason = actionResult.reason,
                },
            },
        })
    end
    -- Task admission failures already flow through ReceiveSemanticTaskResult,
    -- which owns their single authoritative task-result line. Avoid adding a
    -- second generic action-unavailable line for WAIT_AT.
    if action == "WAIT_AT" then return nil end
    local fallback = "I couldn't do that right now."
    if action == "FOLLOW" or tostring(actionResult.commandID) == "follow" then
        fallback = "I can't follow you right now."
    elseif action == "STAY" then
        fallback = "I can't stay right now."
    elseif action == "STOP"
        or tostring(actionResult.commandID) == "stay"
    then
        fallback = "I can't stop right now."
    end
    local templateID = "semantic.action.unavailable"
    if action == "FOLLOW" or tostring(actionResult.commandID) == "follow" then
        templateID = "semantic.action.follow.unavailable"
    elseif action == "STAY" then
        templateID = "semantic.action.stay.unavailable"
    elseif action == "STOP"
        or tostring(actionResult.commandID) == "stay"
    then
        templateID = "semantic.action.stop.unavailable"
    end
    return ResponseAdapter.Payload({
        response = {
            templateID = templateID,
            fallback = fallback,
            args = {
                action = action,
                reason = actionResult.reason,
            },
        },
    })
end

return ResponseAdapter
