-- Conversation-level state claims and non-item social utterances.
--
-- This public path remains the catalog conversation-pattern entry point while
-- loading each registration family in its original dependency order.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end
if type(Internal.RegisterPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_SelfState"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social"

return Internal
