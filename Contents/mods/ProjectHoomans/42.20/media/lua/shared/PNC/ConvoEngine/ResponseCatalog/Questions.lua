-- Ordered entry point for authored question response pools.
--
-- Registration order is preserved while each semantic response family owns its
-- data in a focused provider module.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

require "PNC/ConvoEngine/ResponseCatalog/Questions_Knowledge_Core"
require "PNC/ConvoEngine/ResponseCatalog/Questions_IdentityActivity"
require "PNC/ConvoEngine/ResponseCatalog/Questions_WellbeingMedical"
require "PNC/ConvoEngine/ResponseCatalog/Questions_Needs"
require "PNC/ConvoEngine/ResponseCatalog/Questions_FollowUps"
require "PNC/ConvoEngine/ResponseCatalog/Questions_Whereabouts"

return true
