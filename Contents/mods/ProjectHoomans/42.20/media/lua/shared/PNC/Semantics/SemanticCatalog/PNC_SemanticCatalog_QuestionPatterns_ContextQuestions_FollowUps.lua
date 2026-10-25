-- Context-question follow-up registration hub.
--
-- Keep the public aggregator stable; spokes own follow-up families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog context-question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog context-question module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_Needs"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_GiftPreference"

function Internal.RegisterWorldFactQuestions_FollowUps()
    Internal.RegisterContextReferenceFollowUps()
    Internal.RegisterNeedsFollowUps()
    Internal.RegisterGiftPreferenceFollowUps()
end

return Internal
