PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Composer = Conversation.Composer or {}
Conversation.Composer = Composer
Composer.Internal = Composer.Internal or {}
local Internal = Composer.Internal

local TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
if type(TopicCatalog) ~= "table" then
    pcall(require, "PNC/Semantics/PNC_SemanticTopicCatalog")
    TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
end
Internal.TopicCatalog = TopicCatalog

-- Keep this path as the public composer entry point.  The spokes below are
-- ordered because semantic projections depend on BuildBlockNode, while the
-- graph projection depends on both the block and semantic projections.
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Blocks_Core"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Blocks_Semantic"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Blocks_Graph"

return Composer
