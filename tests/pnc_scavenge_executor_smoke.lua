local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local physicalItems, transfers = {}, 0
local CoreInventory = {}
function CoreInventory.getItemFullType(id)
    return id == 1 and "Base.CannedBeans" or nil
end
function CoreInventory.wrapPhysicalInventory()
    return {
        add = function(_, item)
            local value = { record = item }
            physicalItems[#physicalItems + 1] = value
            return true, { value }
        end,
        count = function(_, fullType)
            local count = 0
            for _, value in ipairs(physicalItems) do
                if CoreInventory.getItemFullType(value.record[1]) == fullType then
                    count = count + 1
                end
            end
            return count
        end,
        _nativeRemove = function(_, item)
            for index = #physicalItems, 1, -1 do
                if physicalItems[index] == item then
                    table.remove(physicalItems, index)
                    return true
                end
            end
            return false
        end,
    }
end

local WorldLoot = {}
function WorldLoot.IsSourceValid() return true end
function WorldLoot.GetSourceLocation() return { x = 2, y = 0, z = 0 } end
function WorldLoot.ReleaseReservation() return true end
function WorldLoot.ReleaseSession() return true end
function WorldLoot.Transfer(arguments)
    transfers = transfers + 1
    T.equal(arguments.owner, "team", "group reservation owner")
    local ok, reason = arguments.destination:add({ [1] = 1, [2] = 1 })
    return ok, reason
end

package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] =
    function() return CoreInventory end
package.preload["PsychopatzCore/Inventory/PsychopatzInventoryConstants"] =
    function() return { TYPE_ID = 1, QUANTITY = 2 } end
package.preload["PsychopatzCore/WorldLoot/PsychopatzWorldLoot"] =
    function() return WorldLoot end

local clock = 2000
local records = {
    bob = { id = "bob", name = "Bob", alive = true, runtime = {},
        inventory = { items = {} },
        x = 0, y = 0, z = 0, presenceState = "live",
        orderSpec = { kind = "follow" } },
    sue = { id = "sue", name = "Sue", alive = true, runtime = {},
        inventory = { items = {} },
        x = 0, y = 0, z = 0, presenceState = "live",
        orderSpec = { kind = "follow" } },
}
local bodies = {
    bob = { getInventory = function() return {} end },
    sue = { getInventory = function() return {} end },
}
local ratios = { bob = 0, sue = 0 }
local sessions, leases = {}, {}
local provider
local lastMove, sceneRequests = {}, {}
local restored, captured, broadcasts, pathResets = 0, 0, 0, 0
local behaviorHandler, threatResponses, sceneInterrupts = nil, 0, 0
local poolRequests = 0

