-- Action-plan providers for camp arrival verification and order commit.
--
-- MOVE_TO remains the existing path owner. These providers only validate the
-- live destination and then cross the durable-order boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.ActionPlanService
local Registry = PNC.Registry
local Geometry = PNC.Semantics.CampSiteGeometry
local CampSite = PNC.Semantics.CampSite
local WorldTargets = PNC.Semantics.WorldTargetResolver
local Provider = {}

Provider.VERIFY_TIMEOUT_MS = 8000

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function number(value)
    return tonumber(value)
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function liveBody(record)
    if not Registry or type(Registry.GetLiveZombie) ~= "function" then
        return nil
    end
    local ok, body = pcall(Registry.GetLiveZombie, record and record.id)
    return ok and body or nil
end

local function parameters(step)
    return step and type(step.parameters) == "table"
        and step.parameters or {}
end

local function siteFor(step)
    local value = parameters(step).site
    return type(value) == "table" and value or nil
end

local function bodySquare(body, record)
    local square = call(body, "getCurrentSquare")
    if square then return square end
    local x = number(call(body, "getX") or record and record.x)
    local y = number(call(body, "getY") or record and record.y)
    local z = number(call(body, "getZ") or record and record.z) or 0
    if x == nil or y == nil or not Geometry then return nil end
    return Geometry.GetSquare(nil, x, y, z)
end

local function distanceTo(site, body, record)
    local x = number(call(body, "getX") or record and record.x)
    local y = number(call(body, "getY") or record and record.y)
    local z = number(call(body, "getZ") or record and record.z) or 0
    local sx = number(site and site.x)
    local sy = number(site and site.y)
    local sz = number(site and site.z) or 0
    if x == nil or y == nil or sx == nil or sy == nil then return nil end
    return math.sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy)),
        math.abs(z - sz)
end

local function verifySite(site, body, record)
    if type(site) ~= "table" then return false, "camp_site_missing" end
    if not body then return false, "camp_body_unavailable" end
    if site.scope == CampSite.SCOPES.ROOM then
        local square = bodySquare(body, record)
        if not square then return false, "camp_square_unavailable" end
        if not Geometry or type(Geometry.MatchesRoom) ~= "function" then
            return false, "camp_geometry_unavailable"
        end
        if not Geometry.MatchesRoom(square, site) then
            return false, "camp_room_not_reached"
        end
        return true
    end

    local distance, zDistance = distanceTo(site, body, record)
    local radius = math.max(1, number(site.radius) or 3)
    if not distance or zDistance > 1 then
        return false, "campfire_not_reached"
    end
    if distance > math.max(radius, number(site.stopDistance) or 1.25) then
        return false, "campfire_not_reached"
    end
    if not WorldTargets or type(WorldTargets.Resolve) ~= "function" then
        return false, "campfire_resolver_unavailable"
    end
    local resolved = WorldTargets.Resolve({
        kind = "campfire",
        targetID = site.campfireID or site.siteID,
        radius = math.max(4, radius + 2),
    }, { origin = body, record = record })
    if not resolved then return false, "campfire_gone" end
    return true
end

local function setActive(record, action)
    if not record then return end
    record.activeJob = "SemanticActionPlan"
    record.activeBehavior = "SemanticActionPlan:" .. tostring(action)
end

local function clearActive(record)
    if not record then return end
    record.activeJob = nil
    record.activeBehavior = nil
end

function Provider.Resolve(_, step, record)
    if not record or record.alive == false then
        return nil, "npc_unavailable"
    end
    local site = siteFor(step)
    if not site then return nil, "camp_site_missing" end
    return { site = site, startedAt = nil }
end

function Provider.Start(_, step, record)
    local assignment = step and step.assignment
    if type(assignment) ~= "table" or type(assignment.site) ~= "table" then
        return { blocked = true, reason = "camp_site_missing" }
    end
    assignment.startedAt = now()
    setActive(record, "VERIFY_CAMP_SITE")
    return { state = "EXECUTING" }
