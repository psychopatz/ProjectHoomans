PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal

PNC.SleepRuntime = PNC.SleepRuntime or {}
PNC.SleepRuntime.SurfaceOccupants = PNC.SleepRuntime.SurfaceOccupants or {}

require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Helpers"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Sleep"
require "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Seats"

return Internal
