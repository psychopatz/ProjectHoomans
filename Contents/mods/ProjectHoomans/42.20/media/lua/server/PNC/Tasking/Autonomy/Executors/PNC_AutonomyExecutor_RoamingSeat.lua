-- Autonomy executor for roaming and guard furniture/floor seating.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamingSeat = PNC.AutonomyExecutors.RoamingSeat or {}

local Service = PNC.AutonomyExecutors.RoamingSeat
Service.MIN_IDLE_MS = 1200
Service.SEARCH_RADIUS = 6
Service.MAX_OBJECTS = 96
Service.SEAT_MIN_MS = 30000
Service.SEAT_MAX_MS = 90000
Service.POST_SEAT_DWELL_MIN_MS = 20000
Service.POST_SEAT_DWELL_MAX_MS = 45000

local Internal = Service.Internal or {}
Service.Internal = Internal
Internal.SCENE_ID = "ambient.roam.sitFurniture"
Internal.FLOOR_SCENE_ID = "facility.living.sit"
Internal.AMBIENT_FACILITY_ID = "ambient:roam"
Internal.RESERVATION_PURPOSE = "ambient_roam_seat"
Internal.GUARD_RESERVATION_PURPOSE = "guard_seat"

require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Policy"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Discovery"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Lifecycle"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Start"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Tick"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Scenes"

return Service
