-- ProjectHoomans ConvoEngine semantic action contract & presentation binding for CAMP.
--
-- Keeps gameplay authority inside PNC.Client.RequestSemanticTask /
-- PNC.Semantics.TaskRequestService / PNC_SemanticCampTaskHandler, and keeps
-- client-observed camp_site hint validation & read-only discovery strictly
-- separated from mutating dispatch.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local CampAction = PNC.ConvoEngine.CampActionContract or {}
PNC.ConvoEngine.CampActionContract = CampAction

local function coreConvoModule(globalName, modulePath)
    local convo = PsychopatzCore and PsychopatzCore.ConvoEngine or nil
    if convo and type(convo[globalName]) == "table" then
        return convo[globalName]
    end
    local ok, loaded = pcall(require, modulePath)
    if ok and type(loaded) == "table" then
        return loaded
    end
    return nil
end

local function textValue(value)
    local t = type(value)
    if value == nil or t == "table" or t == "function" or t == "thread" then
        return nil
    end
    local s = tostring(value)
    return s ~= "" and s or nil
end

function CampAction.LocationPhrase(site)
    if type(site) ~= "table" then return nil end
    local label = textValue(site.label or site.siteLabel)
    if not label then
        local CampSite = PNC.Semantics and PNC.Semantics.CampSite or nil
        if CampSite and type(CampSite.DisplayLabel) == "function" then
            label = textValue(CampSite.DisplayLabel(site))
        end
    end
    if not label then return nil end
    local lowered = string.lower(label)
    local scope = string.lower(tostring(site.scope or site.siteScope or ""))
    local phrased = string.sub(lowered, 1, 4) == "the " and label or ("the " .. label)
    if scope == "campfire" or lowered == "campfire" then
        return "by " .. phrased
    end
    if scope == "room" then
        return "in " .. phrased
    end
    return "at " .. phrased
end

local function extractSiteFromTable(raw, fallbackTarget)
    if type(raw) ~= "table" then raw = {} end
    local details = type(raw.details) == "table" and raw.details or {}
    local site = type(details.site) == "table" and details.site
        or (type(raw.site) == "table" and raw.site or {})
    local hint = type(fallbackTarget) == "table"
        and (type(fallbackTarget.clientHint) == "table" and fallbackTarget.clientHint or fallbackTarget)
        or {}

    local label = textValue(raw.siteLabel or details.siteLabel or site.label or hint.label)
    local scope = textValue(raw.siteScope or details.siteScope or site.siteScope or site.scope
        or hint.siteScope or hint.scope)
    local siteID = textValue(raw.siteID or details.siteID or site.siteID or raw.campfireID or hint.siteID or hint.campfireID)
    local roomType = textValue(raw.siteRoomType or raw.roomType or details.siteRoomType or details.roomType
        or site.roomType or hint.roomType)
    local risk = textValue(raw.siteRisk or raw.risk or details.siteRisk or details.risk
        or site.risk or hint.risk)

    if not label and not scope and not siteID and not roomType then
        return nil
    end
    return {
        kind = "camp_site",
        label = label,
        scope = scope,
        siteScope = scope,
        siteID = siteID,
        roomType = roomType,
        risk = risk,
    }
end

function CampAction.FromTaskResultPayload(payload, fallbackTarget)
    payload = type(payload) == "table" and payload or {}
    local details = type(payload.details) == "table" and payload.details or {}
    local site = extractSiteFromTable(payload, fallbackTarget)
    return {
        accepted = payload.accepted == true,
        status = tostring(payload.status or (payload.accepted == true and "accepted" or "rejected")),
        reason = payload.reason,
        requestID = payload.requestID,
        planID = payload.planID or details.planID,
        data = {
            site = site,
            planID = payload.planID or details.planID,
            siteLabel = site and site.label or payload.siteLabel or details.siteLabel,
            siteScope = site and site.scope or payload.siteScope or details.siteScope,
            siteID = site and site.siteID or payload.siteID or details.siteID,
        },
    }
end

function CampAction.Dispatch(args, context, meta)
    args = type(args) == "table" and args or {}
    context = type(context) == "table" and context or {}
    meta = type(meta) == "table" and meta or {}

    local target = args.target or context.target
    local npcID = args.npcID or context.npcID or context.targetID
        or (type(context.addressee) == "table" and context.addressee.id) or nil
    local request = {
        action = "CAMP",
        intent = "REQUEST",
        speechAct = "REQUEST",
        requestID = meta.requestID or context.requestID,
        npcID = npcID,
        scope = args.scope or context.scope or "single",
        target = target,
        conversationID = context.conversationID,
        conversationToken = context.conversationToken or context.token,
    }

    local client = PNC.Client
    if client and type(client.RequestSemanticTask) == "function" then
        local ok, statusOrReason, rawResult = client.RequestSemanticTask(request, context)
        if type(rawResult) == "table" then
            return CampAction.FromTaskResultPayload(rawResult, target)
        end
        local status = ok == true and (statusOrReason == "sent" and "queued" or "accepted") or "rejected"
        return {
            accepted = ok == true,
            status = status,
            reason = ok == true and nil or tostring(statusOrReason or "camp_request_rejected"),
            requestID = request.requestID,
            data = {
                site = ok == true and extractSiteFromTable({}, target) or nil,
            },
        }
    end

    local service = PNC.Semantics and PNC.Semantics.TaskRequestService
    if service and type(service.Submit) == "function" then
        local rawResult = service.Submit(request, {
            player = context.player,
            npcID = npcID,
            scope = request.scope,
            conversationToken = request.conversationToken,
            internal = context.internal,
        })
        if type(rawResult) == "table" then
            return CampAction.FromTaskResultPayload(rawResult, target)
        end
        return {
            accepted = rawResult == true,
            status = rawResult == true and "accepted" or "rejected",
            reason = rawResult == true and nil or "camp_request_rejected",
            requestID = request.requestID,
            data = {
                site = rawResult == true and extractSiteFromTable({}, target) or nil,
            },
        }
    end

    return {
        accepted = false,
        status = "failed",
        reason = "semantic_camp_authority_unavailable",
        requestID = request.requestID,
        data = {},
    }
end

CampAction.CONTRACT = {
    id = "pnc.companion.camp",
    capability = "companion.camp",
    mode = "request_response",
    inputs = {
        target = { type = "entity.location", required = true, source = "target" },
        npcID = { type = "entity.person", required = false, source = "addressee.id" },
        scope = { type = "string", required = false },
    },
    result = {
        site = { type = "entity.location" },
        planID = { type = "string" },
        siteLabel = { type = "string" },
        siteScope = { type = "string" },
        siteID = { type = "string" },
    },
    outcomeMap = {
        pending = "pending",
        sent = "queued",
        network_queued = "queued",
        queued = "queued",
        accepted = "queued",
        completed = "completed",
        rejected = "rejected",
        failed = "failed",
    },
}

function CampAction.Register()
    local ActionContract = coreConvoModule("ActionContract", "PsychopatzCore/ConvoEngine/ActionContract")
    local TextBinding = coreConvoModule("TextBinding", "PsychopatzCore/ConvoEngine/TextBinding")
    if TextBinding and type(TextBinding.RegisterResolver) == "function" then
        TextBinding.RegisterResolver("pnc.camp.location_phrase", CampAction.LocationPhrase)
    end
    if ActionContract and type(ActionContract.Register) == "function" then
        ActionContract.Register(CampAction.CONTRACT, CampAction.Dispatch)
        return true
    end
    return false
end

CampAction.Register()

return CampAction
