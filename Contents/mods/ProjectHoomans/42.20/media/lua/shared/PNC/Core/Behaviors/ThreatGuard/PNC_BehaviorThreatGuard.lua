-- Canonical entry point for passive threat arbitration.

PNC = PNC or {}
PNC.BehaviorThreatGuard = PNC.BehaviorThreatGuard or {}
PNC.BehaviorThreatGuard.Internal = PNC.BehaviorThreatGuard.Internal or {}

require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Contexts"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_TargetEligibility"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Transitions"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Lifecycle"

return PNC.BehaviorThreatGuard
