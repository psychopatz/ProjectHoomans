-- Stable home-duty service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.HomeDutyService = PNC.HomeDutyService or {}
PNC.HomeDutyService.Internal = PNC.HomeDutyService.Internal or {}

require "PNC/Production/HomeDutyService/PNC_HomeDutyService_Core"
require "PNC/Production/HomeDutyService/PNC_HomeDutyService_Queries"
require "PNC/Production/HomeDutyService/PNC_HomeDutyService_Commands"
require "PNC/Production/HomeDutyService/PNC_HomeDutyService_Arrivals"

return PNC.HomeDutyService
