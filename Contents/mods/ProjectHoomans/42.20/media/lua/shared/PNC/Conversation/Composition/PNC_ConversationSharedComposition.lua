-- Deterministic shared Conversation composition root.
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry"
require "PNC/Conversation/Blocks/PNC_ConversationRules"
require "PNC/Conversation/Blocks/PNC_ConversationSelector"
require "PNC/Conversation/PNC_ConversationScene"
require "PNC/Conversation/PNC_ConversationLLMTools"
require "PNC/Conversation/Memory/PNC_ConversationMemory"
require "PNC/Conversation/Composition/PNC_ConversationAdopterDefinitions"

return PNC and PNC.Conversation
