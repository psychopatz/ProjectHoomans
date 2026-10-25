-- Ordered entry point for authored question response pools.
--
-- Registration order is preserved while each semantic response family owns its
-- data in a focused provider module.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions_IdentityActivity"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions_WellbeingMedical"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions_Needs"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions_FollowUps"

return true
