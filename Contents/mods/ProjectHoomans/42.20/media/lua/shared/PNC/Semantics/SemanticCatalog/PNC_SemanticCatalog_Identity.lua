-- Identity claim registration hub.
--
-- Keep this public path stable; spokes own shared grammar construction,
-- direct name claims, and alias-style introductions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog or {}
local Internal = Catalog.Internal or {}
Catalog.Internal = Internal

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Identity_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Identity_Direct"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Identity_Aliases"

function Internal.RegisterIdentityPatterns()
    Internal.RegisterIdentityDirectPatterns()
    Internal.RegisterIdentityAliasPatterns()
end

return Internal
