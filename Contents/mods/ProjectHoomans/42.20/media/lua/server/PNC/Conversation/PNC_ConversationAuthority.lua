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
require "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Choice"

return PNC.Conversation.Authority
