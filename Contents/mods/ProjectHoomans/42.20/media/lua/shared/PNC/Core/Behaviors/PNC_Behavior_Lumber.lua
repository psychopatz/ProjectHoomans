-- Shared order projection for lumber work.
--
-- The server task executor owns tree mutation and movement decisions. This
-- shared handler keeps live clients and abstract records on the same durable
-- order/job identity without attempting to mutate world objects on clients.

PNC = PNC or {}
PNC.BehaviorLumber = PNC.BehaviorLumber or {}

local Lumber = PNC.BehaviorLumber
local Const = PNC.Const or {}

local KIND = Const.ORDER_LUMBER or "lumber"
local JOB = "Lumber"

local function normalize(_, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = KIND,
        lumberJobId = tostring(spec.lumberJobId or ""),
        zoneId = tostring(spec.zoneId or ""),
        phase = tostring(spec.phase or "WAITING"),
    }
end

function Lumber.Tick(record)
    local order = record and record.orderSpec or nil
    if not order or tostring(order.kind or "") ~= tostring(KIND) then
        return false
    end
    record.activeJob = JOB
    local runtime = record.runtime and record.runtime.lumber or nil
    record.activeBehavior = "Lumber:" .. tostring(
        runtime and runtime.phase or order.phase or "WAITING"
    )
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(KIND, JOB)
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register(JOB, Lumber.Tick)
end

return Lumber
