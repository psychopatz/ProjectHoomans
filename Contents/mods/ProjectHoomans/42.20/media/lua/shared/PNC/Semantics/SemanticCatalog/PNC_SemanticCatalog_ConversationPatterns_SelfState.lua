-- First-person wellbeing and need-state registration hub.
--
-- Keep this public path stable; spokes own needs, wellbeing, and reciprocal questions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog self-state module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog self-state module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_SelfState_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_SelfState_Needs"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_SelfState_Wellbeing"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_SelfState_Reciprocal"

function Internal.RegisterSelfStatePatterns()
    Internal.RegisterSelfNeedPatterns()
    Internal.RegisterSelfWellbeingPatterns()
    Internal.RegisterSelfReciprocalPatterns()
end

return Internal
