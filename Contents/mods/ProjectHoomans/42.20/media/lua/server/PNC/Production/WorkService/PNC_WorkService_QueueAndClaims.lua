-- WorkService queue and claim providers composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

require "PNC/Production/WorkService/PNC_WorkService_Queue"
require "PNC/Production/WorkService/PNC_WorkService_Claims"

local Service = PNC.WorkService
local Internal = Service.Internal
Service.Commands = Service.Commands or {}

function Service.Commands.Queue(spec)
    return Internal.Queue(spec)
end

return PNC.WorkService