PNC = {
    Const = { ORDER_SCAVENGE = "scavenge", PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return clock end,
        GenerateID = function(prefix) return prefix .. ":1" end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        MarkDirty = function() end,
    },
    PathService = {
        MoveToward = function(record, _, x, y, z, _, stopDistance, reason,
            navigationOptions)
            lastMove[record.id] = { x = x, y = y, z = z,
                stopDistance = stopDistance, reason = reason,
                navigationPolicy = navigationOptions
                    and navigationOptions.navigationPolicy }
            return true, "arrived"
        end,
        Reset = function(_, record)
            pathResets = pathResets + 1
            if record and record.runtime then record.runtime.pathing = nil end
        end,
    },
    Inventory = {
        Internal = { getItemWeight = function() return 1 end },
        GetEncumbranceState = function(record)
            local ratio = ratios[record.id] or 0
            return { ratio = ratio, usedWeight = ratio * 10,
                maxWeight = 10, level = ratio > 1 and "encumbered" or "normal" }
        end,
        CanAccept = function() return true end,
        CaptureLooseInventory = function(record)
            captured = captured + 1
            record.inventory.items = {}
            for index, value in ipairs(physicalItems) do
                record.inventory.items["captured:" .. tostring(index)] = {
                    type = CoreInventory.getItemFullType(value.record[1]),
                    stack = tonumber(value.record[2]) or 1,
                }
            end
            return true
        end,
    },
    AnimationScenes = {
        RequestFromPool = function(record, _, poolName)
            poolRequests = poolRequests + 1
            local variants = { "scavenge.loot_high", "scavenge.loot_low" }
            local sceneId = variants[(poolRequests - 1) % #variants + 1]
            sceneRequests[#sceneRequests + 1] = {
                npcId = record.id, sceneId = sceneId, poolName = poolName }
            return true, { id = sceneId }
        end,
        Request = function(record, _, sceneId)
            sceneRequests[#sceneRequests + 1] = {
                npcId = record.id, sceneId = sceneId }
            return true
        end,
        Interrupt = function()
            sceneInterrupts = sceneInterrupts + 1
            return true
        end,
    },
    Network = { BroadcastRecord = function() broadcasts = broadcasts + 1 end },
    TaskLeaseService = {
        Get = function(id) return leases[tostring(id)] end,
        ForNPC = function(id)
            for _, lease in pairs(leases) do
                if lease.npcId == tostring(id) then return lease end
            end
        end,
    },
    Tasking = { Commands = {} },
    OrderSystem = {
        RegisterNormalizer = function() return true end,
        SetOrder = function(record, order) record.orderSpec = order end,
    },
    JobSystem = { RegisterOrder = function() return true end },
    BehaviorCompanion = { Internal = {
        ShouldScanFollowThreat = function() return true end,
        TryRespondToThreat = function()
            threatResponses = threatResponses + 1
            return true
        end,
    } },
    BehaviorRegistry = { Register = function(job, handler)
        if job == "Scavenge" then behaviorHandler = handler end
        return true
    end },
}

function PNC.Tasking.Commands.RegisterProvider(_, value)
    provider = value
    return true
end
function PNC.Tasking.Commands.SetPhase(npcId, phase)
    local lease = PNC.TaskLeaseService.ForNPC(npcId)
    if lease then lease.phase = phase end
    return lease ~= nil
end
function PNC.Tasking.Commands.Complete(id, reason)
    local lease = leases[id]
    if not lease then return false end
    provider.Complete(lease, reason)
    leases[id] = nil
    return true
end
function PNC.Tasking.Commands.CancelForNPC(npcId, reason)
    local lease = PNC.TaskLeaseService.ForNPC(npcId)
    if not lease then return false end
    provider.Cancel(lease, reason)
    leases[lease.leaseId] = nil
    return true
end

local discoveredBy
local function activity(session, status, entry, reasonOrDetails)
    local details = type(reasonOrDetails) == "table"
        and reasonOrDetails or { reason = reasonOrDetails }
    session.activity = session.activity or {}
    session.activity[#session.activity + 1] = {
        status = status, entryId = entry and entry.entryId,
        reason = details.reason, npcId = details.npcId }
end

PNC.ScavengeService = {
    Sessions = sessions,
    Diagnostics = { counters = {}, timings = {} },
    GetSession = function(id) return sessions[id] end,
    AppendSourceItems = function(session, source, npcId)
        discoveredBy = npcId
        session.manifest[#session.manifest + 1] = {
            entryId = "found:" .. source.sourceToken }
        return true, 1
    end,
    Internal = {
        SessionForNPC = function(npcId)
            for _, session in pairs(sessions) do
                if session.workers and session.workers[tostring(npcId)] then
                    return session
                end
            end
        end,
        Increment = function() end,
        Activity = activity,
        Touch = function(session) session.revision = session.revision + 1 end,
        Emit = function() end,
        ReleaseReservations = function() end,
        RestorePreviousOrder = function(session, npcId)
            restored = restored + 1
            local record = records[tostring(npcId)]
            record.orderSpec = session.previousOrders[tostring(npcId)]
        end,
        TERMINAL_STATES = { COMPLETED = true, CANCELLED = true, FAILED = true },
    },
}

local Executor = T.load("ProjectHoomans", "server",
    "PNC/Scavenge/PNC_ScavengeExecutor.lua")
T.equal(provider, Executor, "task coordinator owns scavenge executor")
T.truthy(behaviorHandler, "scavenge survival behavior registered")
T.truthy(behaviorHandler(records.bob, bodies.bob, "Scavenge", clock),
    "scavenge behavior retains combat primitive")
T.equal(threatResponses, 1, "scavenger scans and responds to nearby threats")

local function leaseFor(session, npcId)
    local lease = { leaseId = "lease:" .. session.id .. ":" .. npcId,
        npcId = npcId, sourceRef = session.id,
        sourceDomain = "scavenge", phase = "ASSIGNED" }
    leases[lease.leaseId] = lease
    return lease
end

local search = {
    id = "search", npcId = "bob", npcIds = { "bob" },
    workers = { bob = { npcId = "bob", phase = "READY" } },
    runActive = true, state = "DISCOVERING", revision = 1,
    candidates = { { sourceToken = "source:fridge",
        sourceType = "container", sourceLabel = "Fridge" } },
    candidateCount = 1, nextCandidateIndex = 1,
    processedCount = 0, searchedCount = 0, unreachableCount = 0,
    invalidCount = 0, manifest = {}, activity = {}, createdAt = 1000,
    previousOrders = { bob = { kind = "follow" } },
}
sessions.search = search
local lease = leaseFor(search, "bob")
T.equal(Executor.GetCandidates("bob")[1].precedence, "FORCED_ORDER",
    "explicit scavenging order outranks ordinary needs and work")
records.bob.runtime.pathing = { phase = "blocked", blockReason = "old_order" }
T.truthy(Executor.Start(lease), "search worker starts")
T.equal(records.bob.runtime.pathing, nil,
    "scavenge start clears a stale blocked path lane")
T.truthy(pathResets > 0, "scavenge start resets previous navigation")
records.bob.runtime.recentThreat = { expiresAt = clock - 1 }
records.bob.runtime.zombieAttacker = { observedAt = clock - 2000 }
T.truthy(Executor.Tick(lease), "worker claims finite source")
T.equal(search.workers.bob.phase, "READY",
    "expired combat observations do not hold scavenger in waiting")
T.truthy(Executor.Tick(lease), "worker routes to source and starts scene")
T.equal(lastMove.bob.reason, "scavenge_search",
    "scavenging uses routed behavior movement")
T.equal(lastMove.bob.x, 1.5,
    "container target is an adjacent interaction tile")
T.equal(sceneRequests[1].poolName, "scavenge.loot",
    "search requests one randomized loot animation")
local interruptsBeforeCombat = sceneInterrupts
records.bob.runtime.target = { kind = "zombie" }
T.truthy(Executor.Tick(lease), "combat temporarily owns scavenger")
T.equal(search.processedCount, 0,
    "interrupted search does not inspect source during combat")
T.equal(search.workers.bob.phase, "INTERRUPTED_COMBAT",
    "worker exposes combat interruption phase")
T.equal(sceneInterrupts, interruptsBeforeCombat + 1,
    "combat interrupts loot presentation")
records.bob.runtime.target = nil
T.truthy(Executor.Tick(lease), "search resumes at source after combat")
clock = clock + 700
T.truthy(Executor.Tick(lease), "scene completes before source inspection")
T.equal(search.processedCount, 1, "source processed once")
T.equal(search.searchedCount, 1, "source searched once")
T.equal(discoveredBy, "bob", "search result records the finding scavenger")
T.equal(search.activity[#search.activity].npcId, "bob",
    "activity log attributes searched source to its scavenger")
T.truthy(Executor.Tick(lease), "finite area settles after final source")
T.equal(search.state, "WAITING_FOR_SELECTION",
    "fully explored area stops searching")
T.falsy(search.runActive, "fully explored run releases workers")

sessions.search = nil
local retry = {
    id = "retry", npcId = "bob", npcIds = { "bob" },
    workers = { bob = { npcId = "bob", phase = "READY" } },
    runActive = true, state = "DISCOVERING", revision = 1,
    candidates = { { sourceToken = "source:retry_fridge",
        sourceType = "container", sourceLabel = "Fridge" } },
    candidateCount = 1, nextCandidateIndex = 1,
    processedCount = 0, searchedCount = 0, unreachableCount = 0,
    invalidCount = 0, manifest = {}, activity = {}, createdAt = clock,
    previousOrders = { bob = { kind = "follow" } },
}
sessions.retry = retry
local retryLease = leaseFor(retry, "bob")
Executor.Tick(retryLease)
records.bob.runtime.pathing = {
    phase = "blocked", blockReason = "native_progress_timeout" }
Executor.Tick(retryLease)
T.equal(retry.processedCount, 0,
    "first native timeout does not discard the source")
T.truthy(retry.workers.bob.currentSource,
    "worker retains source while selecting another interaction tile")
Executor.Tick(retryLease)
T.truthy(retry.workers.bob.actionUntil,
    "worker resumes search after alternate interaction path")
T.equal(lastMove.bob.navigationPolicy, "direct",
    "native timeout activates bounded local movement recovery")
Executor.Cancel(retryLease, "test_cleanup")
leases[retryLease.leaseId] = nil
sessions.retry = nil

records.bob.x, records.bob.y = 1.0, 0
lastMove.bob = nil
local near = {
    id = "near", npcId = "bob", npcIds = { "bob" },
    workers = { bob = { npcId = "bob", phase = "READY" } },
    runActive = true, state = "DISCOVERING", revision = 1,
    candidates = { { sourceToken = "source:near_fridge",
        sourceType = "container", sourceLabel = "Fridge" } },
    candidateCount = 1, nextCandidateIndex = 1,
    processedCount = 0, searchedCount = 0, unreachableCount = 0,
    invalidCount = 0, manifest = {}, activity = {}, createdAt = clock,
    previousOrders = { bob = { kind = "follow" } },
}
sessions.near = near
local nearLease = leaseFor(near, "bob")
Executor.Tick(nearLease)
Executor.Tick(nearLease)
T.equal(lastMove.bob, nil,
    "interaction radius starts looting without an unreachable exact-tile path")
T.truthy(near.workers.bob.actionUntil,
    "nearby source immediately starts its brief loot action")
Executor.Cancel(nearLease, "test_cleanup")
leases[nearLease.leaseId] = nil
sessions.near = nil
records.bob.x, records.bob.y = 0, 0

local entry = { entryId = "entry:beans", itemToken = "item:1",
    sourceToken = "source:floor", sourceType = "floor",
    status = "QUEUED", reservationToken = "r:1",
    fullType = "Base.CannedBeans", displayName = "Beans", quantity = 1 }
local team = {
    id = "team", npcId = "bob", npcIds = { "bob", "sue" },
    workers = {
        bob = { npcId = "bob", phase = "READY" },
        sue = { npcId = "sue", phase = "READY" },
    },
    runActive = true, state = "COLLECTION_QUEUED", revision = 1,
    candidates = {}, candidateCount = 0, nextCandidateIndex = 1,
    processedCount = 0, searchedCount = 0, unreachableCount = 0,
    invalidCount = 0, manifest = { entry }, manifestById = {
        [entry.entryId] = entry }, activity = {}, queueCount = 1,
    queue = { { sourceToken = entry.sourceToken, sourceType = "floor",
        entries = { entry }, x = 2, y = 0, z = 0 } },
    collectedCount = 0, unavailableCount = 0,
    previousOrders = {
        bob = { kind = "follow" }, sue = { kind = "follow" },
    },
}
sessions.team = team
ratios.bob, ratios.sue = 1.1, 0
local bobLease = leaseFor(team, "bob")
local sueLease = leaseFor(team, "sue")
Executor.Tick(bobLease)
T.equal(entry.assignedNpcId, nil,
    "encumbered scavenger does not claim queued item")
Executor.Tick(sueLease)
T.equal(entry.assignedNpcId, "sue",
    "free-capacity scavenger claims queued item")
local sceneBeforePickup = sceneRequests[#sceneRequests].sceneId
Executor.Tick(sueLease)
T.equal(sceneRequests[#sceneRequests].poolName, "scavenge.loot",
    "pickup uses the same randomized loot animation pipeline")
T.truthy(sceneRequests[#sceneRequests].sceneId ~= sceneBeforePickup,
    "consecutive loot actions can select different variants")
T.equal(transfers, 0, "item remains in world during loot scene")
clock = clock + 700
Executor.Tick(sueLease)
T.equal(entry.status, "COLLECTED", "item transfers after scene")
T.equal(transfers, 1, "queued item transferred exactly once")
T.equal(#physicalItems, 1, "free-capacity NPC receives item")
T.truthy(captured > 0, "physical inventory captured into NPC model")
T.equal(broadcasts, 1, "inventory mutation replicated")
T.equal(team.activity[#team.activity].npcId, "sue",
    "activity log attributes collected item to its scavenger")

T.finish("pnc_scavenge_executor_smoke")
