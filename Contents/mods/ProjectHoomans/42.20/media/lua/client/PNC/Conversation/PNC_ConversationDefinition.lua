-- Build 42.20 compatibility entry for conversation definitions.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

if not PNC.NPCIdentityPresentation then
    require "PNC/Knowledge/PNC_NPCIdentityPresentation"
end
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Conversation/Blocks/PNC_ConversationIdentityChoice"
if not PNC.Conversation.Audience then
    require "PNC/Conversation/PNC_ConversationAudience"
end

require "PNC/Conversation/Definition/PNC_ConversationDefinition_Context"
require "PNC/Conversation/Definition/PNC_ConversationDefinition_Builder"
require "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle"

return PNC.Conversation
