if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.FacilityValidationService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Farming = PNC.Farming
local H = Validation.Internal

function H.Result(ok, reason, details)
    return { ok = ok == true, reason = reason, details = details }
end

function H.LevelDefinition(facility, targetLevel)
    return Definitions.GetLevel(facility.definitionId, targetLevel or facility.level)
end

function H.ComponentStats(facility, replacingId, candidate)
    local counts, tiles = {}, {}
    for componentId, present in pairs(facility.componentIds or {}) do
        if present == true and componentId ~= replacingId then
            local component = Repository.GetComponent(componentId)
            if component then
                counts[component.role] = (counts[component.role] or 0) + 1
                tiles[component.role] = (tiles[component.role] or 0)
                    + (tonumber(component.tileCount) or 0)
            end
        end
    end
    if candidate then
        counts[candidate.role] = (counts[candidate.role] or 0) + 1
        tiles[candidate.role] = (tiles[candidate.role] or 0)
            + (tonumber(candidate.tileCount) or 0)
    end
    return counts, tiles
end

function H.BaseContainsRegion(base, region)
    local baseZone = base and Zones.get(base.baseZoneId)
    if not baseZone then return false end
    local footprint = PNC.BaseValidationService.ProjectFootprint(region)
    return GridRegion.containsRegion(baseZone.geometry, footprint)
end

function H.FacilityContainsRegion(facility, region)
    return facility and facility.constructionRegion
        and GridRegion.containsRegion(facility.constructionRegion, region)
end

function H.ExistingStockpile(base, builtOnly)
    for facilityId, present in pairs(base and base.facilityIds or {}) do
        local facility = present == true and Repository.GetFacility(facilityId)
            or nil
        if facility and facility.definitionId == "stockpile"
            and (not builtOnly or facility.constructionState == "BUILT")
        then
            return facility
        end
    end
    return nil
end

function Validation.GetStockpile(base, builtOnly)
    return H.ExistingStockpile(base, builtOnly == true)
end

function Validation.CanCreate(base, definitionId, level)
    local definition = Definitions.Get(definitionId)
    local levelData = definition and Definitions.GetLevel(definitionId, level or 1)
    if not definition or not levelData then return H.Result(false, "UNKNOWN_FACILITY") end
    if definition.singleton == true and H.ExistingStockpile(base, false) then
        return H.Result(false, "STOCKPILE_ALREADY_EXISTS")
    end
    if definitionId ~= "stockpile" and not H.ExistingStockpile(base, true) then
        return H.Result(false, "STOCKPILE_REQUIRED")
    end
    if (tonumber(base and base.hqLevel) or 0) < levelData.requiredHQLevel then
        return H.Result(false, "HQ_LEVEL_TOO_LOW")
    end
    if definition.requiredTechnology
        and (not PNC.ResearchService
            or not PNC.ResearchService.Queries.HasTechnology(
                base.colonyId, definition.requiredTechnology))
    then
        return H.Result(false, "TECHNOLOGY_REQUIRED", {
            technologyId = definition.requiredTechnology,
        })
    end
    return H.Result(true)
end

function Validation.CanUpgrade(base, facility, expectedRevision)
    if not facility then return H.Result(false, "FACILITY_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= facility.revision then
        return H.Result(false, "REVISION_CONFLICT", { revision = facility.revision })
    end
    local nextLevel = H.LevelDefinition(facility, facility.level + 1)
    if not nextLevel then return H.Result(false, "MAX_LEVEL") end
    if base.hqLevel < nextLevel.requiredHQLevel then
        return H.Result(false, "HQ_LEVEL_TOO_LOW")
    end
    if nextLevel.requiredTechnology
        and (not PNC.ResearchService
            or not PNC.ResearchService.Queries.HasTechnology(
                base.colonyId, nextLevel.requiredTechnology))
    then return H.Result(false, "TECHNOLOGY_REQUIRED", {
        technologyId = nextLevel.requiredTechnology }) end
    return H.Result(true)
end

return Validation

