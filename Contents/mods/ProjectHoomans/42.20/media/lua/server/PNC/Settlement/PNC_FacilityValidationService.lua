if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityValidationService = PNC.FacilityValidationService or {}

local Validation = PNC.FacilityValidationService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function result(ok, reason, details)
    return { ok = ok == true, reason = reason, details = details }
end

local function levelDefinition(facility, targetLevel)
    return Definitions.GetLevel(facility.definitionId, targetLevel or facility.level)
end

local function componentStats(facility, replacingId, candidate)
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

local function baseContainsRegion(base, region)
    local baseZone = base and Zones.get(base.baseZoneId)
    if not baseZone then return false end
    local footprint = PNC.BaseValidationService.ProjectFootprint(region)
    return GridRegion.containsRegion(baseZone.geometry, footprint)
end

function Validation.CanCreate(base, definitionId, level)
    local definition = Definitions.Get(definitionId)
    local levelData = definition and Definitions.GetLevel(definitionId, level or 1)
    if not definition or not levelData then return result(false, "UNKNOWN_FACILITY") end
    if (tonumber(base and base.hqLevel) or 0) < levelData.requiredHQLevel then
        return result(false, "HQ_LEVEL_TOO_LOW")
    end
    if definition.requiredTechnology
        and (not PNC.ResearchService
            or not PNC.ResearchService.Queries.HasTechnology(
                base.colonyId, definition.requiredTechnology))
    then
        return result(false, "TECHNOLOGY_REQUIRED", {
            technologyId = definition.requiredTechnology,
        })
    end
    return result(true)
end

