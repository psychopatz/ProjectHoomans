-- Runtime-only seating for live NPCs that retain a durable roam order.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamingSeat = PNC.RoamingSeat or {}

local Service = PNC.RoamingSeat
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local function facilityJobs()
    return PNC.FacilityJobs or Jobs
end

local function facilityResources()
    return PNC.FacilityResources or Resources
end

local function interactionTargets()
    return PNC.FacilityInteractionTargets or Targets
end

local function facilityReservations()
    return PNC.FacilityReservations or Reservations
end

Service.NextAttemptAt = Service.NextAttemptAt or {}
Service.CADENCE_MS = 5000
Service.MIN_IDLE_MS = 1200
Service.SEARCH_RADIUS = 6
Service.MAX_OBJECTS = 96
Service.MAX_ATTEMPTS_PER_TICK = 4
Service.SEAT_MIN_MS = 30000
Service.SEAT_MAX_MS = 90000
Service.POST_SEAT_DWELL_MIN_MS = 20000
Service.POST_SEAT_DWELL_MAX_MS = 45000

local SCENE_ID = "ambient.roam.sitFurniture"
local FLOOR_SCENE_ID = "facility.living.sit"
local AMBIENT_FACILITY_ID = "ambient:roam"
local RESERVATION_PURPOSE = "ambient_roam_seat"
local GUARD_RESERVATION_PURPOSE = "guard_seat"


local Internal = Service.Internal or {}
Service.Internal = Internal
Internal.SCENE_ID = SCENE_ID
Internal.FLOOR_SCENE_ID = FLOOR_SCENE_ID
Internal.AMBIENT_FACILITY_ID = AMBIENT_FACILITY_ID
Internal.RESERVATION_PURPOSE = RESERVATION_PURPOSE
Internal.GUARD_RESERVATION_PURPOSE = GUARD_RESERVATION_PURPOSE
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Policy"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Discovery"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Lifecycle"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Start"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Tick"
require "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService_Scenes"

return Service
