local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Provision/"
local entry = T.read(ROOT .. "PNC_ProvisionEvaluator.lua")
local core = T.read(
    ROOT .. "ProvisionEvaluator/PNC_ProvisionEvaluator_Core.lua"
)
local evaluation = T.read(
    ROOT .. "ProvisionEvaluator/PNC_ProvisionEvaluator_Evaluation.lua"
)
local storage = T.read(
    ROOT .. "ProvisionEvaluator/PNC_ProvisionEvaluator_Storage.lua"
)
local inspection = T.read(
    ROOT .. "ProvisionEvaluator/PNC_ProvisionEvaluator_Inspection.lua"
)

T.contains(entry, "PNC.ProvisionEvaluator.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.ProvisionRuntime",
    "runtime state stays behind the internal boundary")
T.contains(evaluation, "function Evaluator.Evaluate",
    "public evaluation API remains available")
T.contains(storage, "function Evaluator.MeasureStorage",
    "public storage measurement remains available")
T.contains(inspection, "function Evaluator.Inspect",
    "public diagnostics API remains available")
T.falsy(string.find(entry, "function Evaluator.Evaluate", 1, true),
    "entry contains wiring rather than implementation")
