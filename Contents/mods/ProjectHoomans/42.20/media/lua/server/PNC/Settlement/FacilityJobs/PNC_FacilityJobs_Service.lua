-- Stable facility-jobs service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Core"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_ManualTargets"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Toggle"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Resolution"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Start"

return PNC.FacilityJobs
