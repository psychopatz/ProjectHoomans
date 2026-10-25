-- News and gossip conversation-pattern registration hub.
--
-- Keep this public path stable; spokes own event and news families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_News_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_News_Event"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_News_Generic"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_News_Targeted"

function Internal.RegisterNewsSignals()
    Internal.RegisterGossipEventSignal()
    Internal.RegisterGenericNewsSignals()
    Internal.RegisterTargetedNewsSignals()
end

return Internal
