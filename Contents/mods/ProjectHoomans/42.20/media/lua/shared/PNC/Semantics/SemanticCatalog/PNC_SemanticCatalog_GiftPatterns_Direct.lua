-- Direct gift-offer registration hub.
--
-- Keep this public path stable; spokes own shared offer construction,
-- possession offers, and here-is offers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog gift module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog gift module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Direct_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Direct_Have"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns_Direct_Here"

function Internal.RegisterDirectGiftOffers()
    Internal.RegisterDirectGiftHaveOffer()
    Internal.RegisterDirectGiftHereOffers()
end

return Internal
