-- Build deterministic semantic reply payloads before queue delivery.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local ResponseAdapter = Internal.ResponseAdapter or {}
Internal.ResponseAdapter = ResponseAdapter

require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Payloads"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Actions"

return ResponseAdapter
