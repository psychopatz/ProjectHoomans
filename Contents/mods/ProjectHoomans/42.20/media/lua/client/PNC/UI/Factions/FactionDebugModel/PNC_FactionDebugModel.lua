-- Ordered entry point for the faction debug presentation model.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_Shared"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_Items"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_Mobile"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_SnapshotRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_Dashboard"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_ViewRows"

return Model

