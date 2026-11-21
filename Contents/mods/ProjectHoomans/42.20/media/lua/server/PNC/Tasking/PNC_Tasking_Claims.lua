-- Unified server-authoritative resource reservation seam for Tasking & Work.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}
PNC.Tasking.Claims = PNC.Tasking.Claims or {}

local Claims = PNC.Tasking.Claims

Claims.DEFAULT_TTL_MS = tonumber(Claims.DEFAULT_TTL_MS) or 30000
Claims.ByKey = Claims.ByKey or {}
Claims.ByLease = Claims.ByLease or {}
Claims.ByOwner = Claims.ByOwner or {}
Claims.Stats = Claims.Stats or {
    acquired = 0,
    renewed = 0,
    released = 0,
    expired = 0,
    conflicts = 0,
}

local function nowMs()
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function tableHasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do
        return true
    end
    return false
end

local function copyShallow(tbl)
    if type(tbl) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end

local function snapshotKeys(tbl)
    local keys = {}
    if type(tbl) ~= "table" then return keys end
    for key in pairs(tbl) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function unindexClaim(record)
    if not record then return end
    local key = record.key
    if record.ownerId and Claims.ByOwner[record.ownerId] then
        Claims.ByOwner[record.ownerId][key] = nil
        if not tableHasEntries(Claims.ByOwner[record.ownerId]) then
            Claims.ByOwner[record.ownerId] = nil
        end
    end
    if record.leaseId and Claims.ByLease[record.leaseId] then
        Claims.ByLease[record.leaseId][key] = nil
        if not tableHasEntries(Claims.ByLease[record.leaseId]) then
            Claims.ByLease[record.leaseId] = nil
        end
    end
    Claims.ByKey[key] = nil
end

local function indexClaim(record)
    local key = record.key
    Claims.ByKey[key] = record
    Claims.ByOwner[record.ownerId] = Claims.ByOwner[record.ownerId] or {}
    Claims.ByOwner[record.ownerId][key] = true
    if record.leaseId then
        Claims.ByLease[record.leaseId] = Claims.ByLease[record.leaseId] or {}
        Claims.ByLease[record.leaseId][key] = true
    end
end

local function isExpired(record, at)
    local expiresAt = record and tonumber(record.expiresAt) or 0
    return expiresAt > 0 and expiresAt <= at
end

local function resolveExpiresAt(at, opts)
    if opts and opts.expiresAt ~= nil then
        return tonumber(opts.expiresAt) or 0
    end
    if opts and opts.ttlMs ~= nil then
        local ttlMs = tonumber(opts.ttlMs) or 0
        return ttlMs > 0 and (at + ttlMs) or 0
    end
    local defaultTtl = tonumber(Claims.DEFAULT_TTL_MS) or 30000
    return defaultTtl > 0 and (at + defaultTtl) or 0
end

local function copyClaimSummary(record)
    if not record then return nil end
    return {
        key = record.key,
        ownerId = record.ownerId,
        leaseId = record.leaseId,
        domain = record.domain,
        acquiredAt = record.acquiredAt,
        expiresAt = record.expiresAt,
        metadata = copyShallow(record.metadata),
    }
end

---Acquires or renews a claim for claimKey on behalf of ownerId.
function Claims.Acquire(claimKey, ownerId, opts)
    local key = tostring(claimKey or "")
    local owner = tostring(ownerId or "")
    if key == "" then return false, "CLAIM_KEY_REQUIRED" end
    if owner == "" then return false, "CLAIM_OWNER_REQUIRED" end

    opts = type(opts) == "table" and opts or {}
    local at = tonumber(opts.at)
    if at == nil then at = nowMs() end
    local leaseId = opts.leaseId ~= nil and tostring(opts.leaseId) or nil
    if leaseId == "" then leaseId = nil end

    local existing = Claims.ByKey[key]
    if existing and isExpired(existing, at) then
        unindexClaim(existing)
        Claims.Stats.expired = Claims.Stats.expired + 1
        existing = nil
    end

    if existing then
        local ownerMatches = existing.ownerId == owner
        local leaseMatches = not (leaseId and existing.leaseId and existing.leaseId ~= leaseId)
        if not ownerMatches or not leaseMatches then
            Claims.Stats.conflicts = Claims.Stats.conflicts + 1
            return false, "RESOURCE_CLAIMED"
        end
        existing.expiresAt = resolveExpiresAt(at, opts)
        if opts.domain ~= nil then
            existing.domain = tostring(opts.domain)
        end
        if type(opts.metadata) == "table" then
            existing.metadata = copyShallow(opts.metadata)
        end
        if leaseId and existing.leaseId ~= leaseId then
            if existing.leaseId and Claims.ByLease[existing.leaseId] then
                Claims.ByLease[existing.leaseId][key] = nil
                if not tableHasEntries(Claims.ByLease[existing.leaseId]) then
                    Claims.ByLease[existing.leaseId] = nil
                end
            end
            existing.leaseId = leaseId
            Claims.ByLease[leaseId] = Claims.ByLease[leaseId] or {}
            Claims.ByLease[leaseId][key] = true
        end
        Claims.Stats.renewed = Claims.Stats.renewed + 1
        return true, existing
    end

    local record = {
        key = key,
        ownerId = owner,
        leaseId = leaseId,
        domain = opts.domain ~= nil and tostring(opts.domain) or "generic",
        acquiredAt = at,
        expiresAt = resolveExpiresAt(at, opts),
        metadata = copyShallow(opts.metadata),
    }
    indexClaim(record)
    Claims.Stats.acquired = Claims.Stats.acquired + 1
    return true, record
