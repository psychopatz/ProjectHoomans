-- Stable server entry point for authoritative water-container transactions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = require "PNC/World/PNC_WaterContainerService_Core"
require "PNC/World/PNC_WaterContainerService_Admission"
require "PNC/World/PNC_WaterContainerService_Refill"

return Service
