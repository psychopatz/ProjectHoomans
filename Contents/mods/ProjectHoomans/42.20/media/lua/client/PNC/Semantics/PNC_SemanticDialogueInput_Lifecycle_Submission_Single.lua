-- Single semantic-turn submission orchestration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Preflight"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Interpretation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Commit"

function Internal.SubmitSingle(view, value, part)
    local prepared, prepareReason = Internal.PrepareSingleSubmission(
        view, value, part)
    if not prepared then return false, prepareReason end
    if prepared.compoundParts then
        return Internal.SubmitCompound(
            view, prepared.value, prepared.compoundParts, prepared.part)
    end

    local interpretation, interpretationReason =
        Internal.InterpretSingleSubmission(view, prepared)
    if not interpretation then return false, interpretationReason end
    return Internal.CommitSingleSubmission(view, prepared, interpretation)
end

return Input
