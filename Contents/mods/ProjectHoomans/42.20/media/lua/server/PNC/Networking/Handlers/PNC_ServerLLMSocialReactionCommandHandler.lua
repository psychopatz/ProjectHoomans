if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
-- Permanent public require compatibility; one Conversation-owned implementation.
return require "PNC/Conversation/PNC_LLMSocialReactionService"
