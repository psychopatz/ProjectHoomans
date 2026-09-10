PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal

Internal.KIND = "facility_activity"
Internal.JOB = "FacilityActivity"
Internal.SEAT_STOP_DISTANCE = 0.10
Internal.SEAT_ARRIVAL_TOLERANCE = 0.14
Internal.MAX_SCENE_START_ATTEMPTS = 3

return Internal
