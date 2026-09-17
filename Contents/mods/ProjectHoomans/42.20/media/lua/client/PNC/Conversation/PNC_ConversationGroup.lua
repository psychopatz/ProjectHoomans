-- Client-local group conversation coordinator.
--
-- Nearby mode has one visible conversation queue, but each participant keeps
-- its own semantic router, context, and authoritative action request.  This
-- module only coordinates those boundaries; it never mutates world state.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Group = PNC.Conversation.Group or {}
PNC.Conversation.Group = Group

Group.VERSION = 1
Group.MAX_PARTICIPANTS = 12
Group.MAX_EVENTS = 16
Group.MAX_INPUT_LENGTH = 4000

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Group.MAX_INPUT_LENGTH
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function normalizedName(value)
    local resolver = PNC.Semantics and PNC.Semantics.EntityResolver
    if resolver and type(resolver.NormalizeName) == "function" then
        return resolver.NormalizeName(value)
    end
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w%s']", " ")
    value = string.gsub(value, "%s+", " ")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function firstName(value)
    local normalized = string.gsub(tostring(value or ""), "^%s+", "")
    normalized = string.gsub(normalized, "%s+$", "")
    return string.match(normalized, "^(%S+)") or normalized
end

local function safeID(value)
    value = tostring(value or "unknown")
    value = string.gsub(value, "[^%w_%-]", "_")
    return string.sub(value, 1, 64)
end

local function runtimeNow()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return PNC.Core.Now()
    end
    if getTimeInMillis then return getTimeInMillis() end
    if getTimestampMs then return getTimestampMs() end
    return 0
end

local function audit(eventName, data, options)
    local diagnostics = PNC.Semantics
        and PNC.Semantics.SemanticDiagnostics or nil
    if not diagnostics
        or type(diagnostics.IsEnabled) ~= "function"
        or diagnostics.IsEnabled() ~= true
        or type(diagnostics.Record) ~= "function"
    then
        return false
    end
    return diagnostics.Record(eventName, data, options)
end

local function hostID(host, entry)
    return tostring(entry and entry.id or host and host.spec
        and host.spec.npcID or "")
end

local function hostName(host, entry)
    local context = host and host.spec and host.spec.context or {}
    return tostring(entry and entry.name or context.npcName
        or context.npcFullName or "NPC")
end

local function copyIDs(values)
    local output = {}
    for index = 1, #(values or {}) do output[index] = values[index] end
    return output
end

local function memberFor(self, value)
    local id = tostring(value or "")
    if id == "" then return nil end
    return self.memberByID and self.memberByID[id] or nil
end

