if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal

if PNC.Travel and PNC.Travel.Arrivals then
    PNC.Travel.Arrivals.RegisterHandler("colony_home",
        function(record, _, action)
            local point, reason, base = Service.GetHomePoint(
                record, action and action.baseId)
            if not point then return false, reason end
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

