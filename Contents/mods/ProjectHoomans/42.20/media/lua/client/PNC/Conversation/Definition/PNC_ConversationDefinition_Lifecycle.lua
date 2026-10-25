-- Stable conversation-definition lifecycle entry point.
-- Keep this module path and Conversation API compatible with callers.
pcall(require, "PNC/Conversation/PNC_ConversationRuntimeDebugOverlay")

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
local Conversation = PNC.Conversation
Conversation.DefinitionLifecycleInternal =
    Conversation.DefinitionLifecycleInternal or {}

require "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle_Open"
require "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle_Refresh"
require "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle_Disclosure"

return Conversation
