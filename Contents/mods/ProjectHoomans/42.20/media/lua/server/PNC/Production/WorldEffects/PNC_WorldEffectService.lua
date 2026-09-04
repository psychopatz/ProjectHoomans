-- Durable, server-authoritative world mutations that must wait for a loaded
-- grid square.  Providers own persistence; this service owns indexing,
-- bounded retries, and diagnostics.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorldEffectService = PNC.WorldEffectService or {}

local Service = PNC.WorldEffectService
local Core = PNC.Core or {}
local Repository = PNC.WorkRepository

Service.SCHEMA_VERSION = 1
Service.PUMP_INTERVAL_MS = 1000
Service.MAX_APPLIES_PER_PUMP = 8
Service.MAX_APPLIES_PER_LOAD = 8
Service.RETRY_BASE_MS = 2000
Service.RETRY_MAX_MS = 30000
Service.Providers = Service.Providers or {}
Service.Handlers = Service.Handlers or {}
Service.Runtime = Service.Runtime or {}
Service.Runtime.entries = Service.Runtime.entries or {}
Service.Runtime.byPoint = Service.Runtime.byPoint or {}
Service.Runtime.byOwner = Service.Runtime.byOwner or {}
Service.Runtime.indexed = Service.Runtime.indexed == true
Service.Runtime.nextPumpAt = tonumber(Service.Runtime.nextPumpAt) or 0

local function now()
    return Core and type(Core.Now) == "function" and Core.Now() or 0
end

local function copy(value)
    if Core and type(Core.DeepCopy) == "function" then
        return Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function markDirty(provider, owner)
    if provider and type(provider.MarkDirty) == "function" then
        provider.MarkDirty(owner)
        return
    end
    if Repository and type(Repository.MarkDirty) == "function" then
        Repository.MarkDirty()
    end
end

local function pointKey(x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z) or 0
    if not x or not y then return nil end
    return tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))
        .. ":" .. tostring(math.floor(z))
end

local function getCell()
    if type(_G and _G.getCell) == "function" then
        local ok, cell = pcall(_G.getCell)
        if ok and cell then return cell end
        return nil, "CELL_LOOKUP_FAILED"
    end
    if IsoWorld and IsoWorld.instance then
        return IsoWorld.instance.currentCell
    end
    return nil, "WORLD_API_UNAVAILABLE"
end

-- This is intentionally the only generic engine exception boundary. Domain
-- code remains direct and all failures are returned to the effect ledger.
local function squareAt(x, y, z)
    local cell, cellReason = getCell()
    if not cell then return nil, cellReason end
    if type(cell.getGridSquare) ~= "function" then
        return nil, "GRID_LOOKUP_UNAVAILABLE"
    end
    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
    if not ok then return nil, "GRID_LOOKUP_FAILED" end
    return square
end

local function effectID(providerID, ownerID, effect)
    local id = effect and (effect.id or effect.effectId)
    if id ~= nil and tostring(id) ~= "" then return tostring(id) end
    if Core and type(Core.GenerateID) == "function" then
        return tostring(Core.GenerateID("world_effect"))
    end
    return tostring(providerID) .. ":" .. tostring(ownerID) .. ":"
        .. tostring(effect and effect.kind or "effect")
end

local function effectsFor(provider, owner)
    if provider and type(provider.GetEffects) == "function" then
        local effects = provider.GetEffects(owner)
        if type(effects) == "table" then return effects end
    end
    return {}
end

local function ownerIDFor(providerID, provider, owner)
    if provider and type(provider.GetOwnerID) == "function" then
        return tostring(provider.GetOwnerID(owner) or "")
    end
    return tostring(owner and owner.id or providerID)
end

local function pending(effect, provider, owner)
    if type(effect) ~= "table" then return false end
    if provider and type(provider.IsPending) == "function" then
        return provider.IsPending(owner, effect) == true
    end
    local state = tostring(effect.state or "PENDING")
    return state ~= "APPLIED" and state ~= "CANCELLED"
        and state ~= "CONFLICT" and state ~= "FAILED"
