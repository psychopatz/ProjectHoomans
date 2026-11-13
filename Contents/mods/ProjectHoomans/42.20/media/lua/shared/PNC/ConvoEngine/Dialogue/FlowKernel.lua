-- Minimal bounded dialogue-flow preview/commit kernel.
--
-- Preview only calculates a transition. Commit is the sole mutation path and
-- stores bounded flow state inside the existing dialogue context object.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Rules = require
    "PNC/ConvoEngine/Dialogue/RuleProvider"
local Registry = require
    "PNC/ConvoEngine/Dialogue/FlowCatalog"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Kernel = PNC.ConvoEngine.DialogueFlowKernel or {}
PNC.ConvoEngine.DialogueFlowKernel = Kernel

Kernel.VERSION = 1
Kernel.DEFAULT_MAX_STACK = 4
Kernel.DEFAULT_MAX_FLOWS = 8
Kernel.MAX_DIAGNOSTIC_CANDIDATES = 8
Kernel.Internal = Kernel.Internal or {}

local Internal = Kernel.Internal
Internal.Rules = Rules
Internal.RuleProvider = Rules
Internal.Registry = Registry
Internal.CopyValue = ValueBounds.Copy

require "PNC/ConvoEngine/Dialogue/FlowKernel_Storage"
require "PNC/ConvoEngine/Dialogue/FlowKernel_Matching"
require "PNC/ConvoEngine/Dialogue/FlowKernel_Preview"
require "PNC/ConvoEngine/Dialogue/FlowKernel_Commit"
require "PNC/ConvoEngine/Dialogue/FlowKernel_Results"

return Kernel
