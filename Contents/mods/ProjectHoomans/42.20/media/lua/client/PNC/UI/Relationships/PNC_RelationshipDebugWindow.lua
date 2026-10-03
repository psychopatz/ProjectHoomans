-- Stable relationship laboratory entry. Window construction, interaction
-- behavior, and rendering/lifecycle providers load in dependency order.
require "PNC/UI/Relationships/PNC_RelationshipDebugWindow_Core"
require "PNC/UI/Relationships/PNC_RelationshipDebugWindow_Behavior"
require "PNC/UI/Relationships/PNC_RelationshipDebugWindow_Render"

return PNC.RelationshipDebugUI
