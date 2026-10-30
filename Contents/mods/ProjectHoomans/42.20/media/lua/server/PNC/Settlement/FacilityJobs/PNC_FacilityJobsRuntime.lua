-- Domain registration: Settlement. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Settlement/FacilityJobs/PNC_FacilityJobs_Service"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService"
require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientService"
