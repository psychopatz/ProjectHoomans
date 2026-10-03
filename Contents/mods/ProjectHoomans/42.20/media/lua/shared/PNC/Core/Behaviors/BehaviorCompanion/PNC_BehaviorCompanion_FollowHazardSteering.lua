-- Compatibility entry point for horde avoidance target generation.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowHazardSteering
if type(H) ~= "table" then return Companion end

local TargetResolver = H.TargetResolver

function Internal.ResolveHordeAwareFollowTarget(
    record,
    slotTarget,
    slotDist,
    hazard,
    now
)
    if TargetResolver and TargetResolver.Resolve then
        return TargetResolver.Resolve(
            record,
            slotTarget,
            slotDist,
            hazard,
            now
        )
    end
    return nil
end

return Companion
