-- Stable server entry point for the ambient visit service. The public
-- PNC.AmbientVisitService contract is assembled in deterministic order.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.AmbientVisitService = PNC.AmbientVisitService or {}

local Service = PNC.AmbientVisitService

require "PNC/World/PNC_AmbientVisitService_Core"
require "PNC/World/PNC_AmbientVisitService_Eligibility"
require "PNC/World/PNC_AmbientVisitService_MobileSites"
require "PNC/World/PNC_AmbientVisitService_Lease"
require "PNC/World/PNC_AmbientVisitService_Invitation"
require "PNC/World/PNC_AmbientVisitService_MobileShelter"
require "PNC/World/PNC_AmbientVisitService_Lifecycle"

return Service
