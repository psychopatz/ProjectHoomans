-- Server-authoritative progress composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
Service.Commands = Service.Commands or {}

require "PNC/Production/WorkService/PNC_WorkService_Progress_Inputs"
require "PNC/Production/WorkService/PNC_WorkService_Progress_Completion"
require "PNC/Production/WorkService/PNC_WorkService_Progress_Accounting"

function Service.Commands.CollectInputs(orderId, workerId)
    return Internal.CollectInputs(orderId, workerId)
end

function Service.Commands.Assign(orderId, workerId)
    return Internal.Assign(orderId, workerId)
end

function Service.Commands.AddProgress(orderId, workerId, amount)
    return Internal.AddProgress(orderId, workerId, amount)
end

function Service.Commands.AddElapsed(orderId, workerId, elapsedSeconds)
    return Internal.AddElapsed(orderId, workerId, elapsedSeconds)
end

function Service.Commands.CompleteDeferred(orderId, reason)
    return Internal.CompleteDeferred(orderId, reason)
end

return Service
