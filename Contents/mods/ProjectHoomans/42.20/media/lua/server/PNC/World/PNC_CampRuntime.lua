-- Domain registration: World. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/World/PNC_CampZoneService"
require "PNC/World/PNC_CampMovementCoordinator"
require "PNC/World/PNC_AmbientVisitService"
