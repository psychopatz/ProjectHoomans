-- Farming plot inspection and facility snapshots.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Adapter = PNC.PZFarmingAdapter
local copy = Internal.Copy
local facilityFor = Internal.FacilityFor
local plotsFor = Internal.PlotsFor

function Service.InspectPlot(plot)
    if not plot then return nil, "GROWING_PLOT_NOT_FOUND" end
    return Adapter.InspectPlot(plot)
end

function Service.BuildFacilitySnapshot(facility)
    facility = facilityFor(facility)
    if not facility or facility.definitionId ~= Farming.FACILITY_ID then return nil end
    local plots = plotsFor(facility)
    local output = {
        schemaVersion = Farming.SCHEMA_VERSION,
        logicalType = Farming.FACILITY_TYPE,
        plotSlots = (PNC.FacilityDefinitions.GetLevel(
            facility.definitionId, facility.level).componentLimits[Farming.PLOT_ROLE]
            or {}).maxCount or 0,
        plots = {},
    }
    for _, plot in ipairs(plots) do
        local info = Farming.RectangleInfo(plot.region)
        local inspection = Adapter.InspectPlot(plot)
        local row = {
            id = plot.id, schemaVersion = Farming.SCHEMA_VERSION,
            logicalType = Farming.PLOT_TYPE,
            desiredCrop = plot.desiredCrop,
            policy = copy(Farming.NormalizePolicy(plot.policy)),
            width = info and info.width or plot.width,
            height = info and info.height or plot.height,
            tileCount = plot.tileCount,
            status = inspection and inspection.status or "WAITING_FOR_WORLD",
            diagnostics = inspection and copy(inspection) or nil,
        }
        output.plots[#output.plots + 1] = row
    end
    return output
end

function Service.HasConfiguredWork(facility)
    for _, plot in ipairs(plotsFor(facility)) do
        if plot.desiredCrop and Catalog.Get(plot.desiredCrop) then return true end
    end
    return false
end

---Ensures deterministic abstract tile entries for unloaded zone or plot progression.
function Internal.EnsureAbstractTiles(target)
    if type(target) ~= "table" then return {} end
    if type(target.abstractTiles) == "table" and #target.abstractTiles > 0 then
        return target.abstractTiles
    end
    local ok, _, info = false, nil, nil
    if Farming and Farming.ZoneInfo then
        ok, _, info = Farming.ZoneInfo(target)
    elseif Farming and Farming.RectangleInfo and target.region then
        ok, _, info = Farming.RectangleInfo(target.region)
    end
    local tiles = {}
    if ok and info then
        for y = info.minY, info.maxY do
            for x = info.minX, info.maxX do
                tiles[#tiles + 1] = {
                    x = x, y = y, z = info.z,
                    state = "unplowed", waterLvl = 0, nbOfGrow = 0, plantedAt = 0,
                }
            end
        end
    end
    target.abstractTiles = tiles
    return tiles
end

---Returns true when abstract tile state contains at least one actionable crop step.
function Internal.HasActionableAbstractTiles(target)
    if not target then return false end
    local entry = target.desiredCrop and Catalog and Catalog.Get
        and Catalog.Get(target.desiredCrop) or nil
    if not entry then return false end
    local policy = Farming.NormalizePolicy(target.policy)
    for _, tile in ipairs(Internal.EnsureAbstractTiles(target)) do
        local st = tostring(tile.state or "unplowed")
        if st == "unplowed" and policy.autoPlow then return true end
        if st == "plow" and policy.autoPlant then return true end
        if st == "seeded" then
            if tile.canHarvest == true and policy.autoHarvest then return true end
            if (tonumber(tile.waterLvl) or 0) < 100 and policy.autoWater then return true end
        end
    end
    return false
end

---Inspects a farming zone, returning world inspection when loaded or abstract state otherwise.
function Service.InspectZone(zone)
    zone = type(zone) == "table" and zone or (Service.GetZone and Service.GetZone(zone))
    if not zone then return nil, "FARM_ZONE_NOT_FOUND" end
    if Adapter and Adapter.InspectZone then
        local live = Adapter.InspectZone(zone, { policy = zone.policy })
        if live and live.available == true then return live end
    end
    local entry = zone.desiredCrop and Catalog and Catalog.Get and Catalog.Get(zone.desiredCrop)
    local result = {
        available = false, abstract = true, status = "WAITING_FOR_CROP_STATE",
        tileCount = 0, furrows = 0, empty = 0, needsSeed = 0, needsPlow = 0,
        planted = 0, harvestable = 0, needsWater = 0, blocked = 0, tiles = {},
        hasActionable = false,
    }
    for _, tile in ipairs(Internal.EnsureAbstractTiles(zone)) do
        result.tileCount = result.tileCount + 1
        local st = tostring(tile.state or "unplowed")
        if st == "unplowed" then result.needsPlow = result.needsPlow + 1
        elseif st == "plow" then
            result.furrows, result.empty, result.needsSeed =
                result.furrows + 1, result.empty + 1, result.needsSeed + 1
        elseif st == "seeded" then
            result.planted = result.planted + 1
            if tile.canHarvest == true then result.harvestable = result.harvestable + 1
            elseif (tonumber(tile.waterLvl) or 0) < 100 then
                result.needsWater = result.needsWater + 1
            end
        end
        result.tiles[#result.tiles + 1] = tile
    end
    result.hasActionable = entry ~= nil and Internal.HasActionableAbstractTiles(zone)
    return result
end

---Returns true when a zone or plot has configured crop and actionable tiles.
function Service.HasActionableWork(target)
    if not target or target.enabled == false then return false, nil end
    if not target.desiredCrop or not Catalog or not Catalog.Get
        or not Catalog.Get(target.desiredCrop)
    then
        return false, nil
    end
    local inspection = Adapter and Adapter.InspectPlot
        and Adapter.InspectPlot(target, { policy = target.policy }) or nil
    if inspection and inspection.available == true then
        return inspection.hasActionable == true, inspection
    end
    return Internal.HasActionableAbstractTiles(target), Service.InspectZone(target)
end

return Service
