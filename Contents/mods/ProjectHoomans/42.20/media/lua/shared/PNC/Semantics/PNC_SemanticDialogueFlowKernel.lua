-- Minimal bounded dialogue-flow preview/commit kernel.
--
-- Preview only calculates a transition. Commit is the sole mutation path and
-- stores bounded flow state inside the existing dialogue context object.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Rules = require "PNC/Conversation/Blocks/PNC_ConversationRules"
local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowCatalog"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Kernel = PNC.Semantics.DialogueFlowKernel or {}
PNC.Semantics.DialogueFlowKernel = Kernel

Kernel.VERSION = 1
Kernel.DEFAULT_MAX_STACK = 4
Kernel.DEFAULT_MAX_FLOWS = 8
Kernel.MAX_DIAGNOSTIC_CANDIDATES = 8
Kernel.Internal = Kernel.Internal or {}

local Internal = Kernel.Internal
Internal.Rules = Rules
Internal.Registry = Registry
Internal.CopyValue = ValueBounds.Copy

require "PNC/Semantics/PNC_SemanticDialogueFlowKernel_Storage"
require "PNC/Semantics/PNC_SemanticDialogueFlowKernel_Matching"
require "PNC/Semantics/PNC_SemanticDialogueFlowKernel_Preview"
require "PNC/Semantics/PNC_SemanticDialogueFlowKernel_Commit"
require "PNC/Semantics/PNC_SemanticDialogueFlowKernel_Results"

return Kernel
