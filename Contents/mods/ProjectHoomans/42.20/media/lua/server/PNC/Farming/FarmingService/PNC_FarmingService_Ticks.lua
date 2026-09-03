-- Live and abstract farming activity ticks.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Catalog = PNC.FarmingCatalog
local Adapter = PNC.PZFarmingAdapter
local facilityFor = Internal.FacilityFor
local plotFor = Internal.PlotFor
local operation = Internal.Operation

function Service.TickLive(record, body, runtime, now)
    if not runtime or runtime.capability ~= "farm.work" then return true end
    now = tonumber(now) or PNC.Core.Now()
    if now < (tonumber(runtime.nextFarmingOperationAt) or 0) then return true end
    local facility = facilityFor(runtime.facilityId)
    local plot = facility and plotFor(facility, runtime.componentId) or nil
    if not facility or not plot then
        runtime.failedReason = "GROWING_PLOT_NOT_FOUND"
        runtime.completionRequested = true
        return false
    end
    if not body then
        runtime.phase = "WAITING_FOR_WORLD"
        runtime.nextFarmingOperationAt = now + 5000
        return true
    end
    local inspection = Adapter.InspectPlot(plot)
    runtime.farmingStatus = inspection and inspection.status or "WAITING_FOR_WORLD"
    if not inspection or inspection.available ~= true then
        runtime.phase = "WAITING_FOR_WORLD"
        runtime.nextFarmingOperationAt = now + 5000
        return true
    end
    if not plot.desiredCrop or not Catalog.Get(plot.desiredCrop) then
        runtime.phase = "NO_CROP_ASSIGNED"
        runtime.completionRequested = true
        return false
    end
    for _, tile in ipairs(inspection.tiles or {}) do
        local ok, reason = operation(record, body, facility, plot, runtime,
            tile, inspection)
        if ok then
            runtime.phase = "WORKING"
            runtime.lastFarmingOperation = reason
            if PNC.FacilityJobs and PNC.FacilityJobs.RecordProgress then
                PNC.FacilityJobs.RecordProgress(record, now,
                    "farming_" .. tostring(reason or "operation"))
            end
            if reason == "HARVESTED" then
                runtime.harvestedTiles = runtime.harvestedTiles or {}
                runtime.harvestedTiles[tostring(tile.x) .. ":"
                    .. tostring(tile.y) .. ":" .. tostring(tile.z)] = true
            end
            runtime.nextFarmingOperationAt = now + 1200
            return true
        end
        if reason ~= "NO_ACTION" and reason ~= "PLANT_DOES_NOT_NEED_WATER"
            and reason ~= "FURROW_NOT_PLANTABLE"
        then
            if reason == "WATER_MATERIAL_MISSING" or reason == "SEED_MATERIAL_MISSING" then
                runtime.phase = "WAITING_FOR_MATERIALS"
            else
                runtime.phase = "WAITING_FOR_CROP_STATE"
            end
            runtime.lastFarmingReason = reason
            runtime.nextFarmingOperationAt = now + 10000
            return true
        end
    end
    runtime.phase = "WAITING_FOR_CROP_STATE"
    runtime.nextFarmingOperationAt = now + 10000
    return true
end

function Service.TickAbstract(record, lease)
    local runtime = record and record.runtime and record.runtime.facilityActivity
    if runtime then
        runtime.phase = "WAITING_FOR_WORLD"
        runtime.lastFarmingReason = "WAITING_FOR_WORLD"
    end
    return true
end

return Service
