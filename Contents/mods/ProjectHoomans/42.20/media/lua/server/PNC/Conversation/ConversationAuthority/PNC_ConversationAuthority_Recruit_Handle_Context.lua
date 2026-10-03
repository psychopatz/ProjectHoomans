-- Server-side recruitment request and evaluation boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local RecruitmentContext = {}

local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local personalRelationshipCommands = Internal.PersonalRelationshipCommands

local function rejected(state, reason)
    state.reason = reason
    return state
end

function RecruitmentContext.Build(player, args)
    args = type(args) == "table" and args or {}
    local state = {
        player = player,
        args = args,
        requestID = tostring(args.requestID or ""),
        record = PNC.Registry.Get(args.npcID),
    }
    local ok, reason, lease = validateLease(
        player,
        state.record,
        args.token
    )
    state.lease = lease
    if state.requestID == "" then
        state.silent = true
        return rejected(state, "request_id_required")
    end
    if not ok or not lease then
        return rejected(state, reason or "invalid_lease")
    end
    lease.processedConversationRequests =
        lease.processedConversationRequests or {}
    state.relationshipCommands = personalRelationshipCommands()
    if lease.processedConversationRequests[state.requestID] then
        return rejected(state, "replayed_request")
    end
    if not requestIsCurrent(args) then
        return rejected(state, "registry_mismatch")
    end
    local context
    context, reason = Authority.BuildContext(player, state.record, args.token)
    if not context then return rejected(state, reason) end
    if context.audiences.hostile then
        return rejected(state, "hostile_audience")
    end
    state.context = context
    state.attemptID = "recruitment:" .. tostring(state.record.id)
    state.attemptPolicy = { scope = "pair" }
    local service = PNC.Recruitment or PNC.DebugCompanionRecruit
    if not service or not service.TryConversation then
        return rejected(state, "recruitment_service_unavailable")
    end
    state.accepted, state.evaluationReason, state.result = service.TryConversation(
        player,
        { npcID = tostring(args.npcID or "") },
        context.relationship
    )
    lease.processedConversationRequests[state.requestID] = true
    return state
end

Internal.RecruitHandleContext = RecruitmentContext

return RecruitmentContext