end

local function pointsFor(providerID, provider, owner, effect)
    local points
    local handler = Service.Handlers[tostring(effect and effect.kind or "")]
    if handler and type(handler.GetPoints) == "function" then
        points = handler.GetPoints(owner, effect)
    elseif provider and type(provider.GetPoints) == "function" then
        points = provider.GetPoints(owner, effect)
    elseif type(effect and effect.points) == "table" then
        points = effect.points
    else
        points = {}
        if effect and effect.sourceX ~= nil and effect.sourceY ~= nil then
            points[#points + 1] = {
                role = "source", x = effect.sourceX, y = effect.sourceY,
                z = effect.sourceZ,
            }
        end
        if effect and effect.destinationX ~= nil
            and effect.destinationY ~= nil
        then
            points[#points + 1] = {
                role = "destination", x = effect.destinationX,
                y = effect.destinationY, z = effect.destinationZ,
            }
        end
        if #points == 0 and effect and effect.x ~= nil
            and effect.y ~= nil
        then
            points[1] = {
                role = "target", x = effect.x, y = effect.y, z = effect.z,
            }
        end
    end
    if type(points) ~= "table" then return {} end
    local output = {}
    for index = 1, #points do
        local point = points[index]
        if type(point) == "table" and point.x ~= nil and point.y ~= nil then
            output[#output + 1] = {
                role = point.role or (index == 1 and "source" or "target"),
                x = tonumber(point.x), y = tonumber(point.y),
                z = tonumber(point.z) or 0,
            }
        end
    end
    return output
end

local function entryKey(providerID, ownerID, effect)
    return tostring(providerID) .. ":" .. tostring(ownerID) .. ":"
        .. effectID(providerID, ownerID, effect)
end

local function removeEntry(key)
    local entry = Service.Runtime.entries[key]
    if not entry then return end
    for _, point in ipairs(entry.points or {}) do
        local bucket = Service.Runtime.byPoint[point.key]
        if bucket then
            bucket[key] = nil
            local empty = true
            for _ in pairs(bucket) do empty = false; break end
            if empty then Service.Runtime.byPoint[point.key] = nil end
        end
    end
    Service.Runtime.entries[key] = nil
end

local function removeOwnerEntries(providerID, ownerID)
    local ownerKey = tostring(providerID) .. ":" .. tostring(ownerID)
    local keys = Service.Runtime.byOwner[ownerKey]
    if keys then
        for _, key in ipairs(keys) do removeEntry(key) end
    end
    Service.Runtime.byOwner[ownerKey] = nil
end

