-- Farming configuration and debug commands.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Research = PNC.FarmingResearch
local Adapter = PNC.PZFarmingAdapter
local facilityFor = Internal.FacilityFor
local plotFor = Internal.PlotFor
local isBuilt = Internal.IsBuilt
local permission = Internal.Permission
local touch = Internal.Touch
local updatePlotConfiguration = Internal.UpdatePlotConfiguration

function Service.SetDesiredCrop(player, args)
    return updatePlotConfiguration(player, args, function(plot, input)
        local crop = Farming.NormalizeCrop(input.desiredCrop)
        if not crop then return false, "CROP_REQUIRED" end
        if not Catalog.Get(crop) then return false, "UNKNOWN_CROP" end
        if crop ~= plot.desiredCrop and Adapter.ClearPlot then
            local cleared, reason = Adapter.ClearPlot(plot)
            if not cleared and reason ~= "FARMING_SYSTEM_UNAVAILABLE" then
                return false, "PLOT_CLEANUP_FAILED_" .. tostring(reason)
            end
        end
        plot.desiredCrop = crop
        return true
    end)
end

function Service.SetPolicy(player, args)
    return updatePlotConfiguration(player, args, function(plot, input)
        plot.policy = Farming.NormalizePolicy(input.policy)
        return true
    end)
end

local function debugAllowed(player)
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
end

function Service.DebugPlot(player, args)
    args = type(args) == "table" and args or {}
    if not debugAllowed(player) then return { ok = false, reason = "DEBUG_REQUIRED" } end
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
    local action = tostring(args.debugAction or "")
    local ok, reason, details
    if action == "grow" or action == "fast_growth" then
        ok, reason, details = Adapter.ForceGrowPlot(plot)
    elseif action == "water" then
        ok, reason, details = Adapter.ForceWaterPlot(plot)
    elseif action == "harvest" then
        ok, reason, details = Adapter.HarvestPlot(plot, player)
    elseif action == "clear" then
        ok, reason, details = Adapter.ClearPlot(plot)
    elseif Research and Research.NormalizeEffect
        and Research.NormalizeEffect(action)
    then
        ok, reason, details = Adapter.ApplyResearchEffect(plot, action, player)
    else
        return { ok = false, reason = "UNKNOWN_FARMING_DEBUG_ACTION" }
    end
    if not ok then return { ok = false, reason = reason or "FARMING_DEBUG_FAILED" } end
    touch(facility)
    return { ok = true, reason = reason, details = details,
        facility = facility, plot = plot, event = "GrowingPlotDebugChanged" }
end

return Service
