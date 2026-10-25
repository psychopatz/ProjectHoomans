-- Basic fetch and give request registration hub.
--
-- Keep this public path stable; spokes own request families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog pattern module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns_Basic_Fetch"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns_Basic_Give"

function Internal.RegisterBasicRequests()
    Internal.RegisterFetchRequests()
    Internal.RegisterGiveRequests()
end

return Internal
