PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
if not Conversation.Audience then
    require "PNC/Conversation/PNC_ConversationAudience"
end
local Composer = Conversation.Composer
local ActorConversationContext = PNC.Semantics
    and PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader
local Audience = Conversation.Audience

local function actorAuthority(entry, record, player)
    local authority = PNC.ClientCompanionAuthority
    if type(record) ~= "table" then
        return {
            eligible = false,
            companion = nil,
            owned = nil,
            status = "authority_unknown",
        }
    end
    local companion
    local owned
    if authority and type(authority.IsCompanion) == "function" then
        local ok, value = pcall(authority.IsCompanion, record)
        if ok then companion = value == true end
    end
    if authority and type(authority.IsOwnedByPlayer) == "function" then
        local ok, value = pcall(authority.IsOwnedByPlayer, record, player)
        if ok then owned = value == true end
    end
    if companion == nil or owned == nil then
        return {
            eligible = false,
            companion = companion,
            owned = owned,
            status = "authority_unknown",
        }
    end
    return {
        eligible = companion and owned,
        companion = companion,
        owned = owned,
        status = companion and owned and "eligible"
            or (not companion and "not_companion" or "not_owned"),
    }
end

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

function Composer.BuildContext(entry, player, timeID, relationshipID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local record = entry and entry.record or {}
    local colonyManagement = state.colonyManagement or {}
    local npcID = tostring(entry and entry.id or "debug-npc")
    local relationship = Conversation.Relationship
        and Conversation.Relationship.GetPresentation(npcID) or {}
    local at = worldAgeHours()
    local profile = Audience.BuildProfile(
        entry,
        player,
        relationshipID,
        colonyManagement.settlement ~= nil
    )
    local npcPersonality = record.personality or record.socialProfile
        or record.social and record.social.personality or {}
    local context = {
        entry = entry,
        player = player,
        npcRecord = record,
        actorAuthority = actorAuthority(entry, record, player),
        identity = PNC.Identity and PNC.Identity.Verifier
            and PNC.Identity.Verifier.BuildView(entry)
            or nil,
        npcID = npcID,
        characterUUID = playerContext.characterUUID or "unbound",
        relationship = relationship or {},
        relationshipState = relationshipID,
        playerSocialProfile = playerContext.socialProfile,
        playerPersonality = playerContext.socialProfile,
        npcPersonality = npcPersonality,
        npcTraits = PNC.NPCTraitContext
            and PNC.NPCTraitContext.Collect
            and PNC.NPCTraitContext.Collect(record)
            or {},
        audience = profile.audience,
        conversationAudience = profile.audience,
        conversationProfile = profile,
        tacticalClass = profile.tacticalClass,
        playerHostile = profile.playerHostile,
        audiences = profile.audiences,
        allowHostileParley = profile.playerHostile,
        worldAgeHours = at,
        hour = TIME_HOURS[timeID] or at % 24,
        worldID = "world",
        baseEstablished = profile.baseEstablished,
        settlementVisit = relationship and relationship.settlementVisit
            and (tonumber(relationship.settlementVisit.expiresAt) or 0) > at
            and relationship.settlementVisit or nil,
        ambientVisitPreview = relationship
            and relationship.ambientVisitPreview or nil,
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
    context.actorConversationContext = ActorConversationContext.Build(context)
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
