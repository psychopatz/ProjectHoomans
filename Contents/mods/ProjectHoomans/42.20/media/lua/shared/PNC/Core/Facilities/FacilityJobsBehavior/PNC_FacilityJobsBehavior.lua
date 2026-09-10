-- Stable facility-jobs behavior entry point.
-- Runtime behavior is split into cohesive providers while the public
-- PNC.FacilityJobs namespace and registration contract remain unchanged.

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Constants"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_State"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Seating"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Approach"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Camp"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Lifecycle"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Scenes"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Tick"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Api"

local Jobs = PNC.FacilityJobs
local Internal = PNC.FacilityJobsBehaviorInternal

PNC.OrderSystem.RegisterNormalizer(Internal.KIND, Internal.Normalize)
PNC.JobSystem.RegisterOrder(Internal.KIND, Internal.JOB)
PNC.BehaviorRegistry.Register(Internal.JOB, Jobs.Tick)

return Jobs
