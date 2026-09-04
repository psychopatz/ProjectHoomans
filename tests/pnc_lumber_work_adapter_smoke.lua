local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local records = {
    worker = { id = "worker", runtime = {}, orderSpec = {
        kind = "production_work", workOrderId = "work:1",
    } },
}
local job = {
    id = "lumber-job:1", npcId = "worker", zoneId = "zone:1",
    active = true, state = "READY", phase = "WAITING", targetKey = nil,
}
local order
local registrations = {}
local tickComplete = false
local addedProgress = 0
local releasedTree = nil
local queueCalls = 0
local worldEffectProviders = {}
local worldEffectHandlers = {}

local status = {
    CANCELLED = "CANCELLED", COMPLETED = "COMPLETED", FAILED = "FAILED",
    CANCELLING = "CANCELLING",
}

PNC = {
    WorkDefinitions = { STATUS = status },
    WorkService = {
        Internal = {
            setLiveOrder = function(record, value, target, phase)
                record.orderSpec = {
                    kind = "production_work", workOrderId = value.id,
                    operation = "LUMBER", x = target.x, y = target.y,
                    z = target.z, phase = phase,
                }
            end,
        },
        Commands = {
            Queue = function(spec)
                queueCalls = queueCalls + 1
                order = {
                    id = "work:1", operation = spec.operation,
                    payload = spec.payload, requiredWork = spec.requiredWork,
                    status = "QUEUED", priority = spec.priority,
                }
                return order
            end,
            AddProgress = function(_, _, amount)
                addedProgress = addedProgress + amount
                order.status = "COMPLETED"
                return true
            end,
        },
        Queries = {
            Get = function() return order end,
        },
        RegisterTargetProvider = function(operation, handler)
            registrations.target = { operation, handler }
            return true
        end,
        RegisterExecution = function(operation, handler)
            registrations.execution = { operation, handler }
            return true
        end,
        RegisterAbstractExecution = function(operation, handler)
            registrations.abstract = { operation, handler }
            return true
        end,
        CompletionHandlers = {}, CancellationHandlers = {},
    },
    WorldEffectService = {
        RegisterProvider = function(id, provider)
            worldEffectProviders[id] = provider
            return true
        end,
        Register = function(kind, handler)
            worldEffectHandlers[kind] = handler
            return true
        end,
    },
    LumberService = {
        Data = { jobs = { worker = job } },
        GetJob = function() return job end,
        GetZone = function() return {
            enabled = true,
            bounds = { minX = 10, minY = 20, maxX = 12, maxY = 22,
                minZ = 0, maxZ = 0 },
        } end,
        GetTree = function() return nil end,
        FindApproach = function() return nil end,
        TickJob = function() return true, tickComplete, "zone_exhausted" end,
        ReleaseTree = function(key) releasedTree = key end,
        ApplyDeferredTreeRemoval = function() return true, "TREE_REMOVED" end,
    },
    Registry = { Get = function(id) return records[tostring(id)] end },
}

local Adapter = T.load("ProjectHoomans", "server",
    "PNC/Lumber/PNC_LumberWorkAdapter.lua")
T.equal(registrations.target[1], "LUMBER", "lumber target registration")
T.equal(registrations.execution[1], "LUMBER", "lumber execution registration")
T.equal(registrations.abstract[1], "LUMBER",
    "abstract lumber execution registration")
T.truthy(worldEffectProviders.LUMBER,
    "lumber world-effect provider registration")
T.truthy(worldEffectHandlers.TREE_REMOVE,
    "tree removal world-effect registration")

local ensured, queued = Adapter.EnsureOrder(job)
T.truthy(ensured, "work order created")
T.equal(queued.payload.lumberJobId, job.id, "tree job payload persisted")
T.equal(queued.payload.npcId, "worker", "worker payload persisted")
T.equal(queueCalls, 1, "lumber order queued once")
T.equal(records.worker.activeBehavior, "Lumber:WAITING_FOR_WORKER",
    "queued lumber order publishes its worker wait")
T.equal(records.worker.runtime.lumber.waitingFor, "worker",
    "queued lumber order identifies the missing lease")

local target = registrations.target[2](order, records.worker)
T.truthy(target.ok, "zone target acquired")
T.equal(target.target.x, 11.5, "zone target x")
T.equal(target.target.y, 21.5, "zone target y")

local executed = registrations.execution[2](order, {
    npcId = "worker", leaseId = "lease:1", executionMode = "LIVE",
})
T.truthy(executed, "tree execution delegated")
T.equal(job.leaseId, "lease:1", "work lease bound to tree job")
T.equal(job.workOrderId, order.id, "work order bound to tree job")

tickComplete = true
executed = registrations.execution[2](order, {
    npcId = "worker", leaseId = "lease:1", executionMode = "LIVE",
})
T.truthy(executed, "zone completion delegated")
T.equal(addedProgress, 1, "work order advances only after zone exhaustion")

Adapter.Complete(order)
T.falsy(job.active, "completion retires lumber job")
T.equal(releasedTree, nil, "completion does not release an unclaimed tree")

job.active, job.state, job.phase = true, "READY", "WAITING"
job.workOrderId, job.leaseId, job.targetKey = order.id, "lease:2", "tree:1"
order.status = "WAITING_FOR_WORKER"
T.truthy(Adapter.Cancel(order), "worker release is recoverable")
T.truthy(job.active, "worker release keeps lumber job active")
T.equal(job.workOrderId, order.id,
    "worker release keeps the durable order link for requeue")
T.equal(releasedTree, "tree:1", "worker release returns tree claim")
T.equal(Adapter.Reconcile(), 1,
    "reconcile keeps a recoverable lumber order linked")
T.equal(queueCalls, 1, "reconcile does not duplicate a recoverable order")

job.workOrderId, job.leaseId, job.targetKey = order.id, "lease:3", "tree:2"
order.status = status.CANCELLING
order.cancellationRequested = true
T.truthy(Adapter.Cancel(order), "cancellation handled")
T.falsy(job.active, "cancellation retires lumber job")

T.finish("pnc_lumber_work_adapter_smoke")