local function indexOwner(providerID, owner, shouldDirty)
    local provider = Service.Providers[tostring(providerID)]
    if not provider or type(owner) ~= "table" then return 0 end
    local ownerID = ownerIDFor(providerID, provider, owner)
    if ownerID == "" then return 0 end
    removeOwnerEntries(providerID, ownerID)
    local ownerKey = tostring(providerID) .. ":" .. ownerID
    local ownerKeys = {}
    local count = 0
    for _, effect in ipairs(effectsFor(provider, owner)) do
        if pending(effect, provider, owner) then
            if not effect.id and not effect.effectId then
                effect.id = effectID(providerID, ownerID, effect)
                if shouldDirty ~= false then markDirty(provider, owner) end
            end
            local key = entryKey(providerID, ownerID, effect)
            local entry = {
                key = key, providerID = tostring(providerID),
                ownerID = ownerID, owner = owner, effect = effect,
                points = {},
            }
            for _, point in ipairs(pointsFor(providerID, provider, owner,
                effect)) do
                local keyAtPoint = pointKey(point.x, point.y, point.z)
                if keyAtPoint then
                    point.key = keyAtPoint
                    entry.points[#entry.points + 1] = point
                    local bucket = Service.Runtime.byPoint[keyAtPoint]
                        or {}
                    bucket[key] = true
                    Service.Runtime.byPoint[keyAtPoint] = bucket
                end
            end
            Service.Runtime.entries[key] = entry
            ownerKeys[#ownerKeys + 1] = key
            count = count + 1
        end
    end
    Service.Runtime.byOwner[ownerKey] = ownerKeys
    return count
end

local function listProviderOwners(provider)
    if not provider or type(provider.List) ~= "function" then return {} end
    local owners = provider.List()
    return type(owners) == "table" and owners or {}
end

function Service.RegisterProvider(providerID, provider)
    providerID = tostring(providerID or "")
    if providerID == "" or type(provider) ~= "table" then
        return false, "INVALID_WORLD_EFFECT_PROVIDER"
    end
    Service.Providers[providerID] = provider
    Service.Runtime.indexed = false
    return true
end

function Service.Register(kind, handler)
    kind = tostring(kind or "")
    if kind == "" or type(handler) ~= "table"
        or type(handler.Apply) ~= "function"
    then return false, "INVALID_WORLD_EFFECT_HANDLER" end
    Service.Handlers[kind] = handler
    return true
end

function Service.IndexOwner(providerID, owner)
    return indexOwner(providerID, owner, true)
end

function Service.IndexOrder(order)
    return indexOwner("WORK_ORDER", order, true)
end

function Service.MarkPending(providerID, owner, effect, reason)
    if type(effect) ~= "table" then return false, "INVALID_WORLD_EFFECT" end
    local at = now()
    local previous = tostring(effect.waitReason or "")
    effect.state = "PENDING"
    effect.waitReason = tostring(reason or "WORLD_UNAVAILABLE")
    effect.updatedAt = at
    if previous ~= effect.waitReason or effect.nextRetryAt == nil then
        effect.nextRetryAt = 0
    end
    markDirty(Service.Providers[tostring(providerID)], owner)
    indexOwner(providerID, owner, false)
    return true, "WORLD_EFFECT_PENDING"
end

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

local function endpointSnapshot(point)
    local loaded, reason = Service.IsPointLoaded(point.x, point.y, point.z)
    return {
        role = point.role, x = point.x, y = point.y, z = point.z,
        loaded = loaded, loadReason = reason,
    }
end

local function debugRow(providerID, provider, owner, effect)
    local ownerID = ownerIDFor(providerID, provider, owner)
    local points = pointsFor(providerID, provider, owner, effect)
    local endpoints = {}
    for _, point in ipairs(points) do
        endpoints[#endpoints + 1] = endpointSnapshot(point)
    end
    local workerID = owner.workerId or owner.npcId
    local worker = workerID and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerID) or nil
    local required = math.max(1, tonumber(owner.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(owner.progress) or 0))
    return {
        effectId = tostring(effect.id or effect.effectId or ""),
        providerID = tostring(providerID), ownerID = ownerID,
        operation = owner.operation or effect.operation,
        kind = effect.kind, state = effect.state or "PENDING",
        orderStatus = owner.status, workerID = workerID,
        workerName = worker and (worker.name or worker.fullName
            or worker.displayName) or nil,
        progress = progress, requiredWork = required,
        percent = math.floor(progress / required * 100 + 0.5),
        priority = owner.priority, createdAt = effect.createdAt,
        updatedAt = effect.updatedAt, appliedAt = effect.appliedAt,
        attempts = tonumber(effect.attempts) or 0,
        nextRetryAt = effect.nextRetryAt,
        waitReason = effect.waitReason, lastReason = effect.lastReason,
        lastAttemptAt = effect.lastAttemptAt,
        endpoints = endpoints,
        identity = copy(effect.identity or {
            haulToken = effect.haulToken,
            deathMarkerId = effect.deathMarkerId,
            treeKey = effect.treeKey,
            signature = effect.signature,
        }),
    }
end

function Service.BuildSnapshot(options)
    options = type(options) == "table" and options or {}
    local requestedState = options.state and tostring(options.state) or nil
    local requestedKind = options.kind and tostring(options.kind) or nil
    local limit = math.max(1, math.min(500,
        math.floor(tonumber(options.limit) or 100)))
    local rows, matched, summary = {}, 0, {
        total = 0, pending = 0, applied = 0, conflict = 0, failed = 0,
        cancelled = 0,
    }
    for providerID, provider in pairs(Service.Providers) do
        for _, owner in ipairs(listProviderOwners(provider)) do
            for _, effect in ipairs(effectsFor(provider, owner)) do
                if type(effect) == "table" then
                    local state = tostring(effect.state or "PENDING")
                    summary.total = summary.total + 1
                    summary[string.lower(state)] =
                        (summary[string.lower(state)] or 0) + 1
                    if (not requestedState or requestedState == "ALL"
                        or requestedState == state)
                        and (not requestedKind
                            or requestedKind == tostring(effect.kind or ""))
                    then
                        matched = matched + 1
                        rows[#rows + 1] = debugRow(providerID, provider,
                            owner, effect)
                    end
                end
            end
        end
    end
    table.sort(rows, function(left, right)
        local leftPending = left.state == "PENDING" and 0 or 1
        local rightPending = right.state == "PENDING" and 0 or 1
        if leftPending ~= rightPending then return leftPending < rightPending end
        return tostring(left.effectId) < tostring(right.effectId)
    end)
    while #rows > limit do rows[#rows] = nil end
    return {
        schemaVersion = Service.SCHEMA_VERSION, serverTime = now(),
        summary = summary, rows = rows, truncated = matched > #rows,
        filter = { state = requestedState or "PENDING", kind = requestedKind },
    }
end

-- Work orders keep their existing durable worldEffect field for compatibility.
-- Lumber and future multi-effect domains can use a list or a domain-owned
-- record through another provider without creating a second retry loop.
Service.RegisterProvider("WORK_ORDER", {
    List = function()
        if Repository and type(Repository.Load) == "function" then
            Repository.Load()
        end
        local output = {}
        for _, order in pairs(Repository and Repository.State
            and Repository.State.byId or {}) do
            if type(order) == "table"
                and (type(order.worldEffect) == "table"
                    or type(order.worldEffects) == "table")
            then output[#output + 1] = order end
        end
        return output
    end,
    GetOwnerID = function(order) return order and order.id end,
    GetEffects = function(order)
        local output = {}
        if type(order and order.worldEffect) == "table" then
            output[#output + 1] = order.worldEffect
        end
        for _, effect in ipairs(order and order.worldEffects or {}) do
            if type(effect) == "table" then output[#output + 1] = effect end
        end
        return output
    end,
    IsPending = function(order, effect)
        if not order or order.status ~= "WORLD_EFFECT_PENDING" then
            return false
        end
        local state = tostring(effect and effect.state or "PENDING")
        return state ~= "APPLIED" and state ~= "CANCELLED"
            and state ~= "CONFLICT" and state ~= "FAILED"
    end,
})

if Events and Events.LoadGridsquare and not Service.LoadSquareHookRegistered then
    Events.LoadGridsquare.Add(function(square)
        if not square then return end
        local x = square.getX and square:getX() or square.x
        local y = square.getY and square:getY() or square.y
        local z = square.getZ and square:getZ() or square.z or 0
        local key = pointKey(x, y, z)
        if key then
            -- A load event is the exact transition the effect was waiting for;
            -- do not make it wait out an older exponential backoff window.
            Service.Reconcile(now(), key, Service.MAX_APPLIES_PER_LOAD, true)
        end
    end)
    Service.LoadSquareHookRegistered = true
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Pump() end)
    Service.TickHookRegistered = true
end

return Service
