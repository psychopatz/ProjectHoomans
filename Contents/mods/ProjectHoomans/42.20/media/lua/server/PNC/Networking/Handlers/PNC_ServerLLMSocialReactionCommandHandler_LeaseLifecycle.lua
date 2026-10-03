if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Owns cached replay and lease consumption for LLM social reactions.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local log = H.log
local sendResult = H.sendResult

function H.ReplayCachedReaction(context)
    context = type(context) == "table" and context or {}
    local lease = context.lease
    local requestID = context.requestID
    local callID = context.callID
    local idempotencyKey = requestID .. ":" .. callID
    lease.llmToolCalls = lease.llmToolCalls or {}
    local result = lease.llmToolCalls[idempotencyKey]
    if not result then return nil, idempotencyKey end
    log(
        "social_react_duplicate",
        "npc=" .. tostring(context.npcID)
            .. " request=" .. tostring(requestID)
            .. " call=" .. tostring(callID)
    )
    sendResult(context.player, result)
    return result, idempotencyKey
end

function H.RecordAppliedReaction(lease, idempotencyKey, result,
    pendingRequest)
    lease.llmToolCalls[idempotencyKey] = result
    if pendingRequest then
        lease.consumed = true
        lease.consumedAt = getTimeInMillis and getTimeInMillis() or nil
    end
end

return Authority
