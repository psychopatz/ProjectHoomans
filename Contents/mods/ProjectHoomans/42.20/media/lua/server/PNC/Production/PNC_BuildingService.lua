-- Stable building service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}

require "PNC/Production/BuildingService/PNC_BuildingService_Context"
require "PNC/Production/BuildingService/PNC_BuildingService_Snapshot"
require "PNC/Production/BuildingService/PNC_BuildingService_Commands"
require "PNC/Production/BuildingService/PNC_BuildingService_Preparation"
require "PNC/Production/BuildingService/PNC_BuildingService_Placement"
require "PNC/Production/BuildingService/PNC_BuildingService_Lifecycle"

return PNC.BuildingService
