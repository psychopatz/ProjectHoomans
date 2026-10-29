-- Internal implementation hub for semantic dialogue input submission.
-- The public lifecycle entry point remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Receipts"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Compound"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Gossip"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Fact"