function Validation.CanUpgrade(base, facility, expectedRevision)
    if not facility then return result(false, "FACILITY_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= facility.revision then
        return result(false, "REVISION_CONFLICT", { revision = facility.revision })
    end
    local nextLevel = levelDefinition(facility, facility.level + 1)
    if not nextLevel then return result(false, "MAX_LEVEL") end
    if base.hqLevel < nextLevel.requiredHQLevel then
        return result(false, "HQ_LEVEL_TOO_LOW")
    end
    return result(true)
end

function Validation.NormalizeFootprint(base, facility, input)
    if type(input) ~= "table" or input.kind ~= "region" then
        return result(false, "INVALID_COMPONENT")
    end
    local ok, reason, region = GridRegion.validate(input.region)
    if not ok then return result(false, reason) end
    local levels = 0
    for _, _ in pairs(region.levels) do levels = levels + 1 end
    if levels ~= 1 then
        return result(false, "FACILITY_REGION_MULTIPLE_LEVELS")
    end
    if not GridRegion.isConnected(region, 4) then
        return result(false, "FACILITY_REGION_DISCONNECTED")
    end
    if not baseContainsRegion(base, region) then
        return result(false, "OUTSIDE_BASE")
    end
    return result(true, nil, { component = {
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

function Validation.NormalizeComponent(base, facility, input)
    if type(input) ~= "table" or (input.kind ~= "anchor" and input.kind ~= "region")
        or type(input.role) ~= "string" or input.role == ""
    then
        return result(false, "INVALID_COMPONENT")
    end
    local levelData = levelDefinition(facility)
    local limit = levelData and levelData.componentLimits[input.role]
    if not limit or limit.kind ~= input.kind then
        return result(false, "INVALID_COMPONENT_ROLE")
    end
    local component = {
        schemaVersion = 1, id = tostring(input.id or ""), facilityId = facility.id,
        kind = input.kind, role = input.role, revision = tonumber(input.revision) or 0,
        targetResolver = input.targetResolver and tostring(input.targetResolver) or nil,
        objectTag = input.objectTag and tostring(input.objectTag) or nil,
        worldRule = limit.worldRule and tostring(limit.worldRule) or nil,
    }
    if input.kind == "anchor" and component.role == "sleep.bed" then
        component.targetResolver = "sleepSpot"
        component.objectTag = nil
        component.worldRule = nil
    end
    if input.kind == "anchor" then
        component.x = math.floor(tonumber(input.x) or 0)
        component.y = math.floor(tonumber(input.y) or 0)
        component.z = math.floor(tonumber(input.z) or 0)
        component.tileCount = 0
        local baseZone = Zones.get(base.baseZoneId)
        if not baseZone or not GridRegion.containsXY(baseZone.geometry,
            component.x, component.y)
        then
            return result(false, "OUTSIDE_BASE")
        end
        if PNC.FacilityWorldValidation
            and PNC.FacilityWorldValidation.ValidateAnchor
        then
            local valid, worldReason = PNC.FacilityWorldValidation.ValidateAnchor(component)
            if valid ~= true then return result(false, worldReason or "INVALID_TARGET") end
        end
    else
        local ok, reason, region = GridRegion.validate(input.region)
        if not ok then return result(false, reason) end
        local levels = 0
        for _, _ in pairs(region.levels) do levels = levels + 1 end
        if levels ~= 1 then return result(false, "FACILITY_REGION_MULTIPLE_LEVELS") end
        if not GridRegion.isConnected(region, 4) then
            return result(false, "FACILITY_REGION_DISCONNECTED")
        end
        if not baseContainsRegion(base, region) then return result(false, "OUTSIDE_BASE") end
        component.region = region
        component.tileCount = GridRegion.countTiles(region)
        if PNC.FacilityWorldValidation
            and PNC.FacilityWorldValidation.ValidateRegion
        then
            local valid, worldReason = PNC.FacilityWorldValidation.ValidateRegion(component)
            if valid ~= true then
                return result(false, worldReason or "INVALID_WORLD_SQUARE")
            end
        end
    end
    local counts, tiles = componentStats(facility, input.id, component)
    if limit.maxCount and counts[input.role] > limit.maxCount then
        return result(false, "FACILITY_COMPONENT_LIMIT")
    end
    if limit.maxTotalTiles and tiles[input.role] > limit.maxTotalTiles then
        return result(false, "FACILITY_AREA_TOO_LARGE")
    end
    if limit.minTotalTiles and tiles[input.role] < limit.minTotalTiles then
        return result(false, "FACILITY_AREA_TOO_SMALL")
    end
    if limit.overlap == "exclusive" and component.region then
        for componentId, other in pairs(Repository.State.components) do
            if componentId ~= input.id and other.region
                and GridRegion.intersects(component.region, other.region)
            then
                local otherFacility = Repository.GetFacility(other.facilityId)
                local otherLevel = otherFacility and levelDefinition(otherFacility)
                local otherLimit = otherLevel and otherLevel.componentLimits[other.role]
                if otherLimit and otherLimit.overlap == "exclusive" then
                    return result(false, "OVERLAP_NOT_ALLOWED")
                end
            end
        end
    end
    return result(true, nil, { component = component })
end

function Validation.CalculateOperationalState(base, facility)
    if facility.disabled == true then return "DISABLED" end
    local levelData = levelDefinition(facility)
    if not levelData or base.hqLevel < levelData.requiredHQLevel then return "INVALID_COMPONENT" end
    local counts, tiles = componentStats(facility)
    for role, limit in pairs(levelData.componentLimits or {}) do
        if limit.minCount and (counts[role] or 0) < limit.minCount then
            return "NEEDS_ASSIGNMENT"
        end
        if limit.minTotalTiles and (tiles[role] or 0) < limit.minTotalTiles then
            return "UNDERSIZED"
        end
        if limit.maxCount and (counts[role] or 0) > limit.maxCount then
            return "INVALID_COMPONENT"
        end
        if limit.maxTotalTiles and (tiles[role] or 0) > limit.maxTotalTiles then
            return "INVALID_COMPONENT"
        end
    end
    return "OPERATIONAL"
end

return Validation
