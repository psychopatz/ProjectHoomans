-- Server-authoritative task request composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskRequestService = PNC.TaskRequestService or {}

local Service = PNC.TaskRequestService
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

require "PNC/Tasking/PNC_TaskRequestService_Commands"
require "PNC/Tasking/PNC_TaskRequestService_Snapshots"

return Service
