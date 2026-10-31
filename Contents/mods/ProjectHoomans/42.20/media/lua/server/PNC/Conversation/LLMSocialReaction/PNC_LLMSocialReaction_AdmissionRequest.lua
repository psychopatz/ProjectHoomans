if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Normalizes and validates the request envelope for an LLM social reaction.
-- Registry lookup stays here so the authority coordinator receives a record.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local Registry = H.Registry
local Tools = H.Tools
local MAX_ID_LENGTH = H.MAX_ID_LENGTH
local text = H.text
local socialSubtype = H.socialSubtype
local rejected = H.rejected

function H.NormalizeReactionRequest(player, args)
    args = type(args) == "table" and args or {}
    local requestID = string.sub(text(args.requestID), 1, MAX_ID_LENGTH)
    local callID = string.sub(text(args.callID), 1, MAX_ID_LENGTH)
    local npcID = string.sub(text(args.npcID), 1, MAX_ID_LENGTH)
    local token = text(args.token)
    local reaction = Tools and Tools.NormalizeReaction
        and Tools.NormalizeReaction(args.kind or args.reaction) or nil
    local intensity = Tools and Tools.NormalizeIntensity
        and Tools.NormalizeIntensity(args.intensity) or "normal"
    local subtype = socialSubtype(reaction, args.subtype)

    if requestID == "" then
        return nil, rejected(player, args, "request_id_required")
    end
    if callID == "" then
        return nil, rejected(player, args, "call_id_required")
    end
    if npcID == "" then
        return nil, rejected(player, args, "npc_id_required")
    end
    if not reaction then
        return nil, rejected(player, args, "unknown_reaction")
    end

    local record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then
        return nil, rejected(player, args, "npc_not_found")
    end

    return {
        args = args,
        requestID = requestID,
        callID = callID,
        npcID = npcID,
        token = token,
        reaction = reaction,
        intensity = intensity,
        subtype = subtype,
        record = record,
    }, nil
end

return Authority
