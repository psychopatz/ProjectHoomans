if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.BaseValidationService
local H = Validation.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

function Validation.CanBuildBarricade(base, expectedRevision)
    if not base then return H.Result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return H.Result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    local rawNext = Definitions.STARTING_TERRITORY
        + (base.barricadeCount + 1) * Definitions.TILES_PER_BARRICADE
    local limit = Definitions.GetTerritoryLimit(base.hqLevel)
    if rawNext > limit then return H.Result(false, "HQ_TERRITORY_LIMIT") end
    return H.Result(true)
end

function Validation.CanUpgradeHQ(base, expectedRevision)
    if not base then return H.Result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return H.Result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    if not Definitions.GetHQLevel(base.hqLevel + 1) then
        return H.Result(false, "MAX_LEVEL")
    end
    local technologyId = "hq:" .. tostring(base.hqLevel + 1)
    if not PNC.ResearchService
        or not PNC.ResearchService.Queries.HasTechnology(
            base.colonyId, technologyId)
    then
        return H.Result(false, "TECHNOLOGY_REQUIRED", {
            technologyId = technologyId,
        })
    end
    return H.Result(true)
end
