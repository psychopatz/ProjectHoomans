-- Server-authoritative category selection, choice validation, effects, and history.
if isClient and isClient() and (not isServer or not isServer()) then return end

require "PNC/Conversation/PNC_ConversationHistory"
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Authority = PNC.Conversation.Authority or {}
PNC.Conversation.Authority = Authority
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Rules = PNC.Conversation.Rules
local History = PNC.Conversation.History
local TextLoader = PNC.Conversation.TextLoader

local function relationshipCopy(value)
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = value.state,
    }
end

local function relationshipDelta(before, after)
    before = relationshipCopy(before)
    after = relationshipCopy(after)
    return {
        approval = after.approval - before.approval,
        respect = after.respect - before.respect,
        familiarity = after.familiarity - before.familiarity,
    }
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function send(player, command, payload)
    local internal = PNC.Network and PNC.Network.Internal
    if not internal or not internal.SendToPlayer then return false end
    return internal.SendToPlayer(player, command, payload)
end

local RECRUIT_REPLY_VARIANTS = {
    admire = {
        "response.recruit.admire.1",
        "response.recruit.admire.2",
        "response.recruit.admire.3",
    },
    fear = {
        "response.recruit.fear.1",
        "response.recruit.fear.2",
        "response.recruit.fear.3",
    },
    relationship = {
        "response.recruit.reject.relationship.1",
        "response.recruit.reject.relationship.2",
        "response.recruit.reject.relationship.3",
    },
    leader = {
        "response.recruit.reject.leader.1",
        "response.recruit.reject.leader.2",
    },
    cooldown = {
        "response.recruit.reject.cooldown.1",
        "response.recruit.reject.cooldown.2",
    },
    general = {
        "response.recruit.reject.general.1",
        "response.recruit.reject.general.2",
        "response.recruit.reject.general.3",
    },
}

local function stableVariantIndex(value, count)
    local hash = 7
    value = tostring(value or "")
    for index = 1, #value do
        hash = (hash * 31 + string.byte(value, index)) % 2147483647
    end
    return (hash % count) + 1
end

local function recruitReplyKey(npcID, reason, route, worldAgeHours)
    local group = route == "admire" and "admire"
        or route == "fear" and "fear"
        or reason == "relationship_threshold" and "relationship"
        or reason == "leader_active" and "leader"
        or reason == "cooldown_active" and "cooldown"
        or "general"
    local variants = RECRUIT_REPLY_VARIANTS[group]
    local index = stableVariantIndex(table.concat({
        tostring(npcID or ""), tostring(reason or ""), tostring(route or ""),
        tostring(math.floor(tonumber(worldAgeHours) or 0) / 24),
    }, ":"), #variants)
    return variants[index]
end

local function relationshipCategory(record, relationship)
    local explicit = record and (
        record.conversationRelationship or record.relationshipCategory
    )
    if explicit == "Lover" or explicit == "Member"
        or explicit == "Acquaintance" or explicit == "FirstMeet"
    then return explicit end
    if record and (record.recruited == true or record.ownerUsername) then
        return "Member"
    end
    if relationship and relationship.exists ~= false then return "Acquaintance" end
    return "FirstMeet"
end

local function audienceMap(record, category)
    local hostile = tostring(record and record.faction or "") == "hostile"
        and (type(record.hostility) ~= "table"
            or record.hostility.attackPlayers ~= false)
    return {
        hostile = hostile,
        neutral = not hostile and category ~= "Member" and category ~= "Lover",
        member = not hostile and category == "Member",
        special = not hostile and category == "Lover",
        shared = true,
    }
end

function Authority.BuildContext(player, record, token)
    if not player or not record then return nil, "actors_unavailable" end
    local playerEntityKey, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "conversation_block",
        worldAgeHours = worldAgeHours(),
    })
    if not playerEntityKey then return nil, reason end
    local parsed = PNC.EntityRef and PNC.EntityRef.Parse
        and PNC.EntityRef.Parse(playerEntityKey) or nil
    local relationship = PNC.Relationships and PNC.Relationships.Get
        and PNC.Relationships.Get(record.id, playerEntityKey) or nil
    relationship = type(relationship) == "table" and relationship or {}
    relationship.morale = record.social and record.social.morale or 0
    local category = relationshipCategory(record, relationship)
    local playerProfile = PNC.SocialProfiles
        and PNC.SocialProfiles.GetPlayerProfile
        and PNC.SocialProfiles.GetPlayerProfile(
            parsed and parsed.characterUUID or playerEntityKey
        ) or nil
    local context = {
        player = player,
        npcRecord = record,
        npcID = tostring(record.id),
        token = tostring(token or ""),
        playerEntityKey = playerEntityKey,
        characterUUID = parsed and parsed.characterUUID or playerEntityKey,
        relationship = relationship,
        relationshipState = category,
        playerSocialProfile = playerProfile,
        playerPersonality = playerProfile,
        npcPersonality = record.personality or record.socialProfile,
        npcTraits = record.traits or record.socialTraits,
        audiences = audienceMap(record, category),
        allowHostileParley = tostring(record.faction or "") == "hostile",
        worldAgeHours = worldAgeHours(),
        hour = worldAgeHours() % 24,
        worldID = tostring(getWorld and getWorld() or "world"),
    }
    context.historyLookup = function(subjectID, scope)
        return History.Get(subjectID, { scope = scope }, context)
    end
    context.blockValidator = function(block)
        return TextLoader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
    end
    context.categoryValidator = function(categoryDefinition)
        return TextLoader.EnsureSource(
            categoryDefinition.textSource,
            { categoryDefinition.labelKey }
        )
    end
    return context
