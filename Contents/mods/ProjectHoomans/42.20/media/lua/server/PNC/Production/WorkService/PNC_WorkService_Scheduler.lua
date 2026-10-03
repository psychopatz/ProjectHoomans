-- WorkService scheduler composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

require "PNC/Production/WorkService/PNC_WorkService_Scheduler_Orders"
require "PNC/Production/WorkService/PNC_WorkService_Scheduler_Pump"

local Service = PNC.WorkService
local Internal = Service.Internal

function Service.Tick(at)
    return Internal.Tick(at)
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Tick() end)
    Service.TickHookRegistered = true
end

return Service
