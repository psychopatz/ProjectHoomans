--[[
    PNC Companion Behavior
    Ordered entry point for companion follow, threat-response, guard, and
    patrol behavior. Public API wiring is loaded last.
]]

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}

local Companion = PNC.BehaviorCompanion
Companion.Internal = Companion.Internal or {}
local Internal = Companion.Internal

require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal"
Internal.AbstractFollowOwnerResolution = {
    Const = PNC.Const,
    Common = PNC.BehaviorCommon,
    Diagnostics = PNC.PerformanceScalingDiagnostics,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_Resolution"
Internal.AbstractFollowOwnerMovementAudit = {
    Core = PNC.Core,
    Diagnostics = PNC.PerformanceScalingDiagnostics,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementAudit"
Internal.AbstractFollowOwnerMovementSpeed = {
    Const = PNC.Const,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementSpeed"
Internal.AbstractFollowOwnerMovementHandoff = {
    Core = PNC.Core,
    Const = PNC.Const,
    Common = PNC.BehaviorCommon,
    Diagnostics = PNC.PerformanceScalingDiagnostics,
    Audit = Internal.AbstractFollowOwnerMovementAudit,
    Speed = Internal.AbstractFollowOwnerMovementSpeed,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff_Advance"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner"
Internal.FollowOwnerStateHandoff = {
    Registry = PNC.Registry,
    AnimationScenes = PNC.AnimationScenes,
    Diagnostics = PNC.PerformanceScalingDiagnostics,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_StateHandoff"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_PersonalSpace"
Internal.FollowHazardTargetResolver = {
    Core = PNC.Core,
    Const = PNC.Const,
}
Internal.FollowHazardCandidatePlanner = {
    Const = PNC.Const,
    TraversalQuery = PNC.TraversalQuery,
    NormalizeDirection = Internal.NormalizeDirection,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering_CandidatePlanner"
Internal.FollowHazardTargetResolver.CandidatePlanner =
    Internal.FollowHazardCandidatePlanner
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering_TargetResolver"
Internal.FollowHazardSteering = {
    TargetResolver = Internal.FollowHazardTargetResolver,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazards"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_ThreatResponse"
Internal.FollowOwnerCombatRetreat = {
    Const = PNC.Const,
    CombatTactics = PNC.CombatTactics,
    BehaviorCombat = PNC.BehaviorCombat,
    SetFollowMode = Internal.SetFollowMode,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatRetreat"
Internal.FollowOwnerCombatHorde = {
    Const = PNC.Const,
    CombatTactics = PNC.CombatTactics,
    BehaviorCombat = PNC.BehaviorCombat,
    Perception = PNC.Perception,
    TryRespondToImmediateThreat = Internal.TryRespondToImmediateThreat,
    SetFollowMode = Internal.SetFollowMode,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatHorde"
Internal.FollowOwnerCombatLeash = {
    Const = PNC.Const,
    ShouldScanFollowThreat = Internal.ShouldScanFollowThreat,
    TryRespondToThreat = Internal.TryRespondToThreat,
    SetFollowMode = Internal.SetFollowMode,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatLeash"
Internal.FollowOwnerCombatHandoff = {
    Const = PNC.Const,
    CombatTactics = PNC.CombatTactics,
    BehaviorCombat = PNC.BehaviorCombat,
    Perception = PNC.Perception,
    RetreatHandoff = Internal.FollowOwnerCombatRetreat,
    HordeHandoff = Internal.FollowOwnerCombatHorde,
    LeashHandoff = Internal.FollowOwnerCombatLeash,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatHandoff"
Internal.FollowOwnerVehicleHandoff = {
    Common = PNC.BehaviorCommon,
    CompanionVehicle = PNC.CompanionVehicle,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_VehicleHandoff"
Internal.FollowOwnerMovementPlan = {
    Core = PNC.Core,
    Const = PNC.Const,
    Stealth = PNC.Stealth,
    Common = PNC.BehaviorCommon,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_MovementPlan"
Internal.FollowOwnerMovementHandoff = {
    Const = PNC.Const,
    MovementPlan = Internal.FollowOwnerMovementPlan,
}
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_MovementHandoff"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_StaticOrders"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Api"

return Companion
