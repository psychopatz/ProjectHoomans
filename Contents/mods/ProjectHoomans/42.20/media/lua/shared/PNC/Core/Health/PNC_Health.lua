-- Stable entry point for NPC health state, damage, death, and recovery.

PNC = PNC or {}
PNC.Health = PNC.Health or {}
PNC.Health.Internal = PNC.Health.Internal or {}

require "PNC/Core/Health/PNC_Health/PNC_Health_LiveState"
require "PNC/Core/Health/PNC_Health/PNC_Health_Incapacitation"
require "PNC/Core/Health/PNC_Health/PNC_Health_Death"
require "PNC/Core/Health/PNC_Health/PNC_Health_Damage"
require "PNC/Core/Health/PNC_Health/PNC_Health_Update"

return PNC.Health
