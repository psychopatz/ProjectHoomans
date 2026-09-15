-- Ordered mobile presentation modules.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_MobileCatalog"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_MobileRows"

return Model
