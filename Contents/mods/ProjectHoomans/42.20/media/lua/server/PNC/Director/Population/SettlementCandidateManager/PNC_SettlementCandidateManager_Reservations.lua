if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementCandidates = PNC.SettlementCandidates or {}
PNC.SettlementCandidateManagerInternal =
    PNC.SettlementCandidateManagerInternal or {}

local Candidates = PNC.SettlementCandidates
local H = PNC.SettlementCandidateManagerInternal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Core = PNC.Core
local Log = PNC.PopulationLog

function Candidates.ReservationSnapshot(now)
    now = tonumber(now) or Store.WorldAgeHours()
    local output = {}
    for _, value in pairs(Candidates.Reservations) do
        output[#output + 1] = { locationId = value.locationId,
            generationId = value.generationId,
            expiresAt = value.expiresAt,
            remainingHours = math.max(0, value.expiresAt - now) }
    end
    table.sort(output, function(a, b) return a.locationId < b.locationId end)
    return output
end

function Candidates.Reserve(locationID, generationID, now)
    now = tonumber(now) or Store.WorldAgeHours()
    local existing = Candidates.Reservations[locationID]
    if existing and existing.expiresAt > now
        and existing.generationId ~= generationID then return false, "site_reserved" end
    Candidates.Reservations[locationID] = { locationId = locationID,
        generationId = generationID,
        expiresAt = now + Config.RESERVATION_EXPIRY_HOURS }
    Candidates.Metrics.reservations = Candidates.Metrics.reservations + 1
    return true, "reserved"
end

function Candidates.HasReservation(locationID, generationID, now)
    local value = Candidates.Reservations[locationID]
    return value ~= nil and value.generationId == generationID
        and value.expiresAt > (tonumber(now) or Store.WorldAgeHours())
end

function Candidates.Release(locationID, generationID)
    local value = Candidates.Reservations[locationID]
    if not value or generationID and value.generationId ~= generationID then return false end
    Candidates.Reservations[locationID] = nil
    return true
end

function Candidates.Expire(now)
    now = tonumber(now) or Store.WorldAgeHours()
    local removed = 0
    for id, value in pairs(Candidates.Reservations) do
        if value.expiresAt <= now then Candidates.Reservations[id] = nil removed = removed + 1 end
    end
    return removed
end

return Candidates

