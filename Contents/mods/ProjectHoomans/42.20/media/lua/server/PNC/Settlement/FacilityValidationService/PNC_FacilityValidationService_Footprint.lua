if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.FacilityValidationService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Farming = PNC.Farming
local H = Validation.Internal

function Validation.NormalizeFootprint(base, facility, input)
    if type(input) ~= "table" or input.kind ~= "region" then
        return H.Result(false, "INVALID_COMPONENT")
    end
    local ok, reason, region = GridRegion.validate(input.region)
    if not ok then return H.Result(false, reason) end
    local levels = 0
    for _, _ in pairs(region.levels) do levels = levels + 1 end
    if levels ~= 1 then
        return H.Result(false, "FACILITY_REGION_MULTIPLE_LEVELS")
    end
    if not GridRegion.isConnected(region, 4) then
        return H.Result(false, "FACILITY_REGION_DISCONNECTED")
    end
    if not H.BaseContainsRegion(base, region) then
        return H.Result(false, "OUTSIDE_BASE")
    end
    return H.Result(true, nil, { component = {
        schemaVersion = 1,
        id = tostring(input.id or ""),
        facilityId = facility.id,
        kind = "region",
        role = "facility.footprint",
        region = region,
        tileCount = GridRegion.countTiles(region),
        revision = 0,
    } })
end

return Validation

