-- Route schema restoration and Follow reconciliation, without movement execution.
local Repository = {}
-- The application supplies Follow intent and applies any returned travel
-- directive through Companions. Travel never writes another domain's order.
function Repository.RestoreRecord(record, raw, following)
    if type(raw.travel) == "table"
        and PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.Normalize
    then
        record.travel = PNC.Travel.Model.Normalize(
            raw.travel,
            record,
            PNC.Travel.Service and PNC.Travel.Service.WorldHour
                and PNC.Travel.Service.WorldHour()
                or tonumber(raw.travel.lastAdvancedWorldHour)
                or 0
        )
        -- Follow owns the canonical position through the presence lane. An
        -- older save may contain a terminal or active home journey beside a
        -- durable Follow order; retaining that route lets load-time travel
        -- reconciliation replay the base destination over the follower.
        -- Keep the saved position/order and retire the stale route instead.
        if record.travel and following == true then
            record.travel = nil
            if PNC.Registry and PNC.Registry.MarkDirty then
                PNC.Registry.MarkDirty(record, "follow_travel_reconciled")
            end
        elseif record.travel and PNC.Travel.Model.IsActive(record.travel) then
            return true, record.travel.journeyId
        end
    end
    return false
end

return Repository
