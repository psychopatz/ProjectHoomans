-- Server-authoritative conversation recruitment requests.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local Rules = PNC.Conversation.Rules
local History = PNC.Conversation.History
local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local send = Internal.Send
local worldAgeHours = Internal.WorldAgeHours
local recruitReplyKey = Internal.RecruitReplyKey
local relationshipCopy = Internal.RelationshipCopy
local relationshipDelta = Internal.RelationshipDelta
local personalRelationshipCommands = Internal.PersonalRelationshipCommands

function Authority.HandleRecruit(player, args)
    args = type(args) == "table" and args or {}
    local requestID = tostring(args.requestID or "")
    local record = PNC.Registry.Get(args.npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    local function reject(rejection, details)
        local payload = {
            requestID = requestID,
            success = false,
            reason = rejection,
            npcID = tostring(args.npcID or ""),
            responseKey = recruitReplyKey(
                args.npcID,
                rejection,
                nil,
                worldAgeHours()
            ),
        }
        for key, value in pairs(type(details) == "table" and details or {}) do
            payload[key] = value
        end
        send(player, PNC.Const.CMD_CONVERSATION_RECRUIT_RESULT, payload)
        return false, rejection
    end
    if requestID == "" then return false, "request_id_required" end
    if not ok or not lease then return reject(reason or "invalid_lease") end
    lease.processedConversationRequests = lease.processedConversationRequests or {}
    local relationshipCommands = personalRelationshipCommands()
    if lease.processedConversationRequests[requestID] then
        return reject("replayed_request")
    end
    if not requestIsCurrent(args) then return reject("registry_mismatch") end
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then return reject(reason) end
    if context.audiences.hostile then return reject("hostile_audience") end
    local attemptID = "recruitment:" .. tostring(record.id)
    local attemptPolicy = { scope = "pair", cooldownHours = 6 }
    local attempt = History.Get(attemptID, attemptPolicy, context)
    local available, availabilityReason = Rules.CheckRepeat(
        attemptPolicy, attempt, context.worldAgeHours
    )
    if not available then return reject(availabilityReason) end
    local service = PNC.Recruitment or PNC.DebugCompanionRecruit
    if not service or not service.TryConversation then
        return reject("recruitment_service_unavailable")
    end
    local result
    ok, reason, result = service.TryConversation(
        player, { npcID = tostring(args.npcID or "") }, context.relationship
    )
    lease.processedConversationRequests[requestID] = true
    if not ok then
        local before = relationshipCopy(context.relationship)
        local after = before
        local delta = { approval = -2, respect = -1, familiarity = 0 }
        local appliedResult
        if relationshipCommands
            and relationshipCommands.ApplyConversationEffect then
            local applied
            applied, _, appliedResult = relationshipCommands.ApplyConversationEffect(
                record.id,
                context.playerEntityKey,
                { approval = -2, respect = -1 },
                {
                    blockID = "projecthoomans:recruitment",
                    choiceID = "recruit",
                    outcomeID = "rejected",
                    worldAgeHours = context.worldAgeHours,
                    sourceSystem = "recruitment",
                    interaction = {
                        kind = "recruitment",
                        source = "recruitment",
                        interactionType = "recruitment_rejected",
                        choiceID = "recruit",
                        applied = true,
                    },
                }
            )
            if applied == true and appliedResult
                and appliedResult.relationship
            then
                after = relationshipCopy(appliedResult.relationship)
                delta = relationshipDelta(before, after)
            end
        end
        History.Commit(attemptID, attemptPolicy, context, "rejected")
        return reject(reason or "recruitment_rejected", {
            relationshipBefore = before,
            relationshipAfter = after,
            relationshipDelta = delta,
            recruitment = result,
        })
    end
    History.Commit(attemptID, attemptPolicy, context, result and result.route)
    if relationshipCommands and relationshipCommands.RecordInteraction then
        relationshipCommands.RecordInteraction(
            record.id,
            context.playerEntityKey,
            {
                eventID = "conversation:recruitment:" .. tostring(record.id)
                    .. ":" .. requestID,
                kind = "recruitment",
                source = "recruitment",
                interactionType = "recruitment_accepted",
                choiceID = "recruit",
                npcTextKey = recruitReplyKey(
                    args.npcID,
                    nil,
                    result and result.route,
                    context.worldAgeHours
                ),
                applied = true,
                at = context.worldAgeHours,
                worldAgeHours = context.worldAgeHours,
            }
        )
    end
    local payload = {
        requestID = requestID,
        success = true,
        reason = reason or "recruited",
        npcID = tostring(args.npcID or ""),
        route = result and result.route,
        responseKey = recruitReplyKey(
            args.npcID,
            nil,
            result and result.route,
            context.worldAgeHours
        ),
        relationship = result and result.relationship,
        registryFingerprint = Registry.GetFingerprint(),
        close = true,
        closeReason = "recruited",
    }
    send(player, PNC.Const.CMD_CONVERSATION_RECRUIT_RESULT, payload)
    lease.conversationState = nil
    return true, "recruited"
end

return Authority
