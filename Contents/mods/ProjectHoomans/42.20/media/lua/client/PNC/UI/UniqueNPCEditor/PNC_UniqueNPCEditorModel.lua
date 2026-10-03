-- Stable client editor-model entry point. Draft construction, definition
-- import, validation, runtime preview sync, and presentation operations load
-- in dependency order while the public Model API stays at this path.
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Core"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Definition"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Validation"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Runtime"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Presentation"

return PNC.UniqueNPCEditorModel
