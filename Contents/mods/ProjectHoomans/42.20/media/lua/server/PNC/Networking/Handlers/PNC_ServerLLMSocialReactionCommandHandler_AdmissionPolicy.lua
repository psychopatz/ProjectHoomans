if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Owns relationship snapshot and policy availability checks for LLM admission.
-- It never applies a relationship effect or mutates authoritative state.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local Tools = H.Tools
local Policy = H.Policy
local log = H.log
local worldAgeHours = H.worldAgeHours
local relationshipFor = H.relationshipFor
local snapshotOf = H.snapshotOf
local rejected = H.rejected

function H.EvaluateReactionAdmission(context)
    context = type(context) == "table" and context or {}
    local player = context.player
    local args = context.args
    local npcID = context.npcID
    local requestID = context.requestID
    local callID = context.callID
    local reaction = context.reaction
    local intensity = context.intensity
    local subtype = context.subtype
    local record = context.record
    local targetKey = context.targetKey
    local beforeRelationship = relationshipFor(npcID, targetKey)
    local beforeExists = beforeRelationship ~= nil
    local before = snapshotOf(beforeRelationship)
    log(
        "social_react_received",
        "npc=" .. npcID .. " request=" .. requestID
            .. " call=" .. callID .. " reaction=" .. tostring(reaction)
            .. " intensity=" .. tostring(intensity)
            .. " subtype=" .. tostring(subtype or "")
            .. " target=" .. tostring(targetKey)
            .. " before_approval=" .. tostring(before.approval or 0)
            .. " before_respect=" .. tostring(before.respect or 0)
    )
    if not Tools or not Tools.GetEffect or not Policy
        or not Policy.Evaluate
    then
        return nil, nil, nil, rejected(
            player,
            args,
            "social_reaction_policy_unavailable"
        )
    end

    local at = worldAgeHours()
    local available
    local availabilityReason
    local availabilityDetails
    available, availabilityReason, availabilityDetails =
        Policy.Evaluate(reaction, record, player, beforeRelationship, at)
    if not available then
        local capabilities = Policy.BuildCapabilities
            and Policy.BuildCapabilities(
                record,
                player,
                beforeRelationship,
                at
            ) or nil
        if type(availabilityDetails) ~= "table" then
            availabilityDetails = {}
        end
        availabilityDetails.capabilities = capabilities
        return nil, nil, nil, rejected(
            player,
            args,
            availabilityReason,
            availabilityDetails
        )
    end

    return before, beforeExists, at, nil
end

return Authority
