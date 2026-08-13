-- Canonical server Director entry. Dependency order is contractual.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Director/PNC_AbstractWorldStore"
require "PNC/Director/PNC_AbstractLocationManager"
require "PNC/Director/PNC_AbstractGroupManager"

-- World Discovery consumes the foundation above and supplies strategic sites
-- before the remaining simulation and population modules are initialized.
require "PNC/WorldDiscovery/PNC_WorldDiscovery"

require "PNC/Director/PNC_AbstractCombatProfile"
require "PNC/Director/PNC_AbstractResourceNeeds"
require "PNC/Director/PNC_AbstractBehaviorProfile"
require "PNC/Director/PNC_AbstractScavengeResolver"
require "PNC/Director/PNC_AbstractActionResolver"
require "PNC/Director/PNC_AbstractEncounterEvaluator"
require "PNC/Director/PNC_AbstractCasualtyResolver"
require "PNC/Director/PNC_AbstractRetreatResolver"
require "PNC/Director/PNC_AbstractCombatResolver"
require "PNC/Director/PNC_AbstractEncounterResolver"
require "PNC/Director/PNC_AbstractEncounterDetector"
require "PNC/Director/PNC_AbstractTraversal"
require "PNC/Director/Population/PNC_PopulationSandbox"
require "PNC/Director/Population/PNC_PopulationLog"
require "PNC/Director/Population/PNC_PopulationIdentity"
require "PNC/Director/Population/PNC_PopulationSectorManager"
require "PNC/Director/Population/PNC_PopulationBudget"
require "PNC/Director/Population/PNC_GenerationQueue"
require "PNC/Director/Population/PNC_GroupGenerationPlan"
require "PNC/Director/Population/PNC_SettlementGenerationPlan"
require "PNC/Director/Population/PNC_SettlementCandidateManager"
require "PNC/Director/Population/PNC_StarterPopulation"
require "PNC/Director/Population/PNC_GroupGenerator"
require "PNC/Director/Population/PNC_SettlementGenerator"
require "PNC/Director/Population/PNC_CommunityGroupFormation"
require "PNC/Director/Population/PNC_PopulationReconciler"
require "PNC/Director/Population/PNC_PopulationDirector"
require "PNC/Director/PNC_WorldDirector"
require "PNC/Director/PNC_AbstractDirectorDebug"

return PNC
