-- Stable timer-based abstract traversal entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractTraversal = PNC.AbstractTraversal or {}
PNC.AbstractTraversal.Internal = PNC.AbstractTraversal.Internal or {}

local Traversal = PNC.AbstractTraversal
Traversal.TravelCursor = Traversal.TravelCursor or 0
Traversal.DecisionCursor = Traversal.DecisionCursor or 0

require "PNC/Director/AbstractTraversal/PNC_AbstractTraversal_Destinations"
require "PNC/Director/AbstractTraversal/PNC_AbstractTraversal_Travel"
require "PNC/Director/AbstractTraversal/PNC_AbstractTraversal_Batches"

return Traversal
