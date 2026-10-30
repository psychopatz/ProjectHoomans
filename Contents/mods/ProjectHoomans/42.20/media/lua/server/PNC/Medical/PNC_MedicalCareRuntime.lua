-- Domain registration: Health. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Medical/PNC_MedicalCareRepository"
require "PNC/Medical/PNC_MedicalCareService"
require "PNC/Medical/PNC_MedicalCareExecutor"
