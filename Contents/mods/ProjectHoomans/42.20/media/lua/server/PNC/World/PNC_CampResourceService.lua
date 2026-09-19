-- Compatibility entry point for the camp resource service.
-- Keep this stable path because the server composition root and external
-- integrations load it directly. The implementation lives in the ordered
-- CampResourceService spokes below.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

require "PNC/World/CampResourceService/PNC_CampResourceService"

return PNC.CampResourceService
