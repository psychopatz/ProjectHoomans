-- Farming WorkService order creation and zone/plot reconciliation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingWorkAdapter = PNC.FarmingWorkAdapter or {}

local Adapter = PNC.FarmingWorkAdapter
local Internal = Adapter.Internal
local Work = PNC.WorkService
local Service = PNC.FarmingService
local Farming = PNC.Farming
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local SettlementRepo = PNC.SettlementRepository

local function ensureAutonomousOrder(orderId, target, payload)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not target or not orderId
    then
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    local existing = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(orderId) or nil
    local actionable = Service and Service.HasActionableWork
        and Service.HasActionableWork(target) or false
    if not actionable then
        if existing and not existing.workerId
            and existing.status ~= Status.CANCELLED
            and existing.status ~= Status.COMPLETED
            and existing.status ~= Status.FAILED and Work.Commands.Cancel
        then
            Work.Commands.Cancel(orderId, "farming_no_actionable_work")
        end
        return false, "FARMING_NO_ACTIONABLE_WORK"
    end
    if existing and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.FAILED
    then
        return true, existing
    end
    local base = Internal.BaseForTarget(target)
    local order, reason = Work.Commands.Queue({
        id = orderId,
        operation = "FARMING",
        colonyId = tostring(target.colonyId or (base and base.colonyId) or ""),
        factionId = tostring(target.factionId or (base and base.factionId) or ""),
        baseId = tostring(target.baseId or (base and base.id) or ""),
        requiredWorkerId = nil,
        requiredWork = 1,
        priority = 45,
        precedence = "NORMAL_WORK",
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE", returnHome = "STAY" },
        payload = payload,
    })
    if not order then return false, reason or "FARMING_ORDER_FAILED" end
    return true, order
end

---Maintains an autonomous NORMAL_WORK order for an actionable farming zone.
function Adapter.EnsureZoneOrder(zone)
    if not zone or not zone.id then return false, "FARM_ZONE_INVALID" end
    return ensureAutonomousOrder("farming-zone:" .. tostring(zone.id), zone, {
        zoneId = zone.id, autonomous = true,
    })
end

---Maintains an autonomous NORMAL_WORK order for an actionable facility plot.
function Adapter.EnsurePlotOrder(facility, plot)
    if not facility or not plot or not plot.id then
        return false, "GROWING_PLOT_NOT_FOUND"
    end
    plot.baseId = plot.baseId or facility.baseId
    return ensureAutonomousOrder("farming-plot:" .. tostring(plot.id), plot, {
        facilityId = facility.id, plotId = plot.id, autonomous = true,
    })
end

---Creates or reuses a FORCED_ORDER manual assignment for a farming zone or plot.
function Adapter.EnsureManualOrder(zoneOrPlot, npcId)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not zoneOrPlot or not npcId
    then
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    local actionable = Service and Service.HasActionableWork
        and Service.HasActionableWork(zoneOrPlot) or false
    if not actionable then return false, "FARMING_NO_ACTIONABLE_WORK" end
    local autoId = zoneOrPlot.facilityId
        and ("farming-plot:" .. tostring(zoneOrPlot.id))
        or ("farming-zone:" .. tostring(zoneOrPlot.id))
    local autoOrder = Work.Queries and Work.Queries.Get and Work.Queries.Get(autoId) or nil
    if autoOrder and tostring(autoOrder.workerId or "") == tostring(npcId)
        and autoOrder.status ~= Status.CANCELLED
        and autoOrder.status ~= Status.COMPLETED
        and autoOrder.status ~= Status.FAILED
    then
        return true, autoOrder
    end
    local base = Internal.BaseForTarget(zoneOrPlot)
    local payload = zoneOrPlot.facilityId
        and { facilityId = zoneOrPlot.facilityId, plotId = zoneOrPlot.id, npcId = npcId }
        or { zoneId = zoneOrPlot.id, npcId = npcId }
    local order, reason = Work.Commands.Queue({
        operation = "FARMING",
        colonyId = tostring(zoneOrPlot.colonyId or (base and base.colonyId) or ""),
        factionId = tostring(zoneOrPlot.factionId or (base and base.factionId) or ""),
        baseId = tostring(zoneOrPlot.baseId or (base and base.id) or ""),
        requiredWorkerId = npcId,
        requiredWork = 1,
        priority = 90,
        precedence = "FORCED_ORDER",
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE", returnHome = "STAY" },
        payload = payload,
    })
    if not order then return false, reason or "FARMING_MANUAL_ORDER_FAILED" end
    return true, order
end

---Reconciles WorkService orders for all configured farming zones and facility plots.
function Adapter.Reconcile()
    local count = 0
    for _, zone in pairs(Service and Service.Data and Service.Data.zones or {}) do
        if zone and Adapter.EnsureZoneOrder(zone) then count = count + 1 end
    end
    if SettlementRepo and SettlementRepo.GetFacilitiesByDefinition then
        for _, facility in ipairs(SettlementRepo.GetFacilitiesByDefinition(
            Farming.FACILITY_ID) or {})
        do
            for _, plot in ipairs(Service.Internal.PlotsFor
                and Service.Internal.PlotsFor(facility) or {})
            do
                if Adapter.EnsurePlotOrder(facility, plot) then count = count + 1 end
            end
        end
    end
    return count
end

return Adapter
