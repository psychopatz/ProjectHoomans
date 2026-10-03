-- Community map layer composition root.
-- Site geometry, rendering/hover, and claim/registration providers load in order.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISContextMenu"
require "PNC/UI/PNC_NPCTypePalette"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.CommunityMapLayer = PNC.CommunityMapLayer or {}

require "PNC/UI/Map/Layers/PNC_MapLayer_Communities_Core"
require "PNC/UI/Map/Layers/PNC_MapLayer_Communities_Render"
require "PNC/UI/Map/Layers/PNC_MapLayer_Communities_Claims"

return PNC.CommunityMapLayer