end

function Provider.Tick(_, step, record)
    local assignment = step and step.assignment
    local site = assignment and assignment.site
    local body = liveBody(record)
    local ok
    local reason
    local startedAt
    if type(assignment) ~= "table" or type(site) ~= "table" then
        return { blocked = true, reason = "camp_site_missing" }
    end
    startedAt = number(assignment.startedAt) or now()
    assignment.startedAt = startedAt
    ok, reason = verifySite(site, body, record)
    if ok then
        return { complete = true, result = {
            siteID = site.siteID,
            scope = site.scope,
            label = site.label,
        } }
    end
    if now() - startedAt >= Provider.VERIFY_TIMEOUT_MS then
        clearActive(record)
        return { blocked = true, reason = reason or "camp_arrival_timeout" }
    end
    setActive(record, "VERIFY_CAMP_SITE")
    return { state = "EXECUTING", diagnostics = { reason = reason } }
end

function Provider.Cancel(_, _, record)
    clearActive(record)
    return true
end

local CommitProvider = {}

local function sameOrder(order, site)
    if type(order) ~= "table" or type(site) ~= "table" then return false end
    return tostring(order.kind or "") == tostring(PNC.Const
        and PNC.Const.ORDER_CAMP or "camp")
        and tostring(order.siteID or order.campId or "")
            == tostring(site.siteID or "")
        and tostring(order.scope or order.siteScope or "") == tostring(site.scope)
end

function CommitProvider.Resolve(_, step, record)
    if not record or record.alive == false then
        return nil, "npc_unavailable"
    end
    local site = siteFor(step)
    if not site then return nil, "camp_site_missing" end
    return { site = site }
end

function CommitProvider.Start(_, step, record)
    local assignment = step and step.assignment
    local site = assignment and assignment.site
    local body = liveBody(record)
    local ok
    local reason
    if not site then return { blocked = true, reason = "camp_site_missing" } end
    ok, reason = verifySite(site, body, record)
    if not ok then return { blocked = true, reason = reason } end
    if sameOrder(record.orderSpec, site) then
        clearActive(record)
        return { complete = true, result = { siteID = site.siteID } }
    end
    local orderSystem = PNC.OrderSystem
    if not orderSystem or type(orderSystem.SetOrder) ~= "function" then
        return { blocked = true, reason = "order_system_unavailable" }
    end
    local order = {
        kind = PNC.Const and PNC.Const.ORDER_CAMP or "camp",
        scope = site.scope,
        siteScope = site.scope,
        siteID = site.siteID,
        roomID = site.roomID,
        buildingID = site.buildingID,
        roomType = site.roomType,
        roomName = site.roomName,
        roomBounds = site.roomBounds,
        campfireID = site.campfireID,
        x = site.x,
        y = site.y,
        z = site.z,
        radius = site.radius,
        campId = site.siteID or ("camp:" .. tostring(record.id)),
        resourceRadius = site.resourceRadius,
    }
    local success = pcall(orderSystem.SetOrder, record, order)
    if not success then
        return { blocked = true, reason = "camp_order_commit_failed" }
    end
    if not sameOrder(record.orderSpec, site) then
        return { blocked = true, reason = "camp_order_not_committed" }
    end
    clearActive(record)
    return { complete = true, result = {
        siteID = site.siteID,
        scope = site.scope,
        label = site.label,
    } }
end

function CommitProvider.Tick(_, step, record)
    return CommitProvider.Start(nil, step, record)
end

function CommitProvider.Cancel(_, _, record)
    clearActive(record)
    return true
end

if Service and type(Service.RegisterProvider) == "function" then
    Service.RegisterProvider("VERIFY_CAMP_SITE", Provider)
    Service.RegisterProvider("COMMIT_CAMP_ORDER", CommitProvider)
end

return {
    Verify = Provider,
    Commit = CommitProvider,
}
