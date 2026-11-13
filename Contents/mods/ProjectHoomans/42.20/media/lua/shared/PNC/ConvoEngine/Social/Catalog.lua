-- Data-only social language definitions for the semantic layer.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Social = PNC.ConvoEngine.SocialCatalog or {}
PNC.ConvoEngine.SocialCatalog = Social

require "PNC/ConvoEngine/Social/Catalog_Definitions"
require "PNC/ConvoEngine/Social/Catalog_Register"

return Social
