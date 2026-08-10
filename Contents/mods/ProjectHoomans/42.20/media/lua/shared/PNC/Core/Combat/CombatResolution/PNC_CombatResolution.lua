-- Server-authoritative combat outcome resolution.

PNC = PNC or {}
PNC.CombatResolution = PNC.CombatResolution or {}

require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Settings"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Weapon"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Resources"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_HitEvent"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Player"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_NPC"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Zombie"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Target"

return PNC.CombatResolution
