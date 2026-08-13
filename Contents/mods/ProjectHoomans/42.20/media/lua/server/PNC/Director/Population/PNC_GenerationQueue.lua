-- Small bounded, deduplicated queues. Pending requests are intentionally transient.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.GenerationQueue = PNC.GenerationQueue or {}

local Queue = PNC.GenerationQueue
local Config = PNC.DirectorConfig.Population

Queue.Items = Queue.Items or { GROUP = {}, SETTLEMENT = {} }
Queue.Keys = Queue.Keys or { GROUP = {}, SETTLEMENT = {} }
Queue.HighWater = Queue.HighWater or { GROUP = 0, SETTLEMENT = 0 }

local function list(kind) return Queue.Items[kind] end

function Queue.Key(kind, sectorID, qualifier)
    return tostring(kind) .. ":" .. tostring(sectorID)
        .. ":" .. tostring(qualifier or "AUTO")
end

function Queue.Enqueue(kind, request, now)
    kind = tostring(kind or "")
    if not list(kind) then return false, "invalid_generation_type" end
    request = type(request) == "table" and request or {}
    local key = request.key or Queue.Key(kind, request.sectorId, request.qualifier)
    if Queue.Keys[kind][key] then return false, "queue_duplicate" end
    if #list(kind) >= Config.HARD_MAX_GENERATION_QUEUE then
        return false, "queue_full"
    end
    now = tonumber(now) or 0
    local item = {
        key = key, kind = kind, sectorId = request.sectorId,
        qualifier = request.qualifier, priority = tonumber(request.priority) or 0,
        enqueuedAt = tonumber(request.enqueuedAt) or now,
        expiresAt = tonumber(request.expiresAt) or now + Config.QUEUE_EXPIRY_HOURS,
        attempts = math.max(0, math.floor(tonumber(request.attempts) or 0)),
        source = request.source or "WORLD_POPULATION_DIRECTOR",
    }
    list(kind)[#list(kind) + 1] = item
    Queue.Keys[kind][key] = item
    table.sort(list(kind), function(a, b)
        return a.priority == b.priority and a.enqueuedAt < b.enqueuedAt
            or a.priority > b.priority
    end)
    Queue.HighWater[kind] = math.max(Queue.HighWater[kind], #list(kind))
    return true, "queued", item
end

function Queue.Pop(kind, now)
    local items = list(kind)
    if not items then return nil end
    now = tonumber(now) or 0
    while #items > 0 do
        local item = table.remove(items, 1)
        Queue.Keys[kind][item.key] = nil
        if item.expiresAt > now and item.attempts < Config.QUEUE_MAX_ATTEMPTS then
            return item
        end
    end
    return nil
end

function Queue.Retry(item, now)
    if not item then return false, "missing_request" end
    item.attempts = (tonumber(item.attempts) or 0) + 1
    if item.attempts >= Config.QUEUE_MAX_ATTEMPTS then
        return false, "attempt_limit"
    end
    item.priority = item.priority - 0.05
    item.key = Queue.Key(item.kind, item.sectorId,
        tostring(item.qualifier or "AUTO") .. "_retry_" .. tostring(item.attempts))
    return Queue.Enqueue(item.kind, item, now)
end

function Queue.Count(kind) return #(list(kind) or {}) end

function Queue.CountForSector(kind, sectorID)
    local total = 0
    for _, item in ipairs(list(kind) or {}) do
        if item.sectorId == sectorID then total = total + 1 end
    end
    return total
end

function Queue.Snapshot(now)
    now = tonumber(now) or 0
    local output = {}
    for _, kind in ipairs({ "SETTLEMENT", "GROUP" }) do
        for _, item in ipairs(list(kind) or {}) do
            output[#output + 1] = {
                key = item.key, kind = item.kind, sectorId = item.sectorId,
                qualifier = item.qualifier, priority = item.priority,
                enqueuedAt = item.enqueuedAt, expiresAt = item.expiresAt,
                remainingHours = math.max(0, item.expiresAt - now),
                attempts = item.attempts, source = item.source,
            }
        end
    end
    return output
end

function Queue.Clear()
    Queue.Items, Queue.Keys = { GROUP = {}, SETTLEMENT = {} },
        { GROUP = {}, SETTLEMENT = {} }
end

return Queue
