-- Facility activity lifecycle composition root.
PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

-- Compatibility contract: function Internal.RecordProgress remains the
-- facility effect-clock owner implemented by the finish provider.
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Lifecycle_SleepWake"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Lifecycle_Finish"

return PNC.FacilityJobs
