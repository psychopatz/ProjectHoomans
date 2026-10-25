-- Stable semantic action-dispatch entry point.
-- Keep the Input.Internal action API and require path unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"
require "PNC/Semantics/PNC_SemanticWorldTargetHints"
require "PNC/Semantics/PNC_SemanticCampSiteHints"
require "PNC/Semantics/PNC_SemanticCampSite"
require "PNC/Semantics/PNC_SemanticDialogueInput_ActionContext"
require "PNC/Semantics/PNC_SemanticDialogueInput_ActionTargetHints"
require "PNC/Semantics/PNC_SemanticDialogueInput_TaskDispatch"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local Support = require
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions_Core"
Support.install(Input)

local installInventoryQuest = require
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions_InventoryQuest"
installInventoryQuest(Input, Internal, Support)

local installSocial = require
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions_Social"
installSocial(Input, Internal, Support)

local installDispatch = require
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions_Dispatch"
installDispatch(Input, Internal, Support)

return Input
