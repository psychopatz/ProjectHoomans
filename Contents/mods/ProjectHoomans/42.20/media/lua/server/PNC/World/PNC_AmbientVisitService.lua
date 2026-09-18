-- Temporary, server-owned access for friendly NPC visitors and faction
-- ambient campers. This is deliberately separate from settlement admission:
-- it never transfers faction/community ownership and never creates needs.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.AmbientVisitService = PNC.AmbientVisitService or {}

local Service = PNC.AmbientVisitService
local Const = PNC.Const or {}
local Core = PNC.Core

Service.VERSION = 1
Service.DEFAULT_DURATION_HOURS = 4
Service.MAX_DURATION_HOURS = 12
Service.MAX_ACTIVE_LEASES = 16
Service.PUMP_INTERVAL_HOURS = 2 / 60
Service.PUMP_BUDGET = 4
Service.MOBILE_SHELTER_RETRY_HOURS = 0.25
Service.MOBILE_SHELTER_DURATION_HOURS = 12
Service.MAX_MOBILE_SITE_CACHE = 8

Service.Runtime = Service.Runtime or {}
Service.Runtime.leases = Service.Runtime.leases or {}
Service.Runtime.byNPC = Service.Runtime.byNPC or {}
Service.Runtime.mobileSites = Service.Runtime.mobileSites or {}
Service.Runtime.sequence = tonumber(Service.Runtime.sequence) or 0

local function number(value, fallback)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return fallback
end

local function text(value, fallback, maximum)
    if value == nil then return fallback end
    value = tostring(value)
    if maximum then value = string.sub(value, 1, maximum) end
    return value ~= "" and value or fallback
end

local function primitiveCopy(value, depth)
    local valueType = type(value)
    local output
    local child
    if value == nil then return nil end
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or (depth or 0) >= 5 then return nil end
    output = {}
    for key, childValue in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            child = primitiveCopy(childValue, (depth or 0) + 1)
            if child ~= nil then output[key] = child end
        end
    end
    return output
end

local function worldHours(value)
    local gameTime
    local ok
    local result
    if value ~= nil then return number(value, 0) end
    gameTime = type(getGameTime) == "function" and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        ok, result = pcall(gameTime.getWorldAgeHours, gameTime)
        if ok and number(result) ~= nil then return number(result) end
    end
    return 0
end

local function isAuthority()
    return not Core or not Core.IsAuthority
        or Core.IsAuthority() == true
end

local function recordID(record)
    return text(record and record.id, nil, 128)
end

local function activeCount()
    local count = 0
    for _, lease in pairs(Service.Runtime.leases) do
        if lease and lease.status == "active" then count = count + 1 end
    end
    return count
end

local function liveBody(record)
    local registry = PNC.Registry
    local ok
    local body
    if not registry or type(registry.GetLiveZombie) ~= "function" then
        return nil
    end
    ok, body = pcall(registry.GetLiveZombie, record and record.id)
    if not ok or not body then return nil end
    if type(body.isDead) == "function" and body:isDead() then return nil end
    return body
end

local function blockedRuntime(record)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    if not runtime then return false end
    if runtime.target ~= nil or runtime.combatTarget ~= nil
        or runtime.attackAction ~= nil or runtime.facilityActivity ~= nil
        or runtime.workOrderId ~= nil or runtime.taskLeaseId ~= nil
        or runtime.medicalCare ~= nil or runtime.treatment ~= nil
    then
        return true
    end
    if health and health.state == "incapacitated" then return true end
    return false
end

local function normalizedScope(value)
    value = string.lower(tostring(value or ""))
    if value == "inside" or value == "building" then return "room" end
    if value == "fire" or value == "firepit" then return "campfire" end
    if value == "room" or value == "campfire" then return value end
    return nil
end

local function copyBounds(bounds)
    if type(bounds) ~= "table" then return nil end
    if PNC.Semantics and PNC.Semantics.CampSite
        and PNC.Semantics.CampSite.NormalizeBounds
    then
        return PNC.Semantics.CampSite.NormalizeBounds(bounds)
    end
    return primitiveCopy(bounds)
end

