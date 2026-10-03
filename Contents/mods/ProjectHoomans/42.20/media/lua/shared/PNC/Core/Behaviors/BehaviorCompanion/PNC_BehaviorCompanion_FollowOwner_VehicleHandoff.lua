-- Vehicle boarding, passenger maintenance, and full-vehicle ownership for
-- live FollowOwner ticks.
PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerVehicleHandoff
if type(H) ~= "table" then return Companion end

local Common = H.Common
local CompanionVehicle = H.CompanionVehicle

function H.TryHandle(record, zombie, owner, ownerVehicle)
    local vehicleHandled
    local vehicleReason
    if CompanionVehicle and CompanionVehicle.Tick then
        vehicleHandled, vehicleReason = CompanionVehicle.Tick(
            record,
            zombie,
            owner
        )
        if vehicleHandled then
            Internal.SetFollowMode(
                record,
                CompanionVehicle.IsPassenger
                    and CompanionVehicle.IsPassenger(record)
                    and "vehicle_passenger"
                    or "vehicle_disembark"
            )
            return true
        end
    end
    -- A companion trying to catch its owner's car should not abandon that
    -- task for opportunistic combat. When no seat exists, it waits instead of
    -- repeatedly pathing into the occupied vehicle.
    if ownerVehicle and vehicleReason == "vehicle_full" then
        Internal.SetFollowMode(record, "vehicle_full")
        record.activeBehavior = "FollowOwner:vehicle_full"
        Common.ClearCombatTarget(record, "vehicle_full", zombie)
        Common.HaltMovement(record, zombie, "vehicle_full")
        return true
    end
    return false
end

return Companion
