-- Internal implementation hub for semantic dialogue input submission.
-- The public lifecycle entry point remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Receipts"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Compound"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Single"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Gossip"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Fact"
