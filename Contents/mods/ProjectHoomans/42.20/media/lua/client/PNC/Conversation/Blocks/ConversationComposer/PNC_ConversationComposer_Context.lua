PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader

local TIME_HOURS = {
    dawn = 5.5,
    sunrise = 8,
    sunset = 15,
    dusk = 19,
    twilight = 22,
}

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function audienceMap(entry, relationshipID)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local hostility = snapshot.hostility or record.hostility or {}
    -- `record.tacticalClass == "hostile"` is the canonical tactical state.
    -- used when an organizational faction is fighting another NPC faction.
    -- Only an explicit player-hostility bit makes this player a hostile
    -- conversation audience. Missing replica data must fail closed.
    local hostile = hostility.attackPlayers == true
    return {
        hostile = hostile,
        neutral = not hostile and relationshipID ~= "Member"
            and relationshipID ~= "Lover",
        member = not hostile and relationshipID == "Member",
        special = not hostile and relationshipID == "Lover",
        shared = true,
    }
end

function Composer.BuildContext(entry, player, timeID, relationshipID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local record = entry and entry.record or {}
    local colonyManagement = state.colonyManagement or {}
    local npcID = tostring(entry and entry.id or "debug-npc")
    local relationship = Conversation.Relationship
        and Conversation.Relationship.GetPresentation(npcID) or {}
    local at = worldAgeHours()
    local context = {
        entry = entry,
        player = player,
        npcRecord = record,
        identity = PNC.Identity and PNC.Identity.Verifier
            and PNC.Identity.Verifier.BuildView(entry)
            or nil,
        npcID = npcID,
        characterUUID = playerContext.characterUUID or "unbound",
        relationship = relationship or {},
        relationshipState = relationshipID,
        playerSocialProfile = playerContext.socialProfile,
        playerPersonality = playerContext.socialProfile,
        npcPersonality = record.personality or record.socialProfile,
        npcTraits = record.traits or record.socialTraits,
        audiences = audienceMap(entry, relationshipID),
        allowHostileParley = audienceMap(entry, relationshipID).hostile,
        worldAgeHours = at,
        hour = TIME_HOURS[timeID] or at % 24,
        worldID = "world",
        baseEstablished = colonyManagement.settlement ~= nil,
    }
    context.blockValidator = function(block)
        return Loader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
    end
    context.categoryValidator = function(category)
        return Loader.EnsureSource(
            category.textSource,
            { category.labelKey }
        )
    end
    state.conversationHistory = state.conversationHistory or {}
    state.conversationHistory[npcID] = state.conversationHistory[npcID] or {}
    context.historyLookup = function(subjectID)
        return state.conversationHistory[npcID][tostring(subjectID or "")]
    end
    return context
end

function Composer.SetIdentityArguments(context, values)
    if type(context) ~= "table" then return false end
    context.textArgs = {}
    for name, value in pairs(type(values) == "table" and values or {}) do
        context.textArgs[name] = value
        context[name] = value
    end
    return true
end

return Composer
