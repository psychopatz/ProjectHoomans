-- Normalized facility executor order construction.
--
-- This stable module keeps the original provider path and composes the
-- runtime-state and order-payload writers below it.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal

-- Stable source boundary: function H.BuildFacilityActivityOrder is composed
-- by the payload provider after it installs the durable runtime state.
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_StartState_Order_Runtime"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_StartState_Order_Payload"

return H
