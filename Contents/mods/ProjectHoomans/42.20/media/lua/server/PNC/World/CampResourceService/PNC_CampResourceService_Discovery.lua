-- Bounded world discovery composition root.
-- Load helpers and providers before capture state, then publish the public API.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
Service.Internal = Service.Internal or {}

require "PNC/World/CampResourceService/PNC_CampResourceService_Discovery_Core"
require "PNC/World/CampResourceService/PNC_CampResourceService_Discovery_Providers"
require "PNC/World/CampResourceService/PNC_CampResourceService_Discovery_Capture"
require "PNC/World/CampResourceService/PNC_CampResourceService_Discovery_Api"

return Service
