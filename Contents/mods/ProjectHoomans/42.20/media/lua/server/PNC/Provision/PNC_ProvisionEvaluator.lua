-- Stable provision evaluation and diagnostics entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProvisionEvaluator = PNC.ProvisionEvaluator or {}
PNC.ProvisionEvaluator.Internal = PNC.ProvisionEvaluator.Internal or {}

require "PNC/Provision/ProvisionEvaluator/PNC_ProvisionEvaluator_Core"
require "PNC/Provision/ProvisionEvaluator/PNC_ProvisionEvaluator_Evaluation"
require "PNC/Provision/ProvisionEvaluator/PNC_ProvisionEvaluator_Storage"
require "PNC/Provision/ProvisionEvaluator/PNC_ProvisionEvaluator_Inspection"

return PNC.ProvisionEvaluator
