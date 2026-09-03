-- Tasking provider for NPC-to-NPC medical care.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MedicalCareExecutor = PNC.MedicalCareExecutor or {}

local Executor = PNC.MedicalCareExecutor
Executor.Internal = Executor.Internal or {}

require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Provider"
require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Actions"

if PNC.Tasking and PNC.Tasking.Commands
    and PNC.Tasking.Commands.RegisterProvider
    and not Executor.Registered
then
    local registered = PNC.Tasking.Commands.RegisterProvider("medical", Executor)
    Executor.Registered = registered == true
end

return Executor