end

---Renews an existing active claim's TTL or explicit expiration timestamp.
function Claims.Renew(claimKey, ownerId, ttlMs, at, explicitExpiresAt)
    local key = tostring(claimKey or "")
    if key == "" then return false, "CLAIM_KEY_REQUIRED" end

    local atTime = tonumber(at)
    if atTime == nil then atTime = nowMs() end

    local existing = Claims.ByKey[key]
    if not existing then return false, "CLAIM_NOT_FOUND" end
    if isExpired(existing, atTime) then
        unindexClaim(existing)
        Claims.Stats.expired = Claims.Stats.expired + 1
        return false, "CLAIM_NOT_FOUND"
    end
    if ownerId ~= nil and tostring(ownerId) ~= "" and existing.ownerId ~= tostring(ownerId) then
        return false, "RESOURCE_CLAIMED"
    end

    if explicitExpiresAt ~= nil then
        existing.expiresAt = tonumber(explicitExpiresAt) or 0
    elseif ttlMs ~= nil then
        local ttl = tonumber(ttlMs) or 0
        existing.expiresAt = ttl > 0 and (atTime + ttl) or 0
    else
        local defaultTtl = tonumber(Claims.DEFAULT_TTL_MS) or 30000
        existing.expiresAt = defaultTtl > 0 and (atTime + defaultTtl) or 0
    end
    Claims.Stats.renewed = Claims.Stats.renewed + 1
    return true, existing
end

---Attaches or updates a TaskLease ID on an existing claim without changing owner.
function Claims.AttachLease(claimKey, ownerId, leaseId)
    local key = tostring(claimKey or "")
    local lease = tostring(leaseId or "")
    if key == "" or lease == "" then return false, "CLAIM_OR_LEASE_REQUIRED" end
    local existing = Claims.ByKey[key]
    if not existing then return false, "CLAIM_NOT_FOUND" end
    if ownerId ~= nil and tostring(ownerId) ~= "" and existing.ownerId ~= tostring(ownerId) then
        return false, "RESOURCE_CLAIMED"
    end
    if existing.leaseId and existing.leaseId ~= lease and Claims.ByLease[existing.leaseId] then
        Claims.ByLease[existing.leaseId][key] = nil
        if not tableHasEntries(Claims.ByLease[existing.leaseId]) then
            Claims.ByLease[existing.leaseId] = nil
        end
    end
    existing.leaseId = lease
    Claims.ByLease[lease] = Claims.ByLease[lease] or {}
    Claims.ByLease[lease][key] = true
    return true, existing
end

---Releases a single claim by key (validating ownerId when supplied).
function Claims.Release(claimKey, ownerId, reason)
    local key = tostring(claimKey or "")
    if key == "" then return false, "CLAIM_KEY_REQUIRED" end
    local existing = Claims.ByKey[key]
    if not existing then return false, "CLAIM_NOT_FOUND" end
    if ownerId ~= nil and tostring(ownerId) ~= "" and existing.ownerId ~= tostring(ownerId) then
        return false, "RESOURCE_CLAIMED"
    end
    unindexClaim(existing)
    Claims.Stats.released = Claims.Stats.released + 1
    return true, tostring(reason or "released")
end