local function copySite(site)
    local scope
    local output
    if type(site) ~= "table" then return nil, "ambient_visit_site_missing" end
    scope = normalizedScope(site.scope or site.siteScope)
    if not scope then return nil, "ambient_visit_site_scope_invalid" end
    output = {
        kind = "camp_site",
        scope = scope,
        siteScope = scope,
        siteID = text(site.siteID, nil, 128),
        roomID = text(site.roomID, nil, 128),
        buildingID = text(site.buildingID, nil, 128),
        roomType = text(site.roomType, nil, 48),
        roomName = text(site.roomName, nil, 64),
        roomBounds = copyBounds(site.roomBounds),
        campfireID = text(site.campfireID, nil, 128),
        x = number(site.x or site.targetX),
        y = number(site.y or site.targetY),
        z = number(site.z or site.targetZ, 0),
        movementX = number(site.movementX or site.x or site.targetX),
        movementY = number(site.movementY or site.y or site.targetY),
        movementZ = number(site.movementZ or site.z or site.targetZ, 0),
        radius = math.max(0.5, number(site.radius, 3)),
        resourceRadius = math.max(1, math.min(24,
            number(site.resourceRadius, 12))),
        stopDistance = math.max(0.25, number(site.stopDistance,
            scope == "room" and 0.7 or 1.25)),
        label = text(site.label, scope == "room" and "room" or "campfire", 64),
        risk = text(site.risk, nil, 32),
    }
    if output.x == nil or output.y == nil then
        return nil, "ambient_visit_site_position_missing"
    end
    if scope == "room" and not output.siteID and not output.roomID
        and not output.buildingID and not output.roomBounds
    then
        return nil, "ambient_visit_room_identity_missing"
    end
    if scope == "campfire" and not output.campfireID
        and not output.siteID
    then
        return nil, "ambient_visit_campfire_identity_missing"
    end
    return output
end

local function leaseFor(recordOrID)
    local id
    local leaseID
    local record
    if type(recordOrID) == "table" then
        record = recordOrID
        id = recordID(record)
        leaseID = record.runtime and record.runtime.ambientVisit
            and record.runtime.ambientVisit.leaseID or nil
    else
        id = text(recordOrID, nil, 128)
    end
    if not leaseID and id and Service.Runtime.leases[id] then
        return Service.Runtime.leases[id], record
    end
    if not leaseID and id then leaseID = Service.Runtime.byNPC[id] end
    if not leaseID then return nil, record end
    return Service.Runtime.leases[tostring(leaseID)], record
end

local function orderIsLease(record, lease)
    local order = record and record.orderSpec or nil
    return order and lease
        and tostring(order.ambientVisitID or "") == tostring(lease.id or "")
end

local function boundsOverlap(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    return number(left.minX, -math.huge) <= number(right.maxX, math.huge)
        and number(right.minX, -math.huge) <= number(left.maxX, math.huge)
        and number(left.minY, -math.huge) <= number(right.maxY, math.huge)
        and number(right.minY, -math.huge) <= number(left.maxY, math.huge)
end

local function mobileShelterKey(order)
    if type(order) ~= "table" then return nil end
    if order.ambientSourceID then
        return tostring(order.ambientSourceID)
    end
    if order.shelterSiteID then
        return tostring(order.shelterSiteID)
    end
    return string.format(
        "%.1f:%.1f:%s",
        number(order.x, 0),
        number(order.y, 0),
        tostring(number(order.z, 0))
    )
end

local function trimMobileSiteCache()
    local cache = Service.Runtime.mobileSites
    while true do
        local count = 0
        local oldestKey
        local oldestAt = math.huge
        for candidateKey, candidate in pairs(cache) do
            count = count + 1
            if number(candidate and candidate.touchedAt, 0) < oldestAt then
                oldestKey = candidateKey
                oldestAt = number(candidate and candidate.touchedAt, 0)
            end
        end
        if count <= Service.MAX_MOBILE_SITE_CACHE or not oldestKey then
            break
        end
        cache[oldestKey] = nil
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

local function notify(record, reason)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, reason or "ambient_visit")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, reason or "ambient_visit")
    end
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil,
            Core and Core.Now and Core.Now() or 0)
    end
end

local function setOrder(record, order)
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        local ok, reason = pcall(PNC.OrderSystem.SetOrder, record, order)
        if not ok then return false, tostring(reason or "order_failed") end
        return true
    end
    record.orderSpec = order
    return true
end

function Service.Get(recordOrID)
    local lease = leaseFor(recordOrID)
    return lease
end

function Service.IsActive(recordOrID, at)
    local lease = leaseFor(recordOrID)
    if not lease or lease.status ~= "active" then return false end
    return number(lease.expiresAt, 0) > worldHours(at)
end

function Service.IsOrderProtected(record, at)
    local lease = leaseFor(record)
    return Service.IsActive(record, at) and orderIsLease(record, lease)
end

