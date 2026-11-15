-- WorkZoneService per-target TTL claim management and bounded cursor tile scanning.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC = PNC or {}
PNC.WorkZoneService = PNC.WorkZoneService or {}
PNC.WorkZoneService.Internal = PNC.WorkZoneService.Internal or {}

local Service = PNC.WorkZoneService
local Internal = Service.Internal
local DEFAULT_CLAIM_TTL = 10
local DEFAULT_SCAN_BUDGET = 32

local function pruneExpired(zone, at)
    local claims = zone and zone.claims or nil
    if type(claims) ~= "table" then return end
    local removeKeys = {}
    for key, claim in pairs(claims) do
        if tonumber(claim.expiresAt) and tonumber(claim.expiresAt) <= at then
            removeKeys[#removeKeys + 1] = key
        end
    end
    for index = 1, #removeKeys do
        claims[removeKeys[index]] = nil
    end
end

---Claims a spot or tile key inside a work zone with TTL expiry.
function Service.ClaimTarget(zoneId, targetKey, workerId, opts)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    if zone.enabled == false then return false, "WORK_ZONE_DISABLED" end
    targetKey = tostring(targetKey or "")
    workerId = tostring(workerId or "")
    if targetKey == "" then return false, "TARGET_KEY_REQUIRED" end
    if workerId == "" then return false, "WORKER_REQUIRED" end

    opts = type(opts) == "table" and opts or {}
    local at = tonumber(opts.at) or Internal.now()
    local ttl = math.max(1, tonumber(opts.ttlSeconds) or DEFAULT_CLAIM_TTL)
    zone.claims = zone.claims or {}
    pruneExpired(zone, at)

    local current = zone.claims[targetKey]
    if current and tostring(current.workerId) ~= workerId then
        return false, "TARGET_CLAIMED"
    end
    zone.claims[targetKey] = {
        targetKey = targetKey,
        workerId = workerId,
        claimedAt = current and current.claimedAt or at,
        expiresAt = at + ttl,
    }
    return true, zone.claims[targetKey]
end

---Renews an existing target claim's TTL if held by the worker.
function Service.RenewTarget(zoneId, targetKey, workerId, ttlSeconds, at)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    targetKey = tostring(targetKey or "")
    workerId = tostring(workerId or "")
    local claim = zone.claims and zone.claims[targetKey] or nil
    if not claim then return false, "CLAIM_NOT_FOUND" end
    if workerId ~= "" and tostring(claim.workerId) ~= workerId then
        return false, "TARGET_CLAIMED"
    end
    local now = tonumber(at) or Internal.now()
    local ttl = math.max(1, tonumber(ttlSeconds) or DEFAULT_CLAIM_TTL)
    claim.expiresAt = now + ttl
    return true, claim
end

---Releases a specific target claim, or all claims held by workerId when targetKey is nil.
function Service.ReleaseTarget(zoneId, targetKey, workerId)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    zone.claims = zone.claims or {}
    if targetKey ~= nil then
        local key = tostring(targetKey)
        local claim = zone.claims[key]
        if not claim then return false end
        if workerId ~= nil and tostring(claim.workerId) ~= tostring(workerId) then
            return false, "TARGET_CLAIMED"
        end
        zone.claims[key] = nil
        return true
    end
    local released = 0
    local removeKeys = {}
    for key, claim in pairs(zone.claims) do
        if workerId == nil or tostring(claim.workerId) == tostring(workerId) then
            removeKeys[#removeKeys + 1] = key
        end
    end
    for index = 1, #removeKeys do
        zone.claims[removeKeys[index]] = nil
        released = released + 1
    end
    return released > 0, released
end

---Scans up to opts.budget tiles in a zone via bounded cursor progression.
function Service.ScanStep(zoneId, visitor, opts)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    if type(visitor) ~= "function" then return false, "VISITOR_REQUIRED" end
    local bounds = zone.bounds
    if not bounds then return true, 0 end

    opts = type(opts) == "table" and opts or {}
    local budget = math.max(1, math.floor(tonumber(opts.budget) or DEFAULT_SCAN_BUDGET))
    local width = math.max(1, bounds.maxX - bounds.minX + 1)
    local height = math.max(1, bounds.maxY - bounds.minY + 1)
    local total = width * height
    local z = bounds.minZ or 0
    local cursor = math.max(1, math.min(total, tonumber(zone.cursor) or 1))
    local scanned = 0
    local matches = {}

    for step = 0, math.min(total, budget) - 1 do
        local idx = ((cursor - 1 + step) % total)
        local x = bounds.minX + (idx % width)
        local y = bounds.minY + math.floor(idx / width)
        local inside = true
        if zone.geometry and GridRegion and type(GridRegion.containsPoint) == "function" then
            inside = GridRegion.containsPoint(zone.geometry, x, y, z)
        end
        if inside then
            scanned = scanned + 1
            local result = visitor(x, y, z, zone)
            if result ~= nil then
                matches[#matches + 1] = result
                if opts.stopOnFirst then
                    zone.cursor = ((idx + 1) % total) + 1
                    return true, scanned, matches
                end
            end
        end
    end
    zone.cursor = ((cursor - 1 + math.min(total, budget)) % total) + 1
    return true, scanned, matches
end

return Service