---Releases all claims bound to leaseId.
function Claims.ReleaseByLease(leaseId, reason)
    local id = tostring(leaseId or "")
    if id == "" then return 0 end
    local bucket = Claims.ByLease[id]
    if not bucket then return 0 end
    local keys = snapshotKeys(bucket)
    local count = 0
    for i = 1, #keys do
        local record = Claims.ByKey[keys[i]]
        if record then
            unindexClaim(record)
            Claims.Stats.released = Claims.Stats.released + 1
            count = count + 1
        end
    end
    Claims.ByLease[id] = nil
    return count
end

---Releases all claims owned by ownerId.
function Claims.ReleaseByOwner(ownerId, reason)
    local owner = tostring(ownerId or "")
    if owner == "" then return 0 end
    local bucket = Claims.ByOwner[owner]
    if not bucket then return 0 end
    local keys = snapshotKeys(bucket)
    local count = 0
    for i = 1, #keys do
        local record = Claims.ByKey[keys[i]]
        if record then
            unindexClaim(record)
            Claims.Stats.released = Claims.Stats.released + 1
            count = count + 1
        end
    end
    Claims.ByOwner[owner] = nil
    return count
end

---Returns the active claim record for claimKey, pruning it lazily if expired.
function Claims.Get(claimKey, at)
    local key = tostring(claimKey or "")
    if key == "" then return nil end
    local existing = Claims.ByKey[key]
    if not existing then return nil end
    local atTime = tonumber(at)
    if atTime == nil then atTime = nowMs() end
    if isExpired(existing, atTime) then
        unindexClaim(existing)
        Claims.Stats.expired = Claims.Stats.expired + 1
        return nil
    end
    return existing
end

---Returns true if claimKey is actively held (optionally excluding byOtherThanOwnerId).
function Claims.IsClaimed(claimKey, byOtherThanOwnerId, at)
    local record = Claims.Get(claimKey, at)
    if not record then return false, nil end
    if byOtherThanOwnerId ~= nil and tostring(byOtherThanOwnerId) ~= ""
        and record.ownerId == tostring(byOtherThanOwnerId)
    then
        return false, record
    end
    return true, record
end

---Lists shallow copies of claims bound to leaseId.
function Claims.ListByLease(leaseId)
    local out = {}
    local bucket = Claims.ByLease[tostring(leaseId or "")]
    if not bucket then return out end
    local keys = snapshotKeys(bucket)
    for i = 1, #keys do
        local rec = Claims.ByKey[keys[i]]
        if rec then out[#out + 1] = copyClaimSummary(rec) end
    end
    return out
end

---Lists shallow copies of claims owned by ownerId.
function Claims.ListByOwner(ownerId)
    local out = {}
    local bucket = Claims.ByOwner[tostring(ownerId or "")]
    if not bucket then return out end
    local keys = snapshotKeys(bucket)
    for i = 1, #keys do
        local rec = Claims.ByKey[keys[i]]
        if rec then out[#out + 1] = copyClaimSummary(rec) end
    end
    return out
end

---Prunes up to maxChecks expired claims at timestamp at.
function Claims.PruneExpired(at, maxChecks)
    local atTime = tonumber(at)
    if atTime == nil then atTime = nowMs() end
    local limit = math.max(1, math.floor(tonumber(maxChecks) or 128))
    local toExpire = {}
    local checked = 0
    for key, record in pairs(Claims.ByKey) do
        checked = checked + 1
        if isExpired(record, atTime) then
            toExpire[#toExpire + 1] = key
        end
        if checked >= limit then break end
    end
    for i = 1, #toExpire do
        local record = Claims.ByKey[toExpire[i]]
        if record then
            unindexClaim(record)
            Claims.Stats.expired = Claims.Stats.expired + 1
        end
    end
    return #toExpire
end

---Returns bounded diagnostic counts for Colonists Debug UI and tests.
function Claims.GetDiagnostics()
    local activeCount = 0
    for _ in pairs(Claims.ByKey) do activeCount = activeCount + 1 end
    local leaseCount = 0
    for _ in pairs(Claims.ByLease) do leaseCount = leaseCount + 1 end
    local ownerCount = 0
    for _ in pairs(Claims.ByOwner) do ownerCount = ownerCount + 1 end
    return {
        activeCount = activeCount,
        leaseCount = leaseCount,
        ownerCount = ownerCount,
        stats = copyShallow(Claims.Stats),
    }
end

---Clears all claim indexes and resets counters (intended for isolated tests).
function Claims.Reset()
    Claims.ByKey = {}
    Claims.ByLease = {}
    Claims.ByOwner = {}
    Claims.Stats = {
        acquired = 0,
        renewed = 0,
        released = 0,
        expired = 0,
        conflicts = 0,
    }
end

return Claims
