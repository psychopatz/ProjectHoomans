--[[
    PNC Combat Tactics
    Stable entry point for tactical combat decisions. Focused implementation
    modules share private helpers through `PNC.CombatTactics.Internal`.
]]

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_State"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_ThreatAssessment"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_Retreat"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_Melee"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_FireControl"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_Repositioning"

return Tactics
