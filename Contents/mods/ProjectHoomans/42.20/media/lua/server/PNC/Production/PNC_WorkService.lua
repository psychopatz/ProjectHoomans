-- Server-authoritative production work orchestration entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

require "PNC/Production/WorkService/PNC_WorkService_WorkLocation"
require "PNC/Production/WorkService/PNC_WorkService_Core"
require "PNC/Production/WorkService/PNC_WorkService_QueueAndClaims"
require "PNC/Production/WorkService/PNC_WorkService_WorkerReconciliation"
require "PNC/Production/WorkService/PNC_WorkService_Targets"
require "PNC/Production/WorkService/PNC_WorkService_Progress"
require "PNC/Production/WorkService/PNC_WorkService_Commands"
require "PNC/Production/WorkService/PNC_WorkService_Queries"
require "PNC/Production/WorkService/PNC_WorkService_Snapshots"
require "PNC/Production/WorkService/PNC_WorkService_Scheduler"

return PNC.WorkService
