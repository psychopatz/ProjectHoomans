-- Static semantic response template-key catalog facade.
-- Domain tables are split by semantic ownership to keep this namespace bounded.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local keys = {}
local function merge(source)
    for key, value in pairs(source) do
        keys[key] = value
    end
end

merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Action")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Conversation")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Flow")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Identity")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Health_State")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Identity")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Knowledge")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Medical_Bite")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Needs")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Relationship_Status")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Residence")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Wellbeing")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Wellbeing_Dataset")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Wellbeing_Follow_Up")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Wellbeing_Grounded")
merge(require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Social")

Internal.SemanticTranslationKeys = keys

return keys
