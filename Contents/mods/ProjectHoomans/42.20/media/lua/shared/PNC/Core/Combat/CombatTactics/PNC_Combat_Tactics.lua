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
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_Movement"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_RetreatLifecycle"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_MeleeTargeting"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_MeleeDecision"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_FireLane"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_RangedReadiness"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_RangedPositioning"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_ThreatAvoidance"

return Tactics
