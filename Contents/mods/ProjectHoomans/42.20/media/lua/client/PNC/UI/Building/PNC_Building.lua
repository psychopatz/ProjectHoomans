PNC = PNC or {}
PNC.BuildingUI = PNC.BuildingUI or {}

-- Compatibility shim: the visible building surface now belongs to the
-- detachable Base widget. Existing callers may continue requiring this
-- module without reopening the legacy standalone window.
require "PNC/UI/Base/PNC_Base"

return PNC.BaseUI or PNC.BuildingUI