local function buildMembers(hosts, entries)
    local members = {}
    local seen = {}
    for index = 1, math.min(#(hosts or {}), Group.MAX_PARTICIPANTS) do
        local host = hosts[index]
        local entry = entries and entries[index] or nil
        local id = hostID(host, entry)
        if host and id ~= "" and not seen[id] then
            local name = hostName(host, entry)
            local given = firstName(name)
            seen[id] = true
            members[#members + 1] = {
                id = id,
                name = name,
                firstName = given,
                host = host,
                entry = entry,
                index = index,
            }
        end
    end
    return members
end

local function buildEntityCandidates(members)
    local candidates = {}
    for index = 1, #(members or {}) do
        local member = members[index]
        candidates[#candidates + 1] = {
            id = member.id,
            entityType = "npc",
            name = member.name,
            fullName = member.name,
            firstName = member.firstName,
            aliases = { member.firstName, member.name },
            source = "nearby_conversation_group",
        }
    end
    return candidates
end

local function buildParticipantProjection(members)
    local output = {}
    for index = 1, #(members or {}) do
        local member = members[index]
        output[#output + 1] = {
            id = member.id,
            name = member.name,
            firstName = member.firstName,
            entityType = "npc",
        }
    end
    return output
end

function Group:Refresh()
    self.entityCandidates = buildEntityCandidates(self.members)
    self.participantProjection = buildParticipantProjection(self.members)
    self.participantIDs = {}
    for index = 1, #self.members do
        self.participantIDs[index] = self.members[index].id
    end

    for index = 1, #self.members do
        local member = self.members[index]
        local host = member.host
        local context = host and host.spec and host.spec.context or {}
        context.semanticEntityCandidates = self.entityCandidates
        context.semanticGroupID = self.id
        context.semanticGroupSize = #self.members
        context.semanticGroupParticipants = self.participantProjection
        context.semanticGroupTurn = self.turnSequence
        if host and host.spec then host.spec.context = context end
        if host then
            host.groupConversation = self
            host.groupMemberID = member.id
            host.groupPrimary = host == self.primaryHost
        end
        local session = host and host.session or nil
        if session then
            session.context = context
            session.participants = self.participantIDs
            if session.spec then
                session.spec.participants = self.participantIDs
            end
            local semanticState = session.semanticDialogueState
            if semanticState then
                local semanticParticipants =
                    buildParticipantProjection(self.members)
                local playerID = tostring(session.characterUUID or "")
                if playerID ~= "" and playerID ~= "unbound" then
                    semanticParticipants[#semanticParticipants + 1] = {
                        id = playerID,
                        name = context.playerFullName
                            or context.playerName or playerID,
                        entityType = "player",
                    }
                end
                semanticState.participants = semanticParticipants
                semanticState.participantKeys = {}
                semanticState.maxParticipants = math.max(
                    tonumber(semanticState.maxParticipants) or 1,
                    #semanticParticipants
                )
                for participantIndex = 1, #semanticParticipants do
                    local participant = semanticParticipants[
                        participantIndex
                    ]
                    semanticState.participantKeys[tostring(
                        participant.id
                    )] = true
                end
            end
        end
    end
    return self
end

function Group:Rebind(hosts, entries, primaryHost)
    self.hosts = hosts or {}
    self.entries = entries or {}
    self.members = buildMembers(self.hosts, self.entries)
    self.memberByID = {}
    for index = 1, #self.members do
        self.memberByID[self.members[index].id] = self.members[index]
    end
    self.primaryHost = primaryHost
    if not self:MemberForHost(self.primaryHost) then
        self.primaryHost = self.members[1] and self.members[1].host or nil
    end
    if not self.primaryHost or #self.members == 0 then
        return false, "group_participant_unavailable"
    end
    self:Refresh()
    return true
end

function Group:MemberForHost(host)
    for index = 1, #self.members do
        if self.members[index].host == host then return self.members[index] end
    end
    return nil
end

function Group:ViewFor(npcID)
    local member = memberFor(self, npcID)
    return member and member.host or nil
end

function Group:SpeakerFor(view)
    local member = self:MemberForHost(view)
    if not member then return nil, nil end
    return member.id, member.name
end

function Group:PrimaryView()
    return self.primaryHost
end

function Group:PrimarySession()
    return self.primaryHost and self.primaryHost.session or nil
end

function Group:RequestID(memberID)
    local turn = self.activeTurn
    local turnID = turn and turn.id or (self.id .. ":turn:0")
    return string.sub(turnID .. ":" .. safeID(memberID), 1, 128)
end

function Group:BeginTurn(value)
    self.turnSequence = self.turnSequence + 1
    local turn = {
        id = self.id .. ":turn:" .. tostring(self.turnSequence),
        rawText = boundedText(value),
        startedAt = runtimeNow(),
        participantCount = #self.members,
    }
    self.activeTurn = turn
    self.events[#self.events + 1] = turn
    while #self.events > Group.MAX_EVENTS do
        table.remove(self.events, 1)
    end
    self:Refresh()
    audit("semantic.group.turn", {
        groupID = self.id,
        turnID = turn.id,
        participantCount = turn.participantCount,
        rawText = turn.rawText,
    }, { requestID = turn.id })
    return turn
end

local function collectIDs(self, value, output, depth)
    if type(value) ~= "table" then return end
    depth = tonumber(depth) or 0
    if depth >= 5 then return end
    local id = value.id or value.entityID or value.npcID
    id = tostring(id or "")
    if id ~= "" and memberFor(self, id) then output[id] = true end
    for key, child in pairs(value) do
        if type(child) == "table"
            and (key == "target" or key == "recipient"
                or key == "actor" or key == "destination")
        then
            collectIDs(self, child, output, depth + 1)
        end
    end
end

function Group:AddressedIDs(result, rawText)
    local addressed = {}
    local ir = result and result.ir or nil
    if type(ir) == "table" then
        collectIDs(self, ir.target, addressed, 0)
        collectIDs(self, ir.recipient, addressed, 0)
        collectIDs(self, ir.destination, addressed, 0)
    end
    local count = 0
    for _ in pairs(addressed) do count = count + 1 end
    if count > 0 then return addressed end

    local normalized = normalizedName(rawText)
    if normalized == "" then return addressed end
    local padded = " " .. normalized .. " "
    for index = 1, #self.members do
        local member = self.members[index]
        local aliases = { member.firstName, member.name }
        for aliasIndex = 1, #aliases do
            local alias = normalizedName(aliases[aliasIndex])
            if alias ~= ""
                and string.find(padded, " " .. alias .. " ", 1, true)
            then
                addressed[member.id] = true
                break
            end
        end
    end
    return addressed
end

function Group:ShouldRespond(member, result, rawText)
    local addressed = self:AddressedIDs(result, rawText)
    local hasAddress = false
    for _ in pairs(addressed) do
        hasAddress = true
        break
    end
    if not hasAddress then return true end
    return addressed[member.id] == true
end

local function cloneIR(value)
    local semantics = PsychopatzCore and PsychopatzCore.Semantics
    local ir = semantics and semantics.IR or nil
    if ir and type(ir.Clone) == "function" then return ir.Clone(value) end
    return value
end

function Group:Fanout(value, primaryResult)
    local semantics = PNC.Semantics
    local input = semantics and semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    local primary = self.primaryHost
    if not internal or not primary or not primaryResult
        or type(primaryResult.ir) ~= "table"
    then
        return 0, "group_fanout_unavailable"
    end

    local decision = primaryResult.decision or {}
    if decision.giftOffer then
        -- A spoken gift has one explicit recipient in the current slice. Do
        -- not duplicate the same item transfer for every nearby participant;
        -- multi-recipient gifting gets its own negotiation round later.
        audit("semantic.group.gift_primary_only", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = "gift_recipient_selection_not_implemented",
        })
        return 0, "gift_primary_only"
    end
    if decision.route == "llm_fallback" then
        audit("semantic.group.fallback", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = "llm_fallback",
        })
        return 1, "llm_fallback"
    end

    local primaryMember = self:MemberForHost(primary)
    local queued = primaryMember
        and self:ShouldRespond(primaryMember, primaryResult, value) and 1
        or 0
    for index = 1, #self.members do
        local member = self.members[index]
        local host = member.host
        if host ~= primary and self:ShouldRespond(member, primaryResult, value) then
            local requestID = self:RequestID(member.id)
            host.semanticRequestID = requestID
            local ok, reason = pcall(function()
                local router = internal.RouterFor(host)
                if not router or type(router.ProcessIR) ~= "function" then
                    error("group_member_router_unavailable")
                end
                local context = internal.ShallowContext(host)
                local options = {
                    timestamp = internal.Now and internal.Now()
                        or runtimeNow(),
                    groupID = self.id,
                    groupTurnID = self.activeTurn and self.activeTurn.id,
                    groupMemberID = member.id,
                }
                local result = router:ProcessIR(
                    cloneIR(primaryResult.ir), context, options)
                host.lastSemanticDialogueResult = result
                if result.accepted == true then
                    if internal.RecordContextTurn then
                        internal.RecordContextTurn(host, result.ir, {
                            timestamp = options.timestamp,
                            speaker = "player",
                            source = "group_player_input",
                        })
                    end
                    local actionResult
                    if internal.DispatchAction then
                        actionResult = internal.DispatchAction(host, result, value)
                    end
                    if internal.QueueDeterministicResponse then
                        local responseQueued =
                            internal.QueueDeterministicResponse(
                            host, value, result, actionResult, {
                                groupConversation = self,
                                session = self:PrimarySession(),
                                speakerID = member.id,
                                speakerName = member.name,
                                participants = self.participantIDs,
                                groupID = self.id,
                                groupTurnID = self.activeTurn
                                    and self.activeTurn.id,
                            }
                        )
                        if responseQueued == true then
                            queued = queued + 1
                        end
                    end
                end
                audit("semantic.group.member", {
                    groupID = self.id,
                    turnID = self.activeTurn and self.activeTurn.id,
                    npcID = member.id,
                    requestID = requestID,
                    accepted = result.accepted == true,
                    route = result.decision and result.decision.route,
                    branch = result.decision and result.decision.branch,
                    action = result.ir and result.ir.action,
                }, { requestID = requestID })
            end)
            host.semanticRequestID = nil
            if not ok then
                audit("semantic.group.member_failed", {
                    groupID = self.id,
                    turnID = self.activeTurn and self.activeTurn.id,
                    npcID = member.id,
                    requestID = requestID,
                    reason = tostring(reason),
                }, { requestID = requestID })
            end
        end
    end
    if self.activeTurn then self.activeTurn.responseCount = queued end
    return queued
end

function Group:Submit(value, part)
    if self.closed == true then return false, "group_closed" end
    if self.submitting == true then return false, "group_submit_busy" end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
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
        audit("semantic.group.submit_failed", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = tostring(accepted),
        })
        return false, "group_submit_failed"
    end

    local primaryResult = primary.lastSemanticDialogueResult
    if accepted == true and primaryResult
        and primaryResult.decision
        and primaryResult.decision.route ~= "llm_fallback"
        and not primaryResult.decision.giftOffer
    then
        self:Fanout(value, primaryResult)
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
        turnSequence = 0,
        events = {},
        activeTurn = nil,
        submitting = false,
        closed = false,
    }
    setmetatable(self, { __index = Group })
    local rebound, reason = self:Rebind(hosts, entries, primaryHost)
    if not rebound then return nil, reason end
    audit("semantic.group.created", {
        groupID = self.id,
        participantCount = #self.members,
        participantIDs = copyIDs(self.participantIDs),
        mode = self.mode,
    })
    return self
end

return Group
