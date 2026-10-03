-- Authoritative semantic camp site resolver composition root.
-- Shared normalization loads before hint validation and broad resolution.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Resolver = PNC.Semantics.CampSiteResolver or {}
PNC.Semantics.CampSiteResolver = Resolver
Resolver.Internal = Resolver.Internal or {}

require "PNC/Semantics/CampSiteResolver/PNC_SemanticCampSiteResolver_Core"
require "PNC/Semantics/CampSiteResolver/PNC_SemanticCampSiteResolver_Validation"
require "PNC/Semantics/CampSiteResolver/PNC_SemanticCampSiteResolver_Resolve"

return Resolver
