-- Camp activity composition root.
-- Acquisition loads before target re-resolution and lifecycle cleanup.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}
local Service = PNC.CampResourceService
Service.Internal = Service.Internal or {}

require "PNC/World/CampResourceService/PNC_CampResourceService_Activity_Core"
require "PNC/World/CampResourceService/PNC_CampResourceService_Activity_Resolve"
require "PNC/World/CampResourceService/PNC_CampResourceService_Activity_Lifecycle"

return Service