end

local function validateLease(player, record, token)
    local zombie = record and PNC.Registry.GetLiveZombie(record.id) or nil
    local lease = record and record.runtime and record.runtime.conversationLease
    if not lease or tostring(lease.token or "") ~= tostring(token or "") then
        return false, "invalid_lease"
    end
    local ok, reason = PNC.ConversationScene.Begin(record, zombie, player, token, {
        maximumDistance = lease.maximumDistance,
        dangerRadius = lease.dangerRadius,
        allowHostileParley = lease.hostileParley == true,
    })
    return ok == true, reason, lease
end

local function requestIsCurrent(args)
    return tostring(args.registryFingerprint or "") == Registry.GetFingerprint()
end

function Authority.HandleCategory(player, args)
    args = type(args) == "table" and args or {}
    if type(args.requestID) ~= "string" or args.requestID == "" then
        return false, "request_id_required"
    end
    local record = PNC.Registry.Get(args.npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    lease.processedConversationRequests =
        lease.processedConversationRequests or {}
    if lease.processedConversationRequests[args.requestID] then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = "replayed_request",
            npcID = tostring(args.npcID or ""),
        })
        return false, "replayed_request"
    end
    if not requestIsCurrent(args) then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false,
            reason = "registry_mismatch",
            npcID = tostring(args.npcID or ""),
            registryFingerprint = Registry.GetFingerprint(),
        })
        return false, "registry_mismatch"
    end
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local categoryEligible
    categoryEligible, reason = Selector.IsCategoryEligible(
        args.categoryID,
        context,
        args.categoryID == "projecthoomans:greetings"
            and context.audiences.hostile == true
    )
    if not categoryEligible then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
            categoryID = args.categoryID,
        })
        return false, reason
    end
    local categoryHistory = History.Get(
        "category:" .. tostring(args.categoryID or ""),
        { scope = "pair" },
        context
    )
    context.historySlot = categoryHistory and categoryHistory.useCount or 0
    local block, selection = Selector.SelectBlock(args.categoryID, context)
    if not block then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false,
            reason = "no_eligible_block", categoryID = args.categoryID,
            npcID = tostring(args.npcID or ""),
        })
        return false, "no_eligible_block"
    end
    lease.conversationState = {
        blockID = block.id,
        nodeID = block.entryNode,
        categoryID = block.category,
        registryFingerprint = Registry.GetFingerprint(),
        processed = {},
    }
    lease.processedConversationRequests[args.requestID] = {
        kind = "category",
    }
    send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
        requestID = args.requestID,
        success = true,
        npcID = record.id,
        blockID = block.id,
        nodeID = block.entryNode,
        categoryID = block.category,
        registryFingerprint = Registry.GetFingerprint(),
        selection = selection,
    })
    return true, block.id
