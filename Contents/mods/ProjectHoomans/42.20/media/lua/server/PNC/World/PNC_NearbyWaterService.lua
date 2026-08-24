-- Stable nearby-water service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}

require "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Core"
require "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Origin"
require "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Approach"
require "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Discovery"
require "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Consumption"

return PNC.NearbyWaterService
