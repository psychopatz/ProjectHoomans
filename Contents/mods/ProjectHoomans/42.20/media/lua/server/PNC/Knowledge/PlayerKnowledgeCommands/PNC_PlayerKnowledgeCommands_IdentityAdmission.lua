-- Server-only request normalization and conversation-lease admission.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}

local Admission = {}
local Commands = PNC.PlayerKnowledgeCommands or {}
local H = Commands.Internal or {}
local Identity = require "PNC/Semantics/PNC_SemanticIdentityExchange"
local IdentityPresentation = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityPresentation"

function Admission.Resolve(player, args)
    args = type(args) == "table" and args or {}
    local requestID = H.SafeID(args.requestID)
    local npcID = H.SafeID(args.npcID)
    local kind = tostring(args.kind or "")
    local claimedName = IdentityPresentation.Clean(args.claimedName)
    if not requestID or not npcID then
        return nil, "identity_request_invalid"
    end
    if kind ~= Identity.EVENT_CLAIM and kind ~= Identity.EVENT_EVASION then
        return nil, "identity_event_invalid"
    end
    if kind == Identity.EVENT_CLAIM and claimedName == "" then
        return nil, "identity_claim_missing"
    end

    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end

    local authority = PNC.Conversation
        and PNC.Conversation.Authority
    local validator = authority and authority.Internal
        and authority.Internal.ValidateLease
    if type(validator) ~= "function" then
        return nil, "conversation_authority_unavailable"
    end
    local valid, reason, lease = validator(
        player, record, args.conversationToken or args.token
    )
    if valid ~= true then return nil, reason end

    local context
    context, reason = H.ContextFor(player, "semantic_identity")
    if not context then return nil, reason end
    local targetKey = context.playerEntityKey
    if not targetKey then
        return nil, "player_identity_unavailable"
    end

    return {
        args = args,
        requestID = requestID,
        npcID = npcID,
        kind = kind,
        claimedName = claimedName,
        record = record,
        context = context,
        targetKey = targetKey,
        lease = lease,
    }
end

return Admission
