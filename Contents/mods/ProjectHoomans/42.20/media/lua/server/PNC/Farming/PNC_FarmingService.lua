if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}

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
    local service = PNC.ColonyStorageService
    local internal = service and service.Internal
    return internal and internal.DebugAllowed
        and internal.DebugAllowed(player) == true
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

local function storageFor(facility)
    local base = baseFor(facility)
    if not base or not PNC.ColonyStorageRepository
        or not PNC.ColonyStorageRepository.GetPrimary
    then return nil end
    return PNC.ColonyStorageRepository.GetPrimary(base.factionId, base.colonyId)
end

local function retrieveMaterial(record, facility, itemTypes, runtime)
    if runtime and runtime.lastMaterialAttemptAt
        and PNC.Core.Now() - runtime.lastMaterialAttemptAt < 10000
    then return false, "MATERIAL_RETRY_DELAY" end
    if not record or not facility or not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReserveProductionMaterials
        or not PNC.ColonyStorageService.CollectProductionReservation
    then return false, "MATERIAL_RETRIEVAL_UNAVAILABLE" end
    local storage = storageFor(facility)
    if not storage then return false, "STORAGE_NOT_FOUND" end
    runtime.lastMaterialAttemptAt = PNC.Core.Now()
    local reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        storage.id, {{ itemTypes = itemTypes, amount = 1 }},
        "farming:" .. tostring(facility.id))
    if not reservation then return false, reason or "MATERIALS_NOT_AVAILABLE" end
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        reservation.id, "farming:" .. tostring(facility.id), "FARMING",
        storage.id, record)
    if not ok then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return false, details or "MATERIAL_RETRIEVAL_FAILED"
    end
    return true, "MATERIAL_RETRIEVED"
end

local function ensureSeed(record, facility, entry, runtime)
    local itemID = Adapter.FindSeed(record, nil, entry)
    if itemID then return true end
    return retrieveMaterial(record, facility, entry.seedTypes, runtime)
end

local function storageWaterTypes(storage)
    local output, seen = {}, {}
    local inventory = storage and storage.inventory
    local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
    for _, itemRecord in ipairs(inventory and inventory.records or {}) do
        local item = CoreInventory.decodeItem(itemRecord)
        local fullType = item and item.getFullType and item:getFullType() or nil
        if fullType and Adapter.IsWaterItem and Adapter.IsWaterItem(item)
            and not seen[fullType]
        then
            seen[fullType] = true
            output[#output + 1] = fullType
        end
    end
    return output
end

local function ensureWater(record, facility, runtime, body)
    if Adapter.FindWater(record, body) then return true end
    local storage = storageFor(facility)
    local types = storageWaterTypes(storage)
    if #types <= 0 then return false, "WATER_MATERIAL_MISSING" end
    return retrieveMaterial(record, facility, types, runtime)
end

local function operation(record, body, facility, plot, runtime, tile, inspection)
    local policy = Farming.NormalizePolicy(plot.policy)
    local desired = plot.desiredCrop
    if not desired then return false, "NO_CROP_ASSIGNED" end
    local entry = Catalog.Get(desired)
    if not entry then return false, "UNKNOWN_CROP" end
    if policy.autoHarvest and tile.status == "HARVESTABLE" then
        return Adapter.Harvest(record, body, tile)
    end
    local tileKey = tostring(tile.x) .. ":" .. tostring(tile.y) .. ":" .. tostring(tile.z)
    if policy.autoPlant and tile.status == "EMPTY_FURROW"
        and (not runtime.harvestedTiles or runtime.harvestedTiles[tileKey] ~= true
            or policy.autoReplant)
        and (inspection.empty > 0)
    then
        local supplied, reason = ensureSeed(record, facility, entry, runtime)
        if not supplied then return false, reason end
        return Adapter.Plant(record, body, plot, tile, desired)
    end
    if policy.autoWater and tile.status == "NEEDS_WATER" then
        local supplied, reason = ensureWater(record, facility, runtime, body)
        if not supplied then return false, reason end
        return Adapter.Water(record, body, tile)
    end
    return false, "NO_ACTION"
end

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

local Provider = {}

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function isFarmer(record)
    local affiliation = record and record.affiliation or {}
    local role = tostring(affiliation.role or affiliation.communityRole or "")
    return role == "farmer" or record and record.job == "Farmer"
end

function Provider.GetCandidates(npcId)
    local record = recordFor(npcId)
    if not record or record.alive == false or not isFarmer(record)
        or record.allowedJobs and record.allowedJobs[Farming.FARMER_JOB] == false
    then return {} end
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
    if not base then return {} end
    local output = {}
    for _, facility in ipairs(PNC.FacilityService.ListByCapability(
        base.id, "farm.work") or {}) do
        if Service.HasConfiguredWork(facility)
            and PNC.FacilityReservations.HasCapacity(facility, "farm.work")
        then
            output[#output + 1] = {
                taskId = "farm:" .. tostring(facility.id) .. ":" .. tostring(record.id),
                npcId = tostring(record.id), kind = "FARM_MAINTENANCE",
                sourceDomain = "farming", sourceRef = facility.id,
                precedence = "NORMAL_WORK", urgency = 0.35,
                capability = "farm.work", revision = facility.revision,
            }
        end
    end
    return output
end

function Provider.Validate(intent)
    local record = recordFor(intent and intent.npcId)
    local facility = intent and Repository.GetFacility(intent.sourceRef)
    return record ~= nil and record.alive ~= false and facility ~= nil
        and Service.HasConfiguredWork(facility)
end

function Provider.Assign(intent)
    local record = recordFor(intent.npcId)
    local facility = Repository.GetFacility(intent.sourceRef)
    local base = baseFor(facility)
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        "farm.work", { ttlMs = 30000, abstract = live == nil,
            deferWorldValidation = true })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Provider.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        "farm.work", { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then PNC.TaskLeaseService.SetPhase(lease.leaseId,
        lease.executionMode == "LIVE" and "TRAVEL" or "WAITING_FOR_WORLD") end
    return ok, reason
end

function Provider.CanContinue(lease)
    local facility = Repository.GetFacility(lease and lease.facilityId)
    local record = recordFor(lease and lease.npcId)
    if not facility or not record or record.alive == false
        or not Repository.GetComponent(lease.componentId)
    then return false end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    return (lease.executionMode == "LIVE") == (live ~= nil)
end

function Provider.Tick(lease)
    local record = recordFor(lease.npcId)
    if not record then return false end
    if lease.executionMode == "ABSTRACT" then Service.TickAbstract(record, lease) end
    return true
end

function Provider.Cancel(lease)
    local record = recordFor(lease and lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        record.runtime.facilityActivity.reservationId = ""
        PNC.FacilityJobs.Stop(record, "farming_task_cancelled")
    end
    return true
end

function Provider.Complete(lease)
    return Provider.Cancel(lease)
end

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("farming", Provider)
end

return Service
