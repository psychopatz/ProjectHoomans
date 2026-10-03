-- Stable server camp movement coordinator entry point.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.CampMovementCoordinator = PNC.CampMovementCoordinator or {}

require "PNC/World/PNC_CampMovementCoordinator_Core"
require "PNC/World/PNC_CampMovementCoordinator_Sessions"
require "PNC/World/PNC_CampMovementCoordinator_Start"
require "PNC/World/PNC_CampMovementCoordinator_Pump"

return PNC.CampMovementCoordinator
