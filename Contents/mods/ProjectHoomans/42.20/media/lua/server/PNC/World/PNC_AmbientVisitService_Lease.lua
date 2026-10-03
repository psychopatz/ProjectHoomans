if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local number = Internal.number
local text = Internal.text
local worldHours = Internal.worldHours
local primitiveCopy = Internal.primitiveCopy
local recordID = Internal.recordID
local activeCount = Internal.activeCount
local copySite = Internal.copySite
local notify = Internal.notify
local setOrder = Internal.setOrder
local Const = Internal.Const

local function nextLeaseID(npcID)
    Service.Runtime.sequence = Service.Runtime.sequence + 1
    return "ambient_visit:" .. tostring(Service.Runtime.sequence) .. ":"
        .. tostring(npcID or "npc")
end

local function buildOrder(record, site, lease, options)
    local root = site
    options = type(options) == "table" and options or {}
    return {
        kind = Const.ORDER_CAMP or "camp",
        x = site.x,
        y = site.y,
        z = site.z,
        movementX = site.movementX or site.x,
        movementY = site.movementY or site.y,
        movementZ = site.movementZ or site.z,
        radius = site.radius,
        campId = lease.id,
        resourceRadius = site.resourceRadius,
        scope = site.scope,
        siteScope = site.siteScope,
        siteID = site.siteID,
        roomID = site.roomID,
        buildingID = site.buildingID,
        roomType = site.roomType,
        roomName = site.roomName,
        roomBounds = site.roomBounds,
        campfireID = site.campfireID,
        label = site.label,
        risk = site.risk,
        stopDistance = site.stopDistance,
        zoneID = site.siteID,
        zoneLabel = site.label,
        campRootX = root.x,
        campRootY = root.y,
        campRootZ = root.z,
        campRootScope = root.scope,
        campRootSiteID = root.siteID,
        campRootRoomID = root.roomID,
        campRootBuildingID = root.buildingID,
        campRootRoomType = root.roomType,
        campRootRoomName = root.roomName,
        campRootRoomBounds = root.roomBounds,
        campRootCampfireID = root.campfireID,
        -- This remains ORDER_CAMP for the mature AtCamp movement behavior,
        -- but the purpose marker prevents player-camp semantics from being
        -- mistaken for a needs-bearing colonist command.
        ambientVisit = true,
        ambientVisitID = lease.id,
        ambientAccessClass = lease.accessClass,
        ambientPurpose = lease.purpose,
        ambientNoNeeds = true,
        ambientNoItemEffects = true,
        ambientSourceID = text(options.sourceID, nil, 128),
        ambientRevision = lease.revision,
        visitorNPCID = recordID(record),
    }
end

local function summary(lease)
    if not lease then return nil end
    return {
        kind = lease.kind,
        id = lease.id,
        npcID = lease.npcID,
        accessClass = lease.accessClass,
        purpose = lease.purpose,
        startedAt = lease.startedAt,
        expiresAt = lease.expiresAt,
        revision = lease.revision,
        noNeeds = lease.noNeeds,
        noItemEffects = lease.noItemEffects,
        site = primitiveCopy(lease.site),
    }
end

function Service.Begin(record, site, options)
    local id = recordID(record)
    local copiedSite
    local reason
    local eligible
    local previousOrder
    local lease
    local order
    local ok
    local duration
    local at
    options = type(options) == "table" and options or {}
    if options.authorized ~= true then
        return false, "ambient_visit_authorization_required"
    end
    if not id then return false, "visitor_id_missing" end
    if Service.IsActive(record, options.at) then
        return false, "ambient_visit_active" end
    if activeCount() >= Service.MAX_ACTIVE_LEASES then
        return false, "ambient_visit_capacity" end
    eligible, reason = Service.IsEligible(record, options)
    if not eligible then return false, reason end
    copiedSite, reason = copySite(site)
    if not copiedSite then return false, reason end
    at = worldHours(options.at)
    duration = math.max(0.05, math.min(
        Service.MAX_DURATION_HOURS,
        number(options.durationHours, Service.DEFAULT_DURATION_HOURS)
    ))
    previousOrder = primitiveCopy(record.orderSpec)
    lease = {
        version = Service.VERSION,
        kind = "ambient_visit",
        id = nextLeaseID(id),
        npcID = id,
        accessClass = text(options.accessClass, "player_visitor", 32),
        purpose = text(options.purpose, "temporary_ambient_visit", 64),
        startedAt = at,
        expiresAt = at + duration,
        revision = 1,
        status = "active",
        noNeeds = true,
        noItemEffects = true,
        site = copiedSite,
        previousOrder = previousOrder,
    }
    order = buildOrder(record, copiedSite, lease, options)
    Service.Runtime.leases[lease.id] = lease
    Service.Runtime.byNPC[id] = lease.id
    record.runtime = record.runtime or {}
    record.runtime.ambientVisit = {
        leaseID = lease.id,
        accessClass = lease.accessClass,
        purpose = lease.purpose,
        startedAt = lease.startedAt,
        expiresAt = lease.expiresAt,
        revision = lease.revision,
        noNeeds = true,
        noItemEffects = true,
    }
    ok, reason = setOrder(record, order)
    if not ok then
        record.runtime.ambientVisit = nil
        Service.Runtime.byNPC[id] = nil
        Service.Runtime.leases[lease.id] = nil
        return false, reason or "ambient_visit_order_failed"
    end
    notify(record, "ambient_visit_started")
    return true, "ambient_visit_started", summary(lease)
end

Service.Start = Service.Begin

-- Invitation/visit callers pass a semantic target, not an engine object. The
-- caller must already have established authority (conversation token, player
-- ownership, or an AI policy); this helper only performs the authoritative
-- loaded-world resolution before creating the lease.
function Service.BeginAtTarget(record, target, context, options)
    local resolver = PNC.Semantics and PNC.Semantics.CampSiteResolver
    local site
    local reason
    options = type(options) == "table" and options or {}
    if options.authorized ~= true then
        return false, "ambient_visit_authorization_required"
    end
    if not resolver then return false, "camp_site_resolver_unavailable" end
    if options.validateClientSite == true
        and type(resolver.ValidateClientSite) == "function"
    then
        site, reason = resolver.ValidateClientSite(target, context)
    elseif type(resolver.Resolve) == "function" then
        site, reason = resolver.Resolve(target, context)
    else
        return false, "camp_site_resolver_unavailable"
    end
    if not site then return false, reason or "ambient_visit_site_unresolved" end
    return Service.Begin(record, site, options)
end

Service.ResolveAndBegin = Service.BeginAtTarget

return Service