function Service.CanUseAmbient(record, at)
    local lease = leaseFor(record)
    return Service.IsActive(record, at)
        and lease.noNeeds == true
        and lease.noItemEffects == true
end

function Service.IsEligible(record, options)
    local order
    local mode
    local actorControl
    options = type(options) == "table" and options or {}
    if not isAuthority() then return false, "not_authority" end
    if not record or record.alive == false then
        return false, "record_invalid" end
    if record.presenceState
        and tostring(record.presenceState)
            ~= tostring(Const.PRESENCE_LIVE or "live")
        and options.allowAbstract ~= true
    then
        return false, "visitor_not_live" end
    if options.requireMaterialized ~= false and not liveBody(record) then
        return false, "visitor_not_materialized" end
    order = record.orderSpec or {}
    if tostring(order.kind or "") ~= tostring(Const.ORDER_ROAM or "roam") then
        return false, "visitor_order_not_roam" end
    mode = tostring(order.roamMode or "area")
    if options.roamModes and not options.roamModes[mode] then
        return false, "visitor_roam_mode_not_allowed" end
    if record.recruited == true or record.ownerUsername ~= nil
        or record.ownerOnlineID ~= nil or record.colonyOwned == true
    then
        return false, "visitor_player_owned" end
    if record.hostility and (
        record.hostility.attackPlayers == true
            or record.hostility.attackNPCs == true)
    then
        return false, "visitor_hostile" end
    actorControl = PNC.ActorControl
    if actorControl and actorControl.IsPuppetOwned
        and actorControl.IsPuppetOwned(record)
    then
        return false, "visitor_actor_owned" end
    if blockedRuntime(record) then return false, "visitor_busy" end
    return true, "eligible"
end

local function resolveRecord(recordOrID)
    if type(recordOrID) == "table" then return recordOrID end
    if PNC.Registry and PNC.Registry.Get then
        return PNC.Registry.Get(tostring(recordOrID or ""))
    end
    return nil
end

local function relationshipState(relationship)
    local states = PNC.RelationshipStates
    local resolved
    if states and type(states.ResolveState) == "function" then
        local ok, value = pcall(states.ResolveState, relationship or {})
        if ok and value then resolved = value end
    end
    return tostring(resolved or relationship and relationship.state or "")
end

local function activePlayerBase(player)
    local factions = PNC.Factions
    local communities = PNC.Communities
    local baseService = PNC.BaseService
    local faction
    local colony
    local base
    if not player or not factions
        or type(factions.GetPlayerFaction) ~= "function"
    then
        return nil, "visitor_player_faction_missing"
    end
    faction = factions.GetPlayerFaction(player)
    if not faction or not communities
        or type(communities.GetForFaction) ~= "function"
    then
        return nil, "visitor_colony_missing"
    end
    for _, candidate in ipairs(communities.GetForFaction(faction.id) or {}) do
        if candidate and candidate.status == "active" then
            colony = candidate
            break
        end
    end
    if not colony or not baseService
        or type(baseService.GetForColony) ~= "function"
    then
        return nil, "visitor_base_missing"
    end
    base = baseService.GetForColony(colony.id)
    if not base then return nil, "visitor_base_missing" end
    return base, nil, faction, colony
end

local function baseZone(base)
    local ok
    local zones
    local zone
    local grid
    if not base or not base.baseZoneId then
        return nil, "visitor_base_zone_missing"
    end
    ok, zones = pcall(require, "PsychopatzCore/World/PC_ZoneRegistry")
    if not ok or not zones or type(zones.get) ~= "function" then
        return nil, "visitor_base_zone_unavailable"
    end
    zone = zones.get(base.baseZoneId)
    if not zone or type(zone.geometry) ~= "table" then
        return nil, "visitor_base_zone_missing"
    end
    ok, grid = pcall(require, "PsychopatzCore/World/PC_GridRegion")
    if not ok or not grid or type(grid.containsXY) ~= "function" then
        return nil, "visitor_base_geometry_unavailable"
    end
    return { base = base, zone = zone, grid = grid }
end

local function pointInBase(baseContext, x, y)
    local geometry = baseContext and baseContext.zone
        and baseContext.zone.geometry or nil
    local grid = baseContext and baseContext.grid or nil
    x, y = number(x), number(y)
    if not geometry or not grid or x == nil or y == nil then return false end
    return grid.containsXY(geometry, math.floor(x), math.floor(y)) == true
end

