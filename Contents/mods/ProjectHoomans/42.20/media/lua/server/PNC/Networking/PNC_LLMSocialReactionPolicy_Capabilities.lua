-- Safe, server-computed capability hints for the LLM conversation context.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
local Policy = PNC.Conversation.LLMSocialReactionPolicy
local Tools = PNC.ConversationLLMTools

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function positiveCooldown(relationship, at)
    local cooldownUntil = relationship
        and relationship.cooldowns
        and tonumber(relationship.cooldowns[Policy.POSITIVE_COOLDOWN_TYPE])
        or nil
    if cooldownUntil ~= nil
        and (cooldownUntil ~= cooldownUntil
            or cooldownUntil == math.huge
            or cooldownUntil == -math.huge)
    then
        cooldownUntil = nil
    end
    if cooldownUntil and at < cooldownUntil then
        return false, cooldownUntil - at, cooldownUntil
    end
    return true, 0, cooldownUntil
end

function Policy.BuildCapabilities(record, player, relationship, at)
    local output = {
        version = Policy.VERSION,
        server_authoritative = true,
        positive_action_cooldown_hours =
            Policy.POSITIVE_COOLDOWN_HOURS,
        available_reactions = {},
        flirt_available = false,
        flirt_available_when_ready = false,
    }
    local cooldownAvailable
    local remaining
    local cooldownUntil
    local reaction
    local allowed
    local reason
    local all = Tools and Tools.ListAll and Tools.ListAll() or {}
    local flirtReady
    local flirtReadyReason
    at = math.max(0, finite(at, 0))
    cooldownAvailable, remaining, cooldownUntil = positiveCooldown(
        relationship,
        at
    )
    output.positive_action_cooldown_active = not cooldownAvailable
    output.positive_action_cooldown_remaining_hours = remaining
    output.positive_action_cooldown_until = cooldownUntil
    flirtReady, flirtReadyReason = Policy.Evaluate(
        "flirt", record, player, relationship, at
    )
    output.flirt_available_when_ready = flirtReady == true
    output.flirt_gate_reason = flirtReadyReason
    for _, reaction in ipairs(all) do
        allowed = reaction == "insult"
        if not allowed and cooldownAvailable then
            allowed, reason = Policy.Evaluate(
                reaction, record, player, relationship, at
            )
        elseif not allowed then
            reason = "positive_cooldown_active"
        end
        if allowed then
            output.available_reactions[#output.available_reactions + 1] =
                reaction
        end
        if reaction == "flirt" then
            output.flirt_available = allowed == true
            output.flirt_reason = reason
        end
    end
    return output
end

return Policy