end

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
        if PNC.Relationships
            and PNC.Relationships.ApplyConversationEffect
        then
            local applied
            applied, _, appliedResult = PNC.Relationships.ApplyConversationEffect(
                record.id,
                context.playerEntityKey,
                { approval = -2, respect = -1 },
                {
                    blockID = "projecthoomans:recruitment",
                    choiceID = "recruit",
                    outcomeID = "rejected",
                    worldAgeHours = context.worldAgeHours,
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

function Authority.HandleChoice(player, args)
    args = type(args) == "table" and args or {}
    if type(args.requestID) ~= "string" or args.requestID == "" then
        return false, "request_id_required"
    end
    local record = PNC.Registry.Get(args.npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    if lease and lease.processedConversationRequests
        and lease.processedConversationRequests[args.requestID]
    then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = "replayed_request",
            npcID = tostring(args.npcID or ""),
        })
        return false, "replayed_request"
    end
    local state = lease and lease.conversationState or nil
    if not ok or not state then reason = reason or "conversation_state_missing" end
    if ok and (not requestIsCurrent(args)
        or state.registryFingerprint ~= Registry.GetFingerprint())
    then ok, reason = false, "registry_mismatch" end
    if ok and (state.blockID ~= args.blockID or state.nodeID ~= args.nodeID) then
        ok, reason = false, "stale_node"
    end
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local block = Registry.GetBlock(state.blockID)
    local choice = Selector.GetChoice(block, state.nodeID, args.choiceID)
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    context.blockID = block and block.id
    context.choiceID = choice and choice.id
    local eligible
    eligible, reason = Selector.IsChoiceEligible(
        block, state.nodeID, choice, context
    )
    if not eligible then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local subjectID = table.concat({ block.id, state.nodeID, choice.id }, "/")
    context.historySlot = (History.Get(subjectID, choice["repeat"], context)
        or { useCount = 0 }).useCount or 0
    local outcome = Selector.SelectOutcome(block, state.nodeID, choice, context)
    if not outcome then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = "no_eligible_outcome",
            npcID = tostring(args.npcID or ""),
        })
        return false, "no_eligible_outcome"
    end
    context.outcomeID = outcome.id
    local relationshipBefore = relationshipCopy(context.relationship)
    local effectResults
    ok, reason = Rules.ValidateEffects(outcome.effects, context)
    if ok then ok, reason, effectResults = Rules.ApplyEffects(outcome.effects, context) end
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local relationshipAfter = relationshipBefore
    if PNC.Relationships and PNC.Relationships.Get then
        relationshipAfter = relationshipCopy(PNC.Relationships.Get(
            record.id, context.playerEntityKey
        ))
    end
    History.Commit(block.id, block["repeat"], context, outcome.id)
    History.Commit(subjectID, choice["repeat"], context, outcome.id)
    History.Commit(
        "category:" .. tostring(state.categoryID),
        { scope = "pair" },
        context,
        outcome.id
    )
    state.nodeID = outcome.next
    local payload = {
        requestID = args.requestID,
        success = true,
        npcID = record.id,
        blockID = block.id,
        nodeID = args.nodeID,
        choiceID = choice.id,
        outcomeID = outcome.id,
        responseKey = outcome.responseKey,
        nextNodeID = outcome.next,
        close = outcome.close == true,
        closeReason = outcome.close == true and table.concat({
            "authored_outcome", block.id, state.nodeID, choice.id, outcome.id,
        }, ":") or nil,
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipAfter,
        relationshipDelta = relationshipDelta(
            relationshipBefore, relationshipAfter
        ),
        effectResults = effectResults,
        registryFingerprint = Registry.GetFingerprint(),
    }
    state.processed[args.requestID] = payload
    lease.processedConversationRequests = lease.processedConversationRequests or {}
    lease.processedConversationRequests[args.requestID] = payload
    send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, payload)
    if payload.close then lease.conversationState = nil end
    return true, outcome.id
end

return Authority
