-- Bounded world-effect retry, reconciliation, and server pump.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.WorldEffectService
local Internal = Service.Internal
local Repository = Internal.Repository or PNC.WorkRepository
local now = Internal.Now
local markDirty = Internal.MarkDirty
local pending = Internal.Pending
local indexOwner = Internal.IndexOwner
local listProviderOwners = Internal.ListProviderOwners
local squareAt = Internal.SquareAt

local function scheduleRetry(entry, reason, at)
    local effect = entry.effect
    local attempts = (tonumber(effect.attempts) or 0) + 1
    local delay = Service.RETRY_BASE_MS
        * (2 ^ math.min(attempts - 1, 4))
    effect.attempts = attempts
    effect.nextRetryAt = at + math.min(Service.RETRY_MAX_MS, delay)
    effect.lastAttemptAt = at
    effect.lastReason = tostring(reason or "WORLD_EFFECT_RETRY")
    effect.waitReason = effect.lastReason
    effect.updatedAt = at
    markDirty(Service.Providers[entry.providerID], entry.owner)
end

local function applyEntry(entry, at)
    local effect = entry.effect
    local handler = Service.Handlers[tostring(effect.kind or "")]
    if not handler then
        effect.state = "FAILED"
        effect.lastReason = "WORLD_EFFECT_HANDLER_MISSING"
        effect.updatedAt = at
        markDirty(Service.Providers[entry.providerID], entry.owner)
        return false
    end
    effect.lastAttemptAt = at
    local ok, result, detail = handler.Apply(entry.owner, effect, {
        providerID = entry.providerID, ownerID = entry.ownerID,
        service = Service,
    })
    if type(result) == "string" then detail = result end
    if type(result) == "table" then
        detail = result.reason or result.detail or detail
        if result.state then effect.state = tostring(result.state) end
        ok = result.ok == true or result.status == "APPLIED"
    end
    if ok == true then
        if tostring(effect.state or "") ~= "APPLIED" then
            effect.state = "APPLIED"
            effect.appliedAt = at
        end
        effect.lastReason = tostring(detail or "APPLIED")
        effect.updatedAt = at
        markDirty(Service.Providers[entry.providerID], entry.owner)
        return true
    end
    local state = tostring(effect.state or "PENDING")
    if state == "CONFLICT" or state == "FAILED"
        or state == "CANCELLED"
    then
        effect.lastReason = tostring(detail or state)
        effect.updatedAt = at
        markDirty(Service.Providers[entry.providerID], entry.owner)
        return false
    end
    scheduleRetry(entry, detail or "WORLD_EFFECT_RETRY", at)
    return false
end

local function due(entry, at)
    return (tonumber(entry.effect.nextRetryAt) or 0) <= at
end

local function candidateKeys(point, at)
    local keys = {}
    if point then
        for key in pairs(Service.Runtime.byPoint[point] or {}) do
            keys[#keys + 1] = key
        end
    else
        for key, entry in pairs(Service.Runtime.entries) do
            if due(entry, at) then keys[#keys + 1] = key end
        end
    end
    table.sort(keys)
    return keys
end

function Service.RebuildIndex()
    Service.Runtime.entries = {}
    Service.Runtime.byPoint = {}
    Service.Runtime.byOwner = {}
    if Repository and type(Repository.Load) == "function" then
        Repository.Load()
    end
    for providerID, provider in pairs(Service.Providers) do
        for _, owner in ipairs(listProviderOwners(provider)) do
            indexOwner(providerID, owner, false)
        end
    end
    Service.Runtime.indexed = true
    return true
end

function Service.Reconcile(at, point, limit, bypassRetry)
    at = tonumber(at) or now()
    limit = math.max(1, math.floor(tonumber(limit)
        or (point and Service.MAX_APPLIES_PER_LOAD
            or Service.MAX_APPLIES_PER_PUMP)))
    if not Service.Runtime.indexed then Service.RebuildIndex() end
    local applied, visited = 0, 0
    for _, key in ipairs(candidateKeys(point, at)) do
        if visited >= limit then break end
        local entry = Service.Runtime.entries[key]
        if entry and pending(entry.effect, Service.Providers[entry.providerID],
            entry.owner) and (bypassRetry == true or due(entry, at))
        then
            visited = visited + 1
            if applyEntry(entry, at) then applied = applied + 1 end
            indexOwner(entry.providerID, entry.owner, false)
        end
    end
    return applied, visited
end

function Service.Pump(at)
    at = tonumber(at) or now()
    if at < (tonumber(Service.Runtime.nextPumpAt) or 0) then return 0 end
    Service.Runtime.nextPumpAt = at + Service.PUMP_INTERVAL_MS
    local applied = Service.Reconcile(at, nil, Service.MAX_APPLIES_PER_PUMP)
    return applied
end

function Service.IsPointLoaded(x, y, z)
    local square, reason = squareAt(x, y, z)
    return square ~= nil, reason
end
