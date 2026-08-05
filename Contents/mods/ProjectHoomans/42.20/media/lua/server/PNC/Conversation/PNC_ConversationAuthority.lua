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
    ok, reason = Rules.ValidateEffects(outcome.effects, context)
    if ok then ok, reason = Rules.ApplyEffects(outcome.effects, context) end
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
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
