if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
local Internal = Service.Internal or {}
Service.Internal = Internal
local Core = PNC.Core
local Registry = PNC.Registry
local worldAge = Internal.WorldAge
local finite = Internal.Finite
local relationshipFor = Internal.RelationshipFor
local sourceFaction = Internal.SourceFaction
local markDirty = Internal.MarkDirty

local function markPending(record, source, ownerKey, at, evaluation)
    local marker = record.colonistDeparture
    if type(marker) ~= "table" or marker.state == "completed" then
        marker = {
            state = "pending",
            eventID = "colonist_departure:" .. tostring(record.id),
            ownerKey = ownerKey,
            sourceFactionID = source.id,
            belowThresholdChecks = 0,
            firstDetectedAt = at,
            lastEvaluatedAt = 0,
        }
    end
    if at - finite(marker.lastEvaluatedAt, 0)
        < Service.PUMP_INTERVAL_HOURS
        and finite(marker.lastEvaluatedAt, 0) > 0
    then
        return marker, false
    end
    marker.state = "pending"
    marker.ownerKey = ownerKey
    marker.sourceFactionID = source.id
    marker.belowThresholdChecks = math.min(
        8, math.max(0, math.floor(finite(
            marker.belowThresholdChecks, 0
        ))) + 1
    )
    marker.firstDetectedAt = finite(marker.firstDetectedAt, at)
    marker.lastEvaluatedAt = at
    marker.approvalThreshold = evaluation.approvalThreshold
    marker.respectThreshold = evaluation.respectThreshold
    record.colonistDeparture = marker
    markDirty(record, "colonist_departure_threshold")
    return marker, true
end

function Service.Pump(at, budget)
    if not Core or not Core.IsAuthority or Core.IsAuthority() ~= true then
        return 0
    end
    at = worldAge(at)
    budget = math.max(1, math.floor(tonumber(budget)
        or Service.DEFAULT_PUMP_BUDGET))
    if Service.LastPumpAt
        and at - Service.LastPumpAt < Service.PUMP_INTERVAL_HOURS
    then
        return 0
    end
    Service.LastPumpAt = at
    if Registry and Registry.EnsureLoaded then Registry.EnsureLoaded() end
    local departures = 0
    for _, record in pairs(Registry and Registry.Data or {}) do
        if departures >= budget then break end
        if record and record.alive ~= false and record.recruited == true
            and record.affiliation and record.affiliation.factionID
        then
            local source = sourceFaction(record)
            if source then
                local ownerKey = source.ownerPlayerKey
                local relationship = relationshipFor(record, ownerKey)
                local evaluation = Service.Evaluate(record, relationship)
                if evaluation and evaluation.eligible then
                    local marker, changed = markPending(
                        record, source, ownerKey, at, evaluation
                    )
                    if changed and marker.belowThresholdChecks
                        >= evaluation.confirmationChecks
                    then
                        local ok = Service.Depart(record, "automatic", {
                            ownerKey = ownerKey,
                            worldAgeHours = at,
                            evaluation = evaluation,
                        })
                        if ok then departures = departures + 1 end
                    end
                elseif record.colonistDeparture
                    and record.colonistDeparture.state == "pending"
                    and evaluation and evaluation.recoverable
                then
                    record.colonistDeparture = nil
                    markDirty(record, "colonist_departure_recovered")
                end
            end
        end
    end
    return departures
end

return Service
