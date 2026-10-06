if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

if PNC.Travel and PNC.Travel.Arrivals then
    -- A failed home arrival must never be replaced by a roam order: that hides
    -- the failure and leaves the record claiming it is still returning home.
    PNC.Travel.Arrivals.StrictActionTypes =
        PNC.Travel.Arrivals.StrictActionTypes or {}
    PNC.Travel.Arrivals.StrictActionTypes.colony_home = true
    PNC.Travel.Arrivals.RegisterHandler("colony_home",
        function(record, _, action)
            local point
            local reason
            local base = Service.GetBase(record, action and action.baseId)
            if action and tonumber(action.x) and tonumber(action.y)
                and base
            then
                -- The travel request was already authority-created from a
                -- validated HomePoint. Commit that exact destination instead
                -- of resolving the nearest node again at arrival time.
                point = {
                    x = tonumber(action.x),
                    y = tonumber(action.y),
                    z = tonumber(action.z) or tonumber(record.z) or 0,
                    radius = math.max(1, tonumber(action.radius) or 3),
                    homeZoneId = action.homeZoneId or base.baseZoneId,
                    stockpileNodeId = action.stockpileNodeId,
                }
            else
                point, reason, base = Service.GetHomePoint(
                    record, action and action.baseId)
            end
            if not point then return false, reason end
            if not base then return false, "BASE_NOT_FOUND" end
            local ok, why = H.SetAtHome(record, base, point)
            local courier = record.runtime and record.runtime.storageCourier
            if ok and courier and (courier.state == "RETURNING_HOME"
                or courier.state == "DEPOSITING")
                and PNC.ColonyStorageService
                and PNC.ColonyStorageService.CompleteNPCCourier
            then
                return PNC.ColonyStorageService.CompleteNPCCourier(record)
            end
            return ok, why
        end)
    PNC.Travel.Arrivals.RegisterHandler("colony_follow_player",
        function(record, _, action)
            return H.SetFollowing(record,
                action and action.ownerUsername,
                action and action.ownerOnlineID)
        end)
end

return Service