local function sitePoint(site)
    if type(site) ~= "table" then return nil, nil end
    return number(site.movementX or site.x or site.targetX),
        number(site.movementY or site.y or site.targetY)
end

local function invitationFailure(reason)
    return {
        eligible = false,
        reason = tostring(reason or "ambient_visit_unavailable"),
    }
end

-- This is deliberately a cheap, server-derived preview. It is sent with the
-- relationship presentation so the menu can stay quiet for ineligible NPCs;
-- it never searches rooms, campfires, or loaded squares.
function Service.GetInvitationPreview(recordOrID, player, relationship)
    local record = resolveRecord(recordOrID)
    local eligible
    local reason
    local base
    if not isAuthority() then return invitationFailure("not_authority") end
    eligible, reason = Service.IsEligible(record, {
        requireMaterialized = true,
    })
    if not eligible then return invitationFailure(reason) end
    if relationshipState(relationship) ~= "friend" then
        return invitationFailure("visitor_relationship_not_friendly")
    end
    base, reason = activePlayerBase(player)
    if not base then return invitationFailure(reason) end
    return {
        eligible = true,
        reason = "eligible",
        baseID = tostring(base.id or ""),
        accessClass = "player_visitor",
        purpose = "invited_visit",
    }
end

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

local function resolveInvitationSite(record, player, baseContext, options)
    local resolver = PNC.Semantics and PNC.Semantics.CampSiteResolver
    local zombie = liveBody(record)
    local targets = {
        {
            kind = "camp_site",
            scope = "room",
            radius = 32,
        },
        {
            kind = "camp_site",
            scope = "campfire",
            radius = 32,
        },
    }
    local context
    local site
    local reason
    local x
    local y
    if not resolver or type(resolver.Resolve) ~= "function" then
        return nil, "camp_site_resolver_unavailable"
    end
    context = {
        origin = player,
        selectionOrigin = player,
        player = player,
        body = zombie,
        record = record,
        npcID = recordID(record),
        requestID = "ambient_visit_invite:"
            .. tostring(options and options.requestID or "direct"),
        baseID = baseContext and baseContext.base
            and baseContext.base.id or nil,
    }
    for _, target in ipairs(targets) do
        site, reason = resolver.Resolve(target, context)
        x, y = sitePoint(site)
        if site and pointInBase(baseContext, x, y) then
            return site, nil
        end
        if site then reason = "visitor_site_outside_base" end
    end
    return nil, reason or "visitor_site_unavailable"
end

-- Authoritative invitation entry point. The conversation authority supplies
-- the validated conversation token and relationship; this service still
-- rechecks the base and resolves the site on the server. The client never
-- submits an object, room, or campfire identity.
function Service.Invite(recordOrID, player, relationship, options)
    local record = resolveRecord(recordOrID)
    local preview
    local base
    local reason
    local baseContext
    local site
    local started
    local result
    options = type(options) == "table" and options or {}
    if options.authorized ~= true then
        return false, "ambient_visit_authorization_required"
    end
    preview = Service.GetInvitationPreview(record, player, relationship)
    if not preview.eligible then return false, preview.reason end
    base, reason = activePlayerBase(player)
    if not base then return false, reason end
    baseContext, reason = baseZone(base)
    if not baseContext then return false, reason end
    site, reason = resolveInvitationSite(
        record,
        player,
        baseContext,
        options
    )
    if not site then return false, reason end
    started, reason, result = Service.Begin(record, site, {
        authorized = true,
        accessClass = "player_visitor",
        purpose = "invited_visit",
        sourceID = "conversation_invite:" .. tostring(base.id or ""),
        durationHours = options.durationHours
            or Service.DEFAULT_DURATION_HOURS,
        at = options.at,
    })
    if not started then return false, reason end
    result = result or {}
    result.baseID = tostring(base.id or "")
    result.siteLabel = site.label
    return true, reason or "ambient_visit_started", result
end

