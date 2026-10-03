-- Follow-owner orchestration across formation, hazards, vehicles, and threats.

local Internal = PNC.BehaviorCompanion.Internal

-- Bodyless followers use only owner resolution and direct abstract movement.
-- This deliberately avoids the live follow pipeline's zombie perception,
-- threat response, formation scan, animation, and engine pathing work.
if not Internal.TickAbstractFollowOwner then
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner"
end
if not Internal.FollowOwnerStateHandoff then
    Internal.FollowOwnerStateHandoff = {
        Registry = PNC.Registry,
        AnimationScenes = PNC.AnimationScenes,
        Diagnostics = PNC.PerformanceScalingDiagnostics,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_StateHandoff"
end
if type(Internal.FollowOwnerTick) ~= "table" then
    Internal.FollowOwnerTick = {
        Core = PNC.Core,
        Const = PNC.Const,
        Stealth = PNC.Stealth,
        Common = PNC.BehaviorCommon,
        CompanionVehicle = PNC.CompanionVehicle,
    }
end
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_Tick"
