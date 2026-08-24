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

return Service
