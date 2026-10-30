-- Stable client editor-model entry point. Draft construction, definition
-- import, validation, runtime preview sync, and presentation operations load
-- in dependency order while the public Model API stays at this path.
require "PNC/Identity/UniqueNPCDraft/PNC_UniqueNPCDraft_Core"
require "PNC/Identity/UniqueNPCDraft/PNC_UniqueNPCDraft_Definition"
require "PNC/Identity/UniqueNPCDraft/PNC_UniqueNPCDraft_Validation"
require "PNC/Identity/UniqueNPCDraft/PNC_UniqueNPCDraft_Runtime"
require "PNC/Identity/UniqueNPCDraft/PNC_UniqueNPCDraft_Presentation"

return PNC.UniqueNPCEditorModel
