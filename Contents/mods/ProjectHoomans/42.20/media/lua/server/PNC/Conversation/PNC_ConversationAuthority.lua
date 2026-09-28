-- Stable server-authoritative conversation entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Conversation/PNC_ConversationHistory"
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Context"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_BuildContext"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Validation"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Category"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_SettlementAdmission"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_AmbientVisit"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Departure"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Choice"

-- Public integration seam for authoritative effects that are triggered by an
-- active conversation but target a related record (for example, a guard
-- referring the player to a caravan merchant). Existing conversation routes
-- continue to use Internal.ValidateLease directly; integrations should use
-- this wrapper so they do not depend on the private table layout.
function PNC.Conversation.Authority.ValidateLease(player, record, token)
    local internal = PNC.Conversation.Authority.Internal
    if not internal or type(internal.ValidateLease) ~= "function" then
        return false, "conversation_authority_unavailable"
    end
    return internal.ValidateLease(player, record, token)
end

return PNC.Conversation.Authority
