-- Workshop catalog rebuild composition root.
-- Helpers/actions, catalog rows, and final build orchestration load in order.

PNC = PNC or {}
PNC.WorkshopCatalogRebuild = PNC.WorkshopCatalogRebuild or {}

require "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Helpers"
require "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Rows"
require "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Build"

return PNC.WorkshopCatalogRebuild
