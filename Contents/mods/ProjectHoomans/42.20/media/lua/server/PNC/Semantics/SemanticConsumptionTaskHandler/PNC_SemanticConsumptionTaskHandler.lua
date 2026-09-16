-- Server entry point for semantic consumption task admission.
-- Contract/validation and plan composition live in ordered spokes so this
-- file remains a small load-order hub.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ConsumptionTaskHandler =
    PNC.Semantics.ConsumptionTaskHandler or {}

local Handler = PNC.Semantics.ConsumptionTaskHandler
local Requests = PNC.Semantics.TaskRequestService

require "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler_Contract"
require "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler_Plan"

if Requests and type(Requests.RegisterHandler) == "function" then
    Requests.RegisterHandler("EAT", Handler)
    Requests.RegisterHandler("DRINK", Handler)
    Requests.RegisterHandler("REFILL", Handler)
    Requests.RegisterHandler("CONSUME", Handler)
end

return Handler
