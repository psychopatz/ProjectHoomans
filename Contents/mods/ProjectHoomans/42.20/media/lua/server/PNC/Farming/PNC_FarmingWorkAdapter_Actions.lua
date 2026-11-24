-- Farming live stockpile collection, animation, tile cultivation, and harvest capture.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingWorkAdapter = PNC.FarmingWorkAdapter or {}
PNC.FarmingWorkAdapter.Internal = PNC.FarmingWorkAdapter.Internal or {}

local Internal = PNC.FarmingWorkAdapter.Internal
local Service = PNC.FarmingService
local FarmingAdapter = PNC.PZFarmingAdapter

function Internal.SyncOrderTarget(order, worker, pos)
    if type(pos) ~= "table" then return end
    if type(order) == "table" then
        order.target = { x = pos.x, y = pos.y, z = pos.z or 0 }
    end
    if type(worker and worker.orderSpec) == "table" then
        worker.orderSpec.x, worker.orderSpec.y, worker.orderSpec.z =
            pos.x, pos.y, pos.z or 0
    end
end

local function inventorySnapshot(record)
    local counts = {}
    local inv = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or (record and record.inventory)
    for _, item in pairs(inv and inv.items or {}) do
        local ft = tostring(item.type or "")
        if ft ~= "" then
            counts[ft] = (counts[ft] or 0) + math.max(0, math.floor(tonumber(item.stack) or 0))
        end
    end
    return counts
end

local function diffHarvestItems(before, after)
    local gained = {}
    for ft, qty in pairs(after or {}) do
        local delta = (tonumber(qty) or 0) - (tonumber(before and before[ft]) or 0)
        if delta > 0 then gained[#gained + 1] = { fullType = ft, quantity = delta } end
    end
    return gained
end

local function oneShotFarmAnimation(order, record, body, sceneId, reason)
    if not PNC.AnimationScenes or type(PNC.AnimationScenes.Request) ~= "function" then
        return "completed"
    end
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    if scene and tostring(scene.id or "") == tostring(sceneId) then
        order._farmAnimRequested = sceneId
        return "running"
    end
    local last = runtime and runtime.lastAnimationScene or nil
    if order._farmAnimRequested == sceneId and last
        and tostring(last.id or "") == tostring(sceneId)
        and tostring(last.reason or "") == "completed"
    then
        order._farmAnimRequested = nil
        return "completed"
    end
    local started = PNC.AnimationScenes.Request(record, body, sceneId, {
        reason = reason, repeatMode = "once",
    })
    if started == false then return "failed" end
    order._farmAnimRequested = sceneId
    return "started"
end

function Internal.CollectStockpileInputs(order, worker, body, target, reqs, tag, now)
    local inputService = PNC.WorkInputService
    local storage = Service.Internal.StorageFor and Service.Internal.StorageFor(target) or nil
    if not storage and PNC.ColonyStorageRepository and PNC.ColonyStorageRepository.GetPrimary then
        storage = PNC.ColonyStorageRepository.GetPrimary(order.factionId, order.colonyId)
    end
    if not storage or not PNC.ColonyStorageService then
        return false, "FARMING_STORAGE_UNAVAILABLE"
    end
    if inputService and (not order.payload or not order.payload.input) then
        local res, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
            storage.id, reqs, order.id)
        if not res then return false, reason or "FARMING_MATERIALS_MISSING" end
        order.payload = order.payload or {}
        inputService.Bind(order.payload, storage.id, res.id, "farming_" .. tostring(tag))
    elseif not inputService then
        return false, "WORK_INPUT_SERVICE_UNAVAILABLE"
    end
    local node = PNC.StockpileAccessService and PNC.StockpileAccessService.FindNearest
        and PNC.StockpileAccessService.FindNearest(worker, storage) or nil
    local dest = node or storage.access or { x = worker.x, y = worker.y, z = worker.z or 0 }
    Internal.SyncOrderTarget(order, worker, dest)
    if PNC.WorkToilRunner and PNC.WorkToilRunner.ObserveLiveApproach then
        local status = PNC.WorkToilRunner.ObserveLiveApproach(
            worker, body, "farm_stockpile:" .. tostring(order.id), dest, now, {
                watchSlot = "farming_input", moveReason = "farm_inputs",
                arriveDistance = 1.4,
            })
        if status == "stalled" then return false, "STOCKPILE_UNREACHABLE" end
        if status ~= "arrived" then return "traveling", nil end
    end
    local anim = oneShotFarmAnimation(order, worker, body, "work.grab", "farm_input_grab")
    if anim ~= "completed" then return "animating", nil end
    local ok, reason = inputService.Collect(order, worker)
    if not ok then return false, reason or "INPUT_COLLECT_FAILED" end
    order.payload.input = nil
    return true, nil
end

local FARM_XP = {
    PLOW = 2,
    PLANT = 4,
    WATER = 2,
    HARVEST = 10,
}

local function awardFarmingXP(worker, action)
    local amount = FARM_XP[action]
    if amount and worker and PNC.Skills and PNC.Skills.AddXP then
        PNC.Skills.AddXP(worker, "Agriculture", amount)
    end
end

function Internal.PerformTileAction(order, worker, body, target, tile, action)
    local anim = oneShotFarmAnimation(
        order, worker, body, "facility.farm.work", "farm_" .. string.lower(action))
    if anim ~= "completed" then return "animating", nil end
    if action == "PLOW" then
        local ok, reason = FarmingAdapter.Plow(worker, body, tile)
        if ok then awardFarmingXP(worker, "PLOW") end
        return ok, reason
    elseif action == "PLANT" then
        local ok, reason = FarmingAdapter.Plant(worker, body, target, tile, target.desiredCrop)
        if ok then awardFarmingXP(worker, "PLANT") end
        return ok, reason
    elseif action == "WATER" then
        local ok, reason = FarmingAdapter.Water(worker, body, tile)
        if ok then awardFarmingXP(worker, "WATER") end
        return ok, reason
    elseif action == "HARVEST" then
        local beforeInv = inventorySnapshot(worker)
        local cell = getCell and getCell() or nil
        local sq = cell and cell.getGridSquare and cell:getGridSquare(tile.x, tile.y, tile.z) or nil
        local beforeGround = PNC.WorkOutputService and sq
            and PNC.WorkOutputService.CaptureGroundOutput(sq, nil, nil, { snapshotOnly = true }) or nil
        local ok, reason = FarmingAdapter.Harvest(worker, body, tile)
        if not ok then return false, reason end
        awardFarmingXP(worker, "HARVEST")
        if PNC.WorkOutputService then
            local gained = diffHarvestItems(beforeInv, inventorySnapshot(worker))
            local effect = PNC.WorkOutputService.EnsureOutputEffect(order, "FARMING", {})
            effect.x, effect.y, effect.z = tile.x, tile.y, tile.z
            if #gained > 0 then
                PNC.WorkOutputService.CaptureInventoryOutput(effect, gained, {
                    record = worker, addToInventory = false, collected = true,
                    reason = "farming_harvest", phase = "OUTPUT_DESTINATION_APPROACH",
                })
                effect.delivering = true
                order.pendingOutput = effect
            elseif sq and beforeGround then
                local captured = PNC.WorkOutputService.CaptureGroundOutput(
                    sq, beforeGround, effect, { fallbackItems = {} })
                if captured and #(effect.items or {}) > 0 then
                    effect.delivering = true
                    order.pendingOutput = effect
                end
            end
        end
        return true, "HARVESTED"
    end
    return false, "UNKNOWN_FARM_ACTION"
end

return Internal
