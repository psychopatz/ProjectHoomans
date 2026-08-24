-- Stable colony farming service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}

require "PNC/Farming/FarmingService/PNC_FarmingService_Context"
require "PNC/Farming/FarmingService/PNC_FarmingService_Commands"
require "PNC/Farming/FarmingService/PNC_FarmingService_Materials"
require "PNC/Farming/FarmingService/PNC_FarmingService_Snapshots"
require "PNC/Farming/FarmingService/PNC_FarmingService_Ticks"
require "PNC/Farming/FarmingService/PNC_FarmingService_Provider"

return PNC.FarmingService
