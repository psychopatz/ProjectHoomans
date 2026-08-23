-- Collision-safe shove displacement and engine-owned hit settling.
PNC = PNC or {}
PNC.CombatZombieReaction = PNC.CombatZombieReaction or {}

require "PNC/Core/Combat/PNC_Combat_ZombieReaction/PNC_Combat_ZombieReaction_Core"
require "PNC/Core/Combat/PNC_Combat_ZombieReaction/PNC_Combat_ZombieReaction_Shove"
require "PNC/Core/Combat/PNC_Combat_ZombieReaction/PNC_Combat_ZombieReaction_Hits"
require "PNC/Core/Combat/PNC_Combat_ZombieReaction/PNC_Combat_ZombieReaction_Runtime"

return PNC.CombatZombieReaction