-- Convert the already-selected mobile shelter target into one semantic room
-- lease after the actor reaches it. This is deliberately called from the
-- arrival edge, never from the world scheduler, so room discovery is paid
-- once per target and the result is shared by the group.
function Service.TryStartMobileShelter(record, zombie, order, at)
    local runtime
    local state
    local key
    local current
    local site
    local reason
    local started
    if type(order) ~= "table"
        or tostring(order.kind or "") ~= tostring(Const.ORDER_ROAM or "roam")
        or tostring(order.roamMode or "") ~= "shelter"
        or order.ambientMobile ~= true
        or tostring(order.ambientObjective or "") ~= "shelter"
    then
        return false, "not_mobile_shelter_order"
    end
    current = worldHours(at)
    if Service.IsActive(record, current) then
        return true, "mobile_shelter_active"
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    key = mobileShelterKey(order)
    state = runtime.ambientMobileShelter or {}
    if state.key ~= key then
        state = { key = key }
        runtime.ambientMobileShelter = state
    end
    if current < number(state.retryAt, 0) then
        return false, state.reason or "mobile_shelter_retry_deferred"
    end
    site, reason = resolveMobileShelterSite(record, zombie, order, current)
    if not site then
        state.reason = reason or "mobile_shelter_room_missing"
        state.retryAt = current + Service.MOBILE_SHELTER_RETRY_HOURS
        state.lastAttemptAt = current
        return false, state.reason
    end
    started, reason = Service.Begin(record, site, {
        authorized = true,
        accessClass = "ai_faction_ambient",
        purpose = "mobile_night_shelter",
        sourceID = key,
        durationHours = Service.MOBILE_SHELTER_DURATION_HOURS,
        at = current,
        roamModes = { shelter = true },
    })
    if not started then
        state.reason = reason or "mobile_shelter_lease_failed"
        state.retryAt = current + Service.MOBILE_SHELTER_RETRY_HOURS
        state.lastAttemptAt = current
        return false, state.reason
    end
    runtime.ambientMobileShelter = nil
    return true, reason or "mobile_shelter_started"
end

function Service.ReleaseMobileShelter(recordOrID, reason, at)
    local lease = leaseFor(recordOrID)
    if not lease or lease.purpose ~= "mobile_night_shelter" then
        return false, "mobile_shelter_missing"
    end
    return Service.Release(recordOrID,
        reason or "mobile_shelter_released", at)
end

function Service.Release(recordOrID, reason, at)
    local lease
    local record
    local id
    local body
    local current
    local ownsOrder
    local restored = false
    lease, record = leaseFor(recordOrID)
    if not lease then return false, "ambient_visit_missing" end
    id = tostring(lease.npcID or "")
    if not record and PNC.Registry and PNC.Registry.Get then
        record = PNC.Registry.Get(id)
    end
    body = record and liveBody(record) or nil
    if record and record.runtime and record.runtime.roamAmbient
        and PNC.RoamAmbient and PNC.RoamAmbient.Stop
    then
        pcall(PNC.RoamAmbient.Stop, record, body,
            reason or "ambient_visit_released", "movement")
    end
    current = record and record.orderSpec or nil
    ownsOrder = orderIsLease(record, lease)
    if record and record.runtime then record.runtime.ambientVisit = nil end
    if record and ownsOrder then
        if lease.previousOrder then
            restored = setOrder(record, primitiveCopy(lease.previousOrder))
        else
            restored = setOrder(record, {
                kind = Const.ORDER_GUARD or "guard",
                x = current and current.x or record.x,
                y = current and current.y or record.y,
                z = current and current.z or record.z,
            })
        end
    end
    lease.status = "released"
    lease.releasedAt = worldHours(at)
    lease.releaseReason = text(reason, "ambient_visit_released", 64)
    Service.Runtime.leases[lease.id] = nil
    if Service.Runtime.byNPC[id] == lease.id then
        Service.Runtime.byNPC[id] = nil
    end
    if record then notify(record, "ambient_visit_released") end
    return true, restored and "ambient_visit_released"
        or "ambient_visit_released_order_changed"
end

function Service.Pump(at, budget)
    local expired = {}
    local processed = 0
    local current = worldHours(at)
    budget = math.max(1, math.floor(number(budget, Service.PUMP_BUDGET)))
    for leaseID, lease in pairs(Service.Runtime.leases) do
        if processed >= budget then break end
        if lease and lease.status == "active" then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(lease.npcID) or nil
            local hostile = record and record.hostility
                and (record.hostility.attackPlayers == true
                    or record.hostility.attackNPCs == true)
            local invalid = not record or record.alive == false
                or hostile or not orderIsLease(record, lease)
            if current >= number(lease.expiresAt, math.huge)
                or invalid
            then
                expired[#expired + 1] = {
                    id = leaseID,
                    reason = current >= number(lease.expiresAt, math.huge)
                        and "ambient_visit_expired"
                        or "ambient_visit_invalidated",
                }
            end
            processed = processed + 1
        end
    end
    for index = 1, #expired do
        Service.Release(expired[index].id, expired[index].reason, current)
    end
    return #expired
end

function Service.ActiveCount()
    return activeCount()
end

return Service
