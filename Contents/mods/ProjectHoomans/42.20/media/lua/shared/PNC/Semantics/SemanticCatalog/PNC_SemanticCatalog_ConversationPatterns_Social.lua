-- Social conversation-pattern registration hub.
--
-- Keep the public registration path stable; spokes own social families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_News"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_Continuation"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns_Social_SpeechActs"

function Internal.RegisterSocialSignals()
    Internal.RegisterRecruitmentRequestPatterns()
    Internal.RegisterWhatsUpConceptPattern()
    Internal.RegisterNewsSignals()
    Internal.RegisterContinuationSignals()
    Internal.RegisterSocialSpeechActs()
end

return Internal
