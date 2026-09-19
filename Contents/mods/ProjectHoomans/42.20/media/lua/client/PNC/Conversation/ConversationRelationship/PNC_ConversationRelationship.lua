-- Build 42.20 relationship resolver for conversations.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Relationship = PNC.Conversation.Relationship or {}
PNC.Conversation.Relationship = Relationship
local presentationCache = Relationship.presentationCache or {}
Relationship.presentationCache = presentationCache

-- Kept on during development. Gameplay can disable this before opening a
-- conversation, then reveal it in a dialogue branch such as "What do you
-- think of me?" without changing the relationship data flow.
Relationship.presentationVisible = Relationship.presentationVisible ~= false

require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Resolution"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Previews"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Snapshot"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Receipt"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_PanelControls"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_DebugActions"

return Relationship
