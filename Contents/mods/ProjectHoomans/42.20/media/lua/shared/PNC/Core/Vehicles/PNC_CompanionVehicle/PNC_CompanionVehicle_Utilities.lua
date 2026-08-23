local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core

function Internal.SafeMethod(target, methodName, ...)
    local method
    local ok
    local value
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target, ...)
    return ok and value or nil
end

function Internal.VehicleKey(vehicle)
    local id = tonumber(Internal.SafeMethod(vehicle, "getId"))
    if id and id >= 0 then
        return "vehicle:" .. tostring(id)
    end
    return "runtime:" .. tostring(vehicle)
end

function Internal.VehiclePosition(vehicle, owner, record)
    return tonumber(Internal.SafeMethod(vehicle, "getX"))
            or tonumber(owner and Internal.SafeMethod(owner, "getX"))
            or tonumber(record.x) or 0,
        tonumber(Internal.SafeMethod(vehicle, "getY"))
            or tonumber(owner and Internal.SafeMethod(owner, "getY"))
            or tonumber(record.y) or 0,
        tonumber(Internal.SafeMethod(vehicle, "getZ"))
            or tonumber(owner and Internal.SafeMethod(owner, "getZ"))
            or tonumber(record.z) or 0
end

function Internal.MarkTransition(record, eventName, reason)
    local message =
        "companion_vehicle npc="
            .. tostring(record and record.id or "nil")
            .. " event=" .. tostring(eventName)
            .. " reason=" .. tostring(reason or "none")
    if Core and Core.LogRecordDebug then
        Core.LogRecordDebug(record, message)
    end
end

function Internal.SetPassengerPosition(record, vehicle, owner)
    local x
    local y
    local z
    x, y, z = Internal.VehiclePosition(vehicle, owner, record)
    record.x = x
    record.y = y
    record.z = z
    record.activeBehavior = "FollowOwner:vehicle_passenger"
    record.runtime.followState = record.runtime.followState or {}
    record.runtime.followState.mode = "vehicle_passenger"
end
