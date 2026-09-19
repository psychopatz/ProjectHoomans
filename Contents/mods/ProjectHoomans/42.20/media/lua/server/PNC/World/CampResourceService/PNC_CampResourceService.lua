-- Camp resource service composition root.
-- Providers load before selectors; lifecycle wiring loads last so every public
-- operation sees the complete internal contract.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
Service.Internal = Service.Internal or {}

require "PNC/World/CampResourceService/PNC_CampResourceService_Context"
require "PNC/World/CampResourceService/PNC_CampResourceService_Discovery"
require "PNC/World/CampResourceService/PNC_CampResourceService_Targets"
require "PNC/World/CampResourceService/PNC_CampResourceService_Activity"

return Service
