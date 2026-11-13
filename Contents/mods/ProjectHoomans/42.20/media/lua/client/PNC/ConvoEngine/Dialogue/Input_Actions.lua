-- Stable semantic action-dispatch entry point.
-- Keep the Input.Internal action API and require path unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"
require "PNC/Semantics/PNC_SemanticWorldTargetHints"
require "PNC/Semantics/PNC_SemanticCampSiteHints"
require "PNC/Semantics/PNC_SemanticCampSite"
require "PNC/ConvoEngine/Dialogue/Input_ActionContext"
require "PNC/ConvoEngine/Dialogue/Input_ActionTargetHints"
require "PNC/ConvoEngine/Dialogue/Input_TaskDispatch"

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local Support = require
    "PNC/ConvoEngine/Dialogue/Input_Actions_Core"
Support.install(Input)

local installInventoryQuest = require
    "PNC/ConvoEngine/Dialogue/Input_Actions_InventoryQuest"
installInventoryQuest(Input, Internal, Support)

local installSocial = require
    "PNC/ConvoEngine/Dialogue/Input_Actions_Social"
installSocial(Input, Internal, Support)

local installDispatch = require
    "PNC/ConvoEngine/Dialogue/Input_Actions_Dispatch"
installDispatch(Input, Internal, Support)

return Input
