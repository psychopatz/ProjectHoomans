PNC = PNC or {}
PNC.BaseUI = PNC.BaseUI or {}

require "PNC/UI/Base/PNC_BaseWindow"

-- Keep the old public name as a compatibility alias for the Command Hub and
-- legacy Colony Management entry points while the visible surface becomes
-- the three-tab Base widget.
PNC.BuildingUI = PNC.BaseUI

return PNC.BaseUI
