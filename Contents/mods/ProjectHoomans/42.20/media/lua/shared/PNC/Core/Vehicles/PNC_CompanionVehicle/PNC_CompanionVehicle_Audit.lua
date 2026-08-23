local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core
local Const = PNC.Const

local lastReservationAuditAt = 0

local function auditContainer(
    vehicleId,
    part,
    container,
    seen
)
    local actualSeat = tonumber(
        Internal.SafeMethod(part, "getContainerSeatNumber")
    )
    local stale = {}
    local removed = 0
    local i
    Internal.ForEachContainerItem(container, function(item)
        local data = Internal.ReservationData(item)
        local key
        local valid
        if data then
            key =
                tostring(data.npcId or "")
                .. ":" .. tostring(data.seat or "")
            valid = actualSeat ~= nil
                and actualSeat >= 0
                and tostring(data.vehicleId or "") == tostring(vehicleId)
                and tonumber(data.seat) == actualSeat
                and Internal.IsActiveReservation(
                    data,
                    vehicleId,
                    actualSeat
                )
                and seen[key] ~= true
            if valid then
                seen[key] = true
            else
                stale[#stale + 1] = item
            end
        end
    end)
    for i = 1, #stale do
        if Internal.RemoveContainerItem(container, stale[i]) then
            removed = removed + 1
        end
    end
    return removed
end

function Internal.AuditVehicle(vehicle)
    local vehicleId = Internal.VehicleKey(vehicle)
    local seen = {}
    local removed = 0
    Internal.ForEachVehicleContainer(vehicle, function(part, container)
        removed = removed + auditContainer(
            vehicleId,
            part,
            container,
            seen
        )
    end)
    return removed
end

local function auditDue(now, force)
    return force
        or (now - lastReservationAuditAt)
            >= (
                tonumber(Const.VEHICLE_RESERVATION_AUDIT_MS)
                or 10000
            )
end

function CompanionVehicle.AuditLoadedReservations(now, force)
    local cell
    local vehicles
    local size
    local i
    local removed = 0
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not auditDue(now, force) then
        return 0
    end
    lastReservationAuditAt = now
    cell = getCell and getCell() or nil
    vehicles = cell
        and Internal.SafeMethod(cell, "getVehicles")
        or nil
    size = tonumber(Internal.SafeMethod(vehicles, "size"))
    if size == nil then return 0 end
    for i = 0, size - 1 do
        removed = removed + Internal.AuditVehicle(
            Internal.SafeMethod(vehicles, "get", i)
        )
    end
    if removed > 0 then
        Core.LogDebug(
            "companion_vehicle audit removed stale reservations="
                .. tostring(removed)
        )
    end
    return removed
end
