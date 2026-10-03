-- Lumber output delivery composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService

require "PNC/Lumber/LumberService/PNC_LumberService_Execution_OutputDelivery_Pickup"
require "PNC/Lumber/LumberService/PNC_LumberService_Execution_OutputDelivery_Deposit"

return Service
