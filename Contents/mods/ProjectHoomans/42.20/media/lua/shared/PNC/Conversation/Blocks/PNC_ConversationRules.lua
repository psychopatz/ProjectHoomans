-- Stable entry point for conversation gate and effect rules.

require "PNC/Conversation/Blocks/PNC_ConversationRegistry"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Rules = PNC.Conversation.Rules or {}
PNC.Conversation.Rules.Internal =
    PNC.Conversation.Rules.Internal or {}

require "PNC/Conversation/Blocks/PNC_ConversationRules/PNC_ConversationRules_Conditions"
require "PNC/Conversation/Blocks/PNC_ConversationRules/PNC_ConversationRules_RelationshipEffects"
require "PNC/Conversation/Blocks/PNC_ConversationRules/PNC_ConversationRules_WorldEffects"
require "PNC/Conversation/Blocks/PNC_ConversationRules/PNC_ConversationRules_Evaluation"
require "PNC/Conversation/Blocks/PNC_ConversationRules/PNC_ConversationRules_Effects"

return PNC.Conversation.Rules
