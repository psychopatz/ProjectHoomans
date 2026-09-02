-- Server-authoritative colony management entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Core"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_DebugAccess"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ColonistActions"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_FacilityDebug"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_NearbyWater"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_DebugNeeds"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_SettlementSync"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_FactionCommands"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionSettlement"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionStorageColonists"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionTasking"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionProduction"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionWorkDebug"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Router"

return PNC.ColonyManagement
