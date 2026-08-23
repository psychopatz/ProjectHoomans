-- Build 42.20 conversation category/block registry.
-- Stable entry point; registry roles load from the matching subfolder.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Registry = PNC.Conversation.Registry or {}
PNC.Conversation.Registry.Internal =
    PNC.Conversation.Registry.Internal or {}

require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Utilities"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_NodeValidation"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Validation"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Mutations"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Queries"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Handlers"
require "PNC/Conversation/Blocks/PNC_ConversationRegistry/PNC_ConversationRegistry_Fingerprint"

return PNC.Conversation.Registry
