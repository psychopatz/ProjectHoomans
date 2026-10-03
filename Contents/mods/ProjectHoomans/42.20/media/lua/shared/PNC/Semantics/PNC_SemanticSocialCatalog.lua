-- Data-only social language definitions for the semantic layer.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Social = PNC.Semantics.SocialCatalog or {}
PNC.Semantics.SocialCatalog = Social

require "PNC/Semantics/PNC_SemanticSocialCatalog_Definitions"
require "PNC/Semantics/PNC_SemanticSocialCatalog_Register"

return Social
