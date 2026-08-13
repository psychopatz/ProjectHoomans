-- Deterministic server Conversation domain entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Conversation/PNC_ConversationHistory"
require "PNC/Conversation/PNC_ConversationAuthority"

return PNC and PNC.Conversation
