if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local number = Internal.number
local recordID = Internal.recordID
local resolveRecord = Internal.resolveRecord
local relationshipState = Internal.relationshipState
local activePlayerBase = Internal.activePlayerBase
local baseZone = Internal.baseZone
local pointInBase = Internal.pointInBase
local sitePoint = Internal.sitePoint
local liveBody = Internal.liveBody

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

return Service
