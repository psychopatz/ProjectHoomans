-- Stable abstract-group manager entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractGroups = PNC.AbstractGroups or {}

require "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_Core"
require "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_MobileImport"
require "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_Membership"
require "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_ThreatAndLOD"
require "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_State"

return PNC.AbstractGroups
