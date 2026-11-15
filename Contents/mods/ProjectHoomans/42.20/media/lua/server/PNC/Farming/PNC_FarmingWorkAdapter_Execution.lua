-- Unified WorkService TargetProvider and ExecuteLive/ExecuteAbstract handlers for FARMING.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingWorkAdapter = PNC.FarmingWorkAdapter or {}

local Adapter = PNC.FarmingWorkAdapter
local Internal = Adapter.Internal
local Work = PNC.WorkService
local Service = PNC.FarmingService
local FatigueGate = PNC.WorkFatigueGate
    or require "PNC/Core/Needs/PNC_WorkFatigueGate"

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

---Resolves the current actionable tile target for a FARMING work order.
function Adapter.Target(order, worker)
    if worker and Internal.IsCamped(worker) then return nil, "NPC_CAMPED" end
    local target = Internal.ResolveTarget(order)
    if not target then return nil, "FARM_TARGET_MISSING" end
    local actionable, inspection = Service.HasActionableWork(target)
    if not actionable then return nil, "FARMING_NO_ACTIONABLE_WORK" end
    local tile = Internal.SelectNextTile(target, inspection)
    if not tile then return nil, "FARMING_NO_ACTIONABLE_WORK" end
    return {
        ok = true,
        componentId = "farming:" .. tostring(target.id),
        claimKey = "farming:" .. tostring(target.id),
        targetKind = "farming_zone",
        target = { x = tile.x + 0.5, y = tile.y + 0.5, z = tile.z or 0 },
        tile = tile,
        phase = "TRAVEL",
    }
end

---Executes live zone/plot farming: collect stockpile inputs -> walk to tile -> act -> haul harvest.
function Adapter.ExecuteLive(order, lease)
    local worker = Internal.RecordFor(order and order.workerId)
    local body = worker and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(worker.id) or nil
    local target = Internal.ResolveTarget(order)
    if not worker or not target then return false, "FARM_TARGET_MISSING" end
    if not body then return Adapter.ExecuteAbstract(order, lease) end
    local now = nowMs()
    if order.pendingOutput and order.pendingOutput.delivering == true
        and PNC.WorkOutputService and PNC.WorkOutputService.TickLiveDelivery
    then
        local ok, complete, reason = PNC.WorkOutputService.TickLiveDelivery(
            order, worker, body, order.pendingOutput, now, {
                moveReason = "farming_stockpile", depositSceneId = "work.deposit",
            })
        if not complete then return ok ~= false, reason end
        order.pendingOutput = nil
    end
    local fatigueOK, fatigueReason = FatigueGate.Check(worker)
    if not fatigueOK then return false, fatigueReason end
    local actionable, inspection = Service.HasActionableWork(target)
    if not actionable then
        Work.Commands.AddProgress(order.id, order.workerId, order.requiredWork)
        return true
    end
    local tile, action = Internal.SelectNextTile(target, inspection)
    if not tile then
        Work.Commands.AddProgress(order.id, order.workerId, order.requiredWork)
        return true
    end
    if action == "PLOW" and PNC.WorkToilRunner and PNC.WorkToilRunner.EnsureToolsStep then
        local toolOk, toolReason = PNC.WorkToilRunner.EnsureToolsStep(
            order, worker, body, { owner = "work:FARMING", applyHands = true })
        if not toolOk then return false, toolReason end
    end
    local reqs, tag = Internal.RequiredInputSpec(action, target, worker, body)
    if reqs then
        local inState, inReason = Internal.CollectStockpileInputs(
            order, worker, body, target, reqs, tag, now)
        if inState == "traveling" or inState == "animating" then return true end
        if inState ~= true then return false, inReason end
    end
    local dest = { x = tile.x + 0.5, y = tile.y + 0.5, z = tile.z or 0 }
    Internal.SyncOrderTarget(order, worker, dest)
    if PNC.WorkToilRunner and PNC.WorkToilRunner.ObserveLiveApproach then
        local status = PNC.WorkToilRunner.ObserveLiveApproach(
            worker, body, "farm_tile:" .. tostring(tile.x) .. ":" .. tostring(tile.y),
            dest, now, { watchSlot = "farming", moveReason = "farming_tile", arriveDistance = 1.3 })
        if status == "stalled" then return false, "FARM_TILE_UNREACHABLE" end
        if status ~= "arrived" then return true end
    end
    local actOk, actReason = Internal.PerformTileAction(order, worker, body, target, tile, action)
    if actOk == "animating" then return true end
    if actOk ~= true then return false, actReason or "FARM_ACTION_FAILED" end
    if not order.pendingOutput and not Service.HasActionableWork(target) then
        Work.Commands.AddProgress(order.id, order.workerId, order.requiredWork)
    end
    return true
end

---Executes abstract farming progression via FarmingService.TickAbstract.
function Adapter.ExecuteAbstract(order, lease)
    local worker = Internal.RecordFor(order and order.workerId)
    local target = Internal.ResolveTarget(order)
    if not worker or not target then return false, "FARM_TARGET_MISSING" end
    local ok, complete, reason = Service.TickAbstract(worker, lease, target)
    if not ok then return false, reason or "FARM_ABSTRACT_FAILED" end
    if complete then
        Work.Commands.AddProgress(order.id, order.workerId, order.requiredWork)
    end
    return true
end

return Adapter
