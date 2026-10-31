if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Applies an admitted LLM social reaction to authoritative relationship state.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local Relationships = H.Relationships or PNC.Relationships
local Tools = H.Tools
local Policy = H.Policy

function H.ApplyRelationshipEffect(context)
    context = type(context) == "table" and context or {}
    local reaction = context.reaction
    local intensity = context.intensity
    local subtype = context.subtype
    local npcID = context.npcID
    local targetKey = context.targetKey
    local requestID = context.requestID
    local callID = context.callID
    local at = context.occurredAt
    local effect, reason = Tools.GetEffect(reaction, intensity, subtype)
    if not effect then return false, reason end

    local cooldownType, cooldownUntil = Policy.CooldownMutation(reaction, at)
    local applied, applyReason, details =
        Relationships.ApplyConversationEffect(
            npcID,
            targetKey,
            effect,
            {
                blockID = "llm_social_reaction",
                choiceID = requestID,
                outcomeID = callID .. ":" .. reaction,
                interactionType = effect.interactionType
                    or effect.memoryType or effect.type,
                worldAgeHours = at,
                cooldownType = cooldownType,
                cooldownUntil = cooldownUntil,
                sourceSystem = "llm_social_reaction",
                interaction = {
                    kind = "llm_social_reaction",
                    source = "llm_tool",
                    interactionType = effect.interactionType
                        or effect.memoryType or effect.type,
                    reaction = reaction,
                    intensity = intensity,
                    subtype = subtype,
                    applied = true,
                },
            }
        )
    return applied, applyReason, details, cooldownType, cooldownUntil
end

return Authority
