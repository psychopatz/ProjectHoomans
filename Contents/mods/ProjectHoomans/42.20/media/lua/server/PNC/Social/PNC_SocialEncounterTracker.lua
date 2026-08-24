-- Minimal server-runtime combat encounter aggregation for social milestones.
-- Runtime tables are intentionally not persisted and contain no engine objects.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
Tracker.Encounters = Tracker.Encounters or {}
Tracker.ByParticipant = Tracker.ByParticipant or {}
Tracker.ByThreat = Tracker.ByThreat or {}
Tracker.NextSequence = Tracker.NextSequence or 0
Tracker.LastPumpAt = Tracker.LastPumpAt
Tracker.MIN_DURATION_HOURS = 5 / 3600
Tracker.END_GRACE_HOURS = 15 / 3600
Tracker.ABANDON_GRACE_HOURS = 10 / 3600
Tracker.PUMP_INTERVAL_HOURS = 1 / 3600
Tracker.ABANDON_DISTANCE = 20

require "PNC/Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Context"
require "PNC/Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Activity"
require "PNC/Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Abandonment"
require "PNC/Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Completion"
require "PNC/Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Pump"

return Tracker
