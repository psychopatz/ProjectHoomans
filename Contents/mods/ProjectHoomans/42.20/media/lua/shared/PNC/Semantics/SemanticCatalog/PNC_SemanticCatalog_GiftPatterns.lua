-- Gift-offer pattern registration hub.
--
-- Keep the public registration path stable; spokes own offer families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Context"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Direct"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Explicit"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Requests"

function Internal.RegisterGiftOffers()
    Internal.RegisterContextGiftOffers()
    Internal.RegisterDirectGiftOffers()
    Internal.RegisterExplicitGiftOffers()
    Internal.RegisterGiftRequests()
end

return Internal
