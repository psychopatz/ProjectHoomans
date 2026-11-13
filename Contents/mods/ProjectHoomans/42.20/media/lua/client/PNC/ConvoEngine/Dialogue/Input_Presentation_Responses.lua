-- Build deterministic semantic reply payloads before queue delivery.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local ResponseAdapter = Internal.ResponseAdapter or {}
Internal.ResponseAdapter = ResponseAdapter

require "PNC/ConvoEngine/Dialogue/Input_Presentation_Responses_Translation"
require "PNC/ConvoEngine/Dialogue/Input_Presentation_Responses_Payloads"
require "PNC/ConvoEngine/Dialogue/Input_Presentation_Responses_Actions"

return ResponseAdapter
