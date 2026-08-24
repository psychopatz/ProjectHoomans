-- Stable starting-companion service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}

require "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Core"
require "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Identity"
require "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Assignment"
require "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Grant"
require "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Ensure"

return PNC.StartingCompanions
