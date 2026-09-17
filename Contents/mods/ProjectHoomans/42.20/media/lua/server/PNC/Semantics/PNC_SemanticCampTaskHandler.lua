-- Converts a semantic CAMP request into a verified, queued site plan.
--
-- Admission resolves a site synchronously so the dialogue layer never tells
-- the player that a camp was accepted when no safe room or campfire exists.
-- The durable camp order is committed only by the final plan step after the
-- existing movement provider reports arrival.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Requests = PNC.Semantics.TaskRequestService
local Plans = PNC.Semantics.ActionPlanService
local Resolver = PNC.Semantics.CampSiteResolver
local Handler = {}

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function upper(value)
    return string.upper(tostring(value or ""))
end

local function safePart(value, fallback)
    local result = text(value) or fallback or "unknown"
    result = string.gsub(result, "[^%w_%.:%-]", "_")
    return string.sub(result, 1, 48)
end

local function npcIDFor(request, context)
    context = type(context) == "table" and context or {}
    local recipient = request and request.recipient
    return text(context.npcID or context.targetID
        or recipient and (recipient.id or recipient.entityID))
end

local function requestIDFor(request, npcID)
    local requestID = text(request and request.requestID)
    if requestID then return requestID end
    return "generated:" .. tostring(npcID) .. ":"
        .. tostring(PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
end

local function siteTarget(site)
    return {
        kind = site.kind,
        targetID = site.siteID,
        x = site.x,
        y = site.y,
        z = site.z,
        mode = site.mode,
        stopDistance = site.stopDistance,
    }
end

local function siteParameters(site)
    return {
        site = site,
    }
end

local function buildPlan(request, context, site)
    local npcID = npcIDFor(request, context)
    local requestID = requestIDFor(request, npcID)
    local planID = "semantic:camp:" .. safePart(npcID)
        .. ":" .. safePart(requestID)
    return {
        planID = planID,
        npcID = npcID,
        requestID = requestID,
        source = request.source or "semantic_dialogue",
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = request.provenance,
        metadata = {
            taskAction = "CAMP",
            targetKind = site.kind,
            siteLabel = site.label,
            siteScope = site.scope,
            siteID = site.siteID,
            siteRoomType = site.roomType,
            siteRisk = site.risk,
        },
        interruptPolicy = "PAUSE",
        steps = {
            {
                id = "move_to_camp_site",
                action = "MOVE_TO",
                parameters = {
                    target = siteTarget(site),
                    mode = site.mode,
                    stopDistance = site.stopDistance,
                },
                onFailure = "STOP",
            },
            {
                id = "verify_camp_site",
                action = "VERIFY_CAMP_SITE",
                parameters = siteParameters(site),
                onFailure = "STOP",
            },
            {
                id = "commit_camp_order",
                action = "COMMIT_CAMP_ORDER",
                parameters = siteParameters(site),
                onFailure = "STOP",
            },
        },
    }
end

function Handler.Validate(request, context)
    if not request or request.intent ~= "REQUEST"
        or upper(request.action) ~= "CAMP"
    then
        return false, "camp_request_invalid"
    end
    if not npcIDFor(request, context) then return false, "npc_required" end
    if type(request.target) ~= "table"
        or request.target.kind ~= "camp_site"
    then
        return false, "camp_site_target_required"
    end
    return true
end

function Handler.Submit(request, context)
    context = type(context) == "table" and context or {}
    local npcID = npcIDFor(request, context)
    local selectionContext = {}
    local clientOriginated
    local clientHint
    local site
    local reason
    local plan
    local accepted
    local submitted
    for key, value in pairs(context) do selectionContext[key] = value end
    selectionContext.npcID = npcID
    selectionContext.selectionOrigin = context.player
        or context.selectionOrigin
    clientOriginated = context.player ~= nil and context.internal ~= true
    clientHint = request.target and request.target.clientHint
    if clientOriginated then
        if type(clientHint) ~= "table" then
            return {
                accepted = false,
                status = "rejected",
                action = "CAMP",
                npcID = npcID,
                request = request,
                reason = "camp_site_hint_required",
                details = { siteReason = "camp_site_hint_required" },
            }
        end
        if Resolver and type(Resolver.ValidateClientSite) == "function" then
            site, reason = Resolver.ValidateClientSite(
                request.target, selectionContext)
        else
            reason = "camp_site_hint_validator_unavailable"
        end
    elseif Resolver and type(Resolver.Resolve) == "function" then
        site, reason = Resolver.Resolve(request.target, selectionContext)
    else
        reason = "camp_site_resolver_unavailable"
    end
    if not site then
        return {
            accepted = false,
            status = "rejected",
            action = "CAMP",
            npcID = npcID,
            request = request,
            reason = reason or "camp_site_unresolved",
            details = { siteReason = reason },
        }
    end

    plan = buildPlan(request, context, site)
    accepted, submitted = Plans.Submit(plan, context)
    if accepted ~= true then
        return {
            accepted = false,
            status = "rejected",
            action = "CAMP",
            npcID = npcID,
            request = request,
            reason = submitted or "camp_plan_rejected",
            details = { site = site },
        }
    end
    return {
        accepted = true,
        status = "accepted",
        action = "CAMP",
        npcID = submitted.npcID,
        planID = submitted.planID,
        request = request,
        details = {
            site = site,
            siteLabel = site.label,
            siteScope = site.scope,
            siteID = site.siteID,
            roomType = site.roomType,
            risk = site.risk,
        },
    }
end

if Requests and type(Requests.RegisterHandler) == "function" then
    Requests.RegisterHandler("CAMP", Handler)
end

return Handler
