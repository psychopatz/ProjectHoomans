-- Stable facility-jobs service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Core"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_ManualTargets"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_ManualWater"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_ManualSleep"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_ManualStart"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Toggle"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Resolution"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Start_Targeting"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_StartState"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Start"

return PNC.FacilityJobs
