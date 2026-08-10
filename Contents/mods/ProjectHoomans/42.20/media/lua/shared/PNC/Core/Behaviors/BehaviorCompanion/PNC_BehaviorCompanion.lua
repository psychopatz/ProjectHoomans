--[[
    PNC Companion Behavior
    Ordered entry point for companion follow, threat-response, guard, and
    patrol behavior. Public API wiring is loaded last.
]]

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}

local Companion = PNC.BehaviorCompanion
Companion.Internal = Companion.Internal or {}

require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_PersonalSpace"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazards"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_ThreatResponse"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_StaticOrders"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Api"

return Companion
