-- Stable entry point for authoritative zombie-attack defense resolution.

PNC = PNC or {}
PNC.CombatDefense = PNC.CombatDefense or {}
PNC.CombatDefense.Internal = PNC.CombatDefense.Internal or {}

require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_State"
require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_DamageChance"
require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_NearMiss"
require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_DamageModel"
require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_Legacy"
require "PNC/Core/Combat/PNC_Combat_Defense/PNC_Combat_Defense_Resolve"

return PNC.CombatDefense
