-- Server-authoritative recruitment composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit_Handle_Context"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit_Handle_Effects"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit_Handle_Response"
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit_Handle"

return PNC.Conversation.Authority
