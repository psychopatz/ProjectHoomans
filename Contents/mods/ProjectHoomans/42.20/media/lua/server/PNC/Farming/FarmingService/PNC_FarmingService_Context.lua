-- Shared farming facility, plot, permission, and mutation helpers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
PNC.FarmingService.Internal = PNC.FarmingService.Internal or {}

local Service = PNC.FarmingService
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Research = PNC.FarmingResearch
local Adapter = PNC.PZFarmingAdapter
local Repository = PNC.SettlementRepository

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function facilityFor(value)
    return type(value) == "table" and value or Repository.GetFacility(value)
end

local function baseFor(facility)
    return facility and PNC.BaseService and PNC.BaseService.Get(facility.baseId) or nil
end

local function plotFor(facility, plotId)
    local plot = plotId and Repository.GetComponent(plotId) or nil
    return plot and plot.facilityId == facility.id
        and plot.role == Farming.PLOT_ROLE and plot or nil
end

local function plotsFor(facility)
    local output = {}
    for id, present in pairs(facility and facility.componentIds or {}) do
        local plot = present == true and Repository.GetComponent(id) or nil
        if plot and plot.role == Farming.PLOT_ROLE then output[#output + 1] = plot end
    end
    table.sort(output, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return output
end

local function isBuilt(facility)
    return facility and (facility.constructionState == nil
        or facility.constructionState == "BUILT")
end

local function permission(player, facility)
    local base = baseFor(facility)
    return base and PNC.BaseValidationService.CanUse(player, base), base
end

local function touch(facility)
    if PNC.FacilityService and PNC.FacilityService.RefreshState then
        return PNC.FacilityService.RefreshState(facility)
    end
    Repository.MarkDirty()
    return true
end

local function updatePlotConfiguration(player, args, update)
    args = type(args) == "table" and args or {}
    local facility = facilityFor(args.facilityId)
    local allowed, base = permission(player, facility)
    if not facility or not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not allowed then return { ok = false, reason = "NO_PERMISSION" } end
    if not isBuilt(facility) then return { ok = false, reason = "FACILITY_NOT_BUILT" } end
    if args.expectedRevision ~= nil
        and tonumber(args.expectedRevision) ~= tonumber(facility.revision)
    then return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision } end
    local plot = plotFor(facility, args.plotId)
    if not plot then return { ok = false, reason = "GROWING_PLOT_NOT_FOUND" } end
    local ok, reason = update(plot, args)
    if not ok then return { ok = false, reason = reason } end
    plot.schemaVersion = Farming.SCHEMA_VERSION
    plot.logicalType = Farming.PLOT_TYPE
    touch(facility)
    return { ok = true, facility = facility, plot = plot,
        event = "GrowingPlotConfigurationChanged" }
end

local Internal = Service.Internal
Internal.Copy = copy
Internal.FacilityFor = facilityFor
Internal.BaseFor = baseFor
Internal.PlotFor = plotFor
Internal.PlotsFor = plotsFor
Internal.IsBuilt = isBuilt
Internal.Permission = permission
Internal.Touch = touch
Internal.UpdatePlotConfiguration = updatePlotConfiguration

return Internal
