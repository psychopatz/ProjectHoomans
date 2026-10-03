local Group = PNC.Conversation.Group
local Internal = Group.Internal
local buildMembers = Internal.BuildMembers
local safeID = Internal.SafeID
local audit = Internal.Audit
local copyIDs = Internal.CopyIDs
local isBroadcastCamp = Internal.IsBroadcastCamp

function Group:Submit(value, part)
    if self.closed == true then return false, "group_closed" end
    if self.submitting == true then return false, "group_submit_busy" end
    local input = self.dialogueInput
    local internal = input and input.Internal or nil
    local primary = self.primaryHost
    if not internal or type(internal.SubmitSingle) ~= "function"
        or not primary
    then
        return false, "group_input_unavailable"
    end

    self.submitting = true
    self:BeginTurn(value)
    primary.semanticRequestID = self:RequestID(
        tostring(primary.spec and primary.spec.npcID or "primary")
    )
    local ok, accepted, reason = pcall(
        internal.SubmitSingle, primary, value, part)
    primary.semanticRequestID = nil
    if not ok then
        self.submitting = false
        audit(self, "semantic.group.submit_failed", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = tostring(accepted),
        })
        return false, "group_submit_failed"
    end

    local primaryResult = primary.lastSemanticDialogueResult
    local primaryActionResult = primary.lastSemanticActionResult
    if accepted == true and primaryResult
        and primaryResult.decision
        and primaryResult.decision.route ~= "llm_fallback"
        and not primaryResult.decision.giftOffer
        and not primaryResult.decision.giftConsent
    then
        if isBroadcastCamp(self, primaryResult, value) then
            self:QueueGroupCampResponses(
                value, primaryResult, primaryActionResult)
        else
            self:Fanout(value, primaryResult)
        end
    end
    self.submitting = false
    return accepted, reason
end

function Group.Create(primaryHost, hosts, entries, player, options)
    options = type(options) == "table" and options or {}
    local members = buildMembers(hosts, entries)
    if not primaryHost or #members == 0 then
        return nil, "group_participant_unavailable"
    end
    local base = primaryHost.session and primaryHost.session.conversationID
        or primaryHost.spec and primaryHost.spec.npcID or "conversation"
    local self = {
        version = Group.VERSION,
        id = "group:" .. safeID(base),
        player = player,
        mode = options.mode,
        dialogueInput = options.dialogueInput,
        semanticDiagnostics = options.semanticDiagnostics,
        entityResolver = options.entityResolver,
        turnSequence = 0,
        events = {},
        activeTurn = nil,
        submitting = false,
        closed = false,
    }
    setmetatable(self, { __index = Group })
    local rebound, reason = self:Rebind(hosts, entries, primaryHost)
    if not rebound then return nil, reason end
    audit(self, "semantic.group.created", {
        groupID = self.id,
        participantCount = #self.members,
        participantIDs = copyIDs(self.participantIDs),
        mode = self.mode,
    })
    return self
end

return Group
