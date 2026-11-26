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

if not Service.TickHookRegistered then
    local TickRegistry = PNC.Server and PNC.Server.TickRegistry
        or require "PNC/Server/Server/PNC_Server_TickRegistry"
    if TickRegistry and type(TickRegistry.Register) == "function" then
        TickRegistry.Register("work_service", {
            phase = "prepare",
            priority = 40,
            pump = function(at) Service.Tick(at) end,
        })
        Service.TickHookRegistered = true
    elseif Events and Events.OnTick then
        Events.OnTick.Add(function() Service.Tick() end)
        Service.TickHookRegistered = true
    end
end

return Service
