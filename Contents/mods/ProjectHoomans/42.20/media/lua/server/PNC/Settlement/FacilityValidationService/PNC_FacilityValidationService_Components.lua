if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.FacilityValidationService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Farming = PNC.Farming
local H = Validation.Internal

local function regionTouchesFacility(facility, region)
    local footprint = facility and facility.constructionRegion
    if not footprint or not region then return false end
    if GridRegion.containsRegion(footprint, region) then return true end
    local normalized = GridRegion.normalize(region)
    for z, level in pairs(normalized.levels) do
        for y, spans in pairs(level.rows) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    if GridRegion.containsPoint(footprint, x - 1, y, z)
                        or GridRegion.containsPoint(footprint, x + 1, y, z)
                        or GridRegion.containsPoint(footprint, x, y - 1, z)
                        or GridRegion.containsPoint(footprint, x, y + 1, z)
                    then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function H.WorkZoneTouchesFacility(facility, region)
    return regionTouchesFacility(facility, region)
end

function Validation.NormalizeComponent(base, facility, input)
    if type(input) ~= "table" or (input.kind ~= "anchor"
        and input.kind ~= "region" and input.kind ~= "abstract")
        or type(input.role) ~= "string" or input.role == ""
    then
        return H.Result(false, "INVALID_COMPONENT")
    end
    local levelData = H.LevelDefinition(facility)
    local limit = Definitions.GetComponentLimit
        and Definitions.GetComponentLimit(facility.definitionId,
            facility.level, input.role)
        or levelData and levelData.componentLimits[input.role]
    if not limit or limit.kind ~= input.kind then
        return H.Result(false, "INVALID_COMPONENT_ROLE")
    end
    local component = {
        schemaVersion = 1, id = tostring(input.id or ""), facilityId = facility.id,
        kind = input.kind, role = input.role, revision = tonumber(input.revision) or 0,
        targetResolver = input.targetResolver and tostring(input.targetResolver) or nil,
        objectTag = input.objectTag and tostring(input.objectTag) or nil,
        worldRule = limit.worldRule and tostring(limit.worldRule) or nil,
        roomGroup = limit.roomGroup and tostring(limit.roomGroup) or nil,
    }
    if input.role == "growing.plot" then
        local valid, reason, info = Farming.RectangleInfo(input.region)
        if not valid then return H.Result(false, reason) end
        component.logicalType = Farming.PLOT_TYPE
        component.region = info.region
        component.tileCount = info.tileCount
        component.width, component.height = info.width, info.height
        component.desiredCrop = Farming.NormalizeCrop(input.desiredCrop)
        component.policy = Farming.NormalizePolicy(input.policy)
        if PNC.FarmingCatalog and component.desiredCrop
            and not PNC.FarmingCatalog.Get(component.desiredCrop)
        then
            return H.Result(false, "UNKNOWN_CROP")
        end
    end
    if input.kind == "anchor" and component.role == "sleep.bed" then
        component.targetResolver = "sleepSpot"
        component.objectTag = nil
        component.worldRule = nil
    end
    if input.kind == "abstract" then
        component.tileCount = 0
    elseif input.kind == "anchor" then
        component.x = math.floor(tonumber(input.x) or 0)
        component.y = math.floor(tonumber(input.y) or 0)
        component.z = math.floor(tonumber(input.z) or 0)
        component.tileCount = math.max(1,
            math.floor(tonumber(limit.fixedTileCount) or 1))
        local baseZone = Zones.get(base.baseZoneId)
        if not baseZone or not GridRegion.containsXY(baseZone.geometry,
            component.x, component.y)
        then
            return H.Result(false, "OUTSIDE_BASE")
        end
        if not facility.constructionRegion or not GridRegion.containsPoint(
            facility.constructionRegion, component.x, component.y, component.z)
        then
            return H.Result(false, "OUTSIDE_FACILITY")
        end
        if PNC.FacilityWorldValidation
            and PNC.FacilityWorldValidation.ValidateAnchor
        then
            local valid, worldReason = PNC.FacilityWorldValidation.ValidateAnchor(component)
            if valid ~= true then return H.Result(false, worldReason or "INVALID_TARGET") end
        end
    else
        local ok, reason, region = GridRegion.validate(input.region)
        if not ok then return H.Result(false, reason) end
        local levels = 0
        for _, _ in pairs(region.levels) do levels = levels + 1 end
        if levels ~= 1 then return H.Result(false, "FACILITY_REGION_MULTIPLE_LEVELS") end
        if not GridRegion.isConnected(region, 4) then
            return H.Result(false, "FACILITY_REGION_DISCONNECTED")
        end
        -- A stockpile can be relocated outside the base only after the
        -- initial facility has an established construction region. The first
        -- stockpile is still a facility creation and must remain inside the
        -- owning base territory.
        local movingStockpile = facility.definitionId == "stockpile"
            and input.role == "storage.stockpile"
            and facility.constructionRegion ~= nil
        -- Once established, the stockpile's physical storage area is
        -- intentionally mobile. It remains owned by this base, but its world
        -- region may be placed outside the base geometry. Other facility
        -- regions remain base-constrained; a separate facility.footprint is
        -- still validated by NormalizeFootprint.
        if not movingStockpile and not H.BaseContainsRegion(base, region) then
            return H.Result(false, "OUTSIDE_BASE")
        end
        if facility.constructionRegion and not movingStockpile then
            local connected = input.role == "work.zone"
                and regionTouchesFacility(facility, region)
                or H.FacilityContainsRegion(facility, region)
            if not connected then return H.Result(false, "OUTSIDE_FACILITY") end
        end
        if input.role ~= "growing.plot" then
            component.region = region
            component.tileCount = GridRegion.countTiles(region)
        end
        if movingStockpile then
            for facilityId, other in pairs(Repository.State.facilities or {}) do
                if facilityId ~= facility.id and other.constructionRegion
                    and GridRegion.intersects(region, other.constructionRegion)
                then
                    return H.Result(false, "OVERLAP_NOT_ALLOWED")
                end
            end
        end
        if PNC.FacilityWorldValidation
            and PNC.FacilityWorldValidation.ValidateRegion
        then
            local valid, worldReason = PNC.FacilityWorldValidation.ValidateRegion(component)
            if valid ~= true then
                return H.Result(false, worldReason or "INVALID_WORLD_SQUARE")
            end
        end
    end
    local counts, tiles = H.ComponentStats(facility, input.id, component)
    if limit.maxCount and counts[input.role] > limit.maxCount then
        return H.Result(false, "FACILITY_COMPONENT_LIMIT")
    end
    if limit.maxTotalTiles and tiles[input.role] > limit.maxTotalTiles then
        return H.Result(false, "FACILITY_AREA_TOO_LARGE")
    end
    if limit.minTotalTiles and tiles[input.role] < limit.minTotalTiles then
        return H.Result(false, "FACILITY_AREA_TOO_SMALL")
    end
    if component.region then
        for componentId, other in pairs(Repository.State.components) do
            if componentId ~= input.id and other.region
                and GridRegion.intersects(component.region, other.region)
            then
                local otherFacility = Repository.GetFacility(other.facilityId)
                local otherLevel = otherFacility and H.LevelDefinition(otherFacility)
                local otherLimit = otherLevel and otherLevel.componentLimits[other.role]
                local exclusive = limit.overlap == "exclusive"
                    and otherLimit and otherLimit.overlap == "exclusive"
                local roomCollision = component.roomGroup ~= nil
                    and otherLimit and otherLimit.roomGroup ~= nil
                if exclusive or roomCollision then
                    return H.Result(false, roomCollision
                        and "ROOM_COLLISION" or "OVERLAP_NOT_ALLOWED")
                end
            end
        end
    end
    return H.Result(true, nil, { component = component })
end

return Validation
