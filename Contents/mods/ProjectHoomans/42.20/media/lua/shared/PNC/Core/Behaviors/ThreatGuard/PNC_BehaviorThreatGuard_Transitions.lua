-- Threat-guard transition composition root.
-- Scene handoff helpers load before target refresh and combat engagement.
local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal

require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Transitions_Scenes"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Transitions_Targets"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Transitions_Combat"

return ThreatGuard
