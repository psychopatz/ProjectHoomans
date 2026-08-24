-- Stable debug companion recruitment entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit

require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Core"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Community"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Ownership"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Persistence"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Assignment"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Reconciliation"
require "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Commands"

return PNC.DebugCompanionRecruit
