-- Combat engagement composition root.
-- Shared decision helpers load before combat lanes and the live tick.
PNC = PNC or {}
PNC.CombatEngagement = PNC.CombatEngagement or {}
PNC.CombatEngagement.Internal = PNC.CombatEngagement.Internal or {}

require "PNC/Core/Combat/CombatEngagement/PNC_Combat_Engagement_Core"
require "PNC/Core/Combat/CombatEngagement/PNC_Combat_Engagement_Lanes"
require "PNC/Core/Combat/CombatEngagement/PNC_Combat_Engagement_Tick"

return PNC.CombatEngagement
