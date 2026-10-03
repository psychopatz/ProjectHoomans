local Group = PNC.Conversation.Group
local Internal = Group.Internal or {}
Group.Internal = Internal

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Group.MAX_INPUT_LENGTH
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function normalizedName(value, resolver)
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

local function audit(group, eventName, data, options)
    local diagnostics = group and group.semanticDiagnostics or nil
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
    audit(self, "semantic.group.turn", {
        groupID = self.id,
        turnID = turn.id,
        participantCount = turn.participantCount,
        rawText = turn.rawText,
    }, { requestID = turn.id })
    return turn
end


Internal.BoundedText = boundedText
Internal.NormalizedName = normalizedName
Internal.SafeID = safeID
Internal.RuntimeNow = runtimeNow
Internal.Audit = audit
Internal.CopyIDs = copyIDs
Internal.MemberFor = memberFor
Internal.BuildMembers = buildMembers
