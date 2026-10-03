if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local MobileSites = Internal.MobileSites
local number = Internal.number
local primitiveCopy = Internal.primitiveCopy
local recordID = Internal.recordID
local mobileShelterKey = Internal.mobileShelterKey
local boundsOverlap = Internal.boundsOverlap

local function trimMobileSiteCache()
    local cache = Service.Runtime.mobileSites
    local entries = {}
    for candidateKey, candidate in pairs(cache) do
        entries[#entries + 1] = {
            key = candidateKey,
            touchedAt = number(candidate and candidate.touchedAt, 0),
        }
    end
    if #entries <= Service.MAX_MOBILE_SITE_CACHE then return end
    table.sort(entries, function(left, right)
        if left.touchedAt == right.touchedAt then
            return tostring(left.key) < tostring(right.key)
        end
        return left.touchedAt < right.touchedAt
    end)
    for index = 1, #entries - Service.MAX_MOBILE_SITE_CACHE do
        cache[entries[index].key] = nil
    end
end

local function rememberMobileSite(key, site, at)
    if not key or not site then return end
    Service.Runtime.mobileSites[key] = {
        site = primitiveCopy(site),
        touchedAt = number(at, 0),
    }
    trimMobileSiteCache()
end

local function rememberMobileFailure(key, reason, at)
    if not key then return end
    Service.Runtime.mobileSites[key] = {
        reason = reason or "mobile_shelter_room_missing",
        retryAt = number(at, 0) + Service.MOBILE_SHELTER_RETRY_HOURS,
        touchedAt = number(at, 0),
    }
    trimMobileSiteCache()
end

local function cachedMobileSite(key, at)
    local cache = key and Service.Runtime.mobileSites[key] or nil
    if not cache or not cache.site then return nil end
    cache.touchedAt = number(at, 0)
    return primitiveCopy(cache.site)
end

local function resolveMobileShelterSite(record, zombie, order, at)
    local resolver = PNC.Semantics and PNC.Semantics.CampSiteResolver
    local key = mobileShelterKey(order)
    local failed = key and Service.Runtime.mobileSites[key] or nil
    local cached = cachedMobileSite(key, at)
    local target
    local site
    local reason
    if cached then return cached, "cached" end
    if failed and not failed.site
        and number(failed.retryAt, 0) > number(at, 0)
    then
        return nil, failed.reason or "mobile_shelter_retry_deferred"
    end
    if not resolver or type(resolver.Resolve) ~= "function" then
        rememberMobileFailure(key, "camp_site_resolver_unavailable", at)
        return nil, "camp_site_resolver_unavailable"
    end
    target = {
        kind = "camp_site",
        scope = "room",
        radius = math.max(4, math.min(32,
            number(order and order.radius, 12))),
    }
    site, reason = resolver.Resolve(target, {
        origin = {
            x = number(order and order.x, record and record.x),
            y = number(order and order.y, record and record.y),
            z = number(order and order.z, record and record.z),
        },
        body = zombie,
        record = record,
        npcID = recordID(record),
        requestID = "ambient_mobile_shelter:" .. tostring(key or "unknown"),
    })
    if not site then
        reason = reason or "mobile_shelter_room_missing"
        rememberMobileFailure(key, reason, at)
        return nil, reason
    end
    -- The existing mobile target is a building site. Do not let the generic
    -- nearest-room fallback silently choose a different adjacent building.
    if order and order.shelterBounds and site.roomBounds
        and not boundsOverlap(order.shelterBounds, site.roomBounds)
    then
        reason = "mobile_shelter_room_outside_target"
        rememberMobileFailure(key, reason, at)
        return nil, reason
    end
    rememberMobileSite(key, site, at)
    return primitiveCopy(site), "resolved"
end

MobileSites.remember = rememberMobileSite
MobileSites.rememberFailure = rememberMobileFailure
MobileSites.cached = cachedMobileSite
MobileSites.resolve = resolveMobileShelterSite
