-- Server-authoritative work task provider composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = PNC.WorkTaskProvider or {}
Provider.Internal = Provider.Internal or {}
PNC.WorkTaskProvider = Provider

require "PNC/Tasking/PNC_WorkTaskProvider_Context"
require "PNC/Tasking/PNC_WorkTaskProvider_Assignment"
require "PNC/Tasking/PNC_WorkTaskProvider_Lease"
require "PNC/Tasking/PNC_WorkTaskProvider_Execution"

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("work", Provider)
end

return Provider
