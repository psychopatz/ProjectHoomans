-- Stable base-building catalog entry point.
PNC = PNC or {}
PNC.BaseBuildingCatalog = PNC.BaseBuildingCatalog or {}

-- The providers retain FilterFacilityRecipes, SetRowsStable, and the
-- buildRecipePreview surface used by the base UI contract.
-- The debug material action remains `building_debug_get_items` behind the
-- `CanUseDebug` availability gate.

require "PNC/UI/Base/PNC_BaseBuildingCatalog_Core"
require "PNC/UI/Base/PNC_BaseBuildingCatalog_Catalog"
require "PNC/UI/Base/PNC_BaseBuildingCatalog_Api"

return PNC.BaseBuildingCatalog
