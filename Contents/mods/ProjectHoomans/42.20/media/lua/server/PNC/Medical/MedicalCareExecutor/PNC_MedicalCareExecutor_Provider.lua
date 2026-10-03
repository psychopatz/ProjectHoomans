if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC and PNC.MedicalCareExecutor
if not Executor then return end

require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Core"
require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Supply"
require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_SupplyActions"
require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Lifecycle"

return Executor
