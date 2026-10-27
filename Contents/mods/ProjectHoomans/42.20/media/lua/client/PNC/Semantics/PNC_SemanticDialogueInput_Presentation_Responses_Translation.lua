-- Semantic response template IDs and their localized UI keys.
--
-- The public translation entry point remains this file; the bounded key catalog
-- loads before the resolver so response adapters keep the same Internal hook.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Resolver"

return Internal.SemanticTranslationKey
