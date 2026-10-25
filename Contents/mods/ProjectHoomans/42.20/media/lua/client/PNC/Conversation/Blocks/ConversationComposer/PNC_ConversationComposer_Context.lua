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

local function entryValue(entry, key)
    local snapshot = entry and type(entry.snapshot) == "table"
        and entry.snapshot or {}
    local record = entry and type(entry.record) == "table"
        and entry.record or {}
    if entry and entry[key] ~= nil then return entry[key] end
    if snapshot[key] ~= nil then return snapshot[key] end
    if record[key] ~= nil then return record[key] end
    if key == "followState"
        and type(record.runtime) == "table"
        and record.runtime.followState ~= nil
    then
        return record.runtime.followState
    end
    if key == "healthState"
        and type(record.health) == "table"
        and record.health.state ~= nil
    then
        return record.health.state
    end
    return nil
end

local function boundedNeeds(value)
    if type(value) ~= "table" then return nil end
    if type(value.needs) == "table"
        and value.hunger == nil and value.thirst == nil
    then
        value = value.needs
    end
    return {
        hunger = math.max(0, math.min(1, tonumber(value.hunger) or 0)),
        thirst = math.max(0, math.min(1, tonumber(value.thirst) or 0)),
        fatigue = math.max(0, math.min(1, tonumber(value.fatigue) or 0)),
    }
end

local function companionState(entry, talkStartProjection)
    local followState = entryValue(entry, "followState")
    -- The production order transition clears runtime.followState when a
    -- companion is not following.  That is an explicit idle state, not an
    -- unknown state; preserve it for semantic Follow/Stay eligibility.
    if type(followState) ~= "table" then
        followState = { mode = "idle" }
    end
    local ownership = type(talkStartProjection) == "table"
        and type(talkStartProjection.ownership) == "table"
        and talkStartProjection.ownership or {}
    local orderSpec = entryValue(entry, "orderSpec")
    if type(orderSpec) ~= "table" then
        orderSpec = type(ownership.orderSpec) == "table"
            and ownership.orderSpec or {}
    end
    local orderKind = entryValue(entry, "orderKind")
        or ownership.orderKind
        or orderSpec.kind
    if orderKind == nil then orderKind = "idle" end
    return {
        activeBehavior = entryValue(entry, "activeBehavior"),
        healthState = entryValue(entry, "healthState"),
        followState = followState,
        -- Durable order intent is the source of truth for Follow/Stay.  The
        -- transient followState.mode describes a movement phase and can be
        -- "idle" or "abstract_follow" while the follow order remains active.
        orderKind = orderKind,
        needs = boundedNeeds(entryValue(entry, "needs")),
        staminaState = entryValue(entry, "staminaState"),
        staminaRatio = tonumber(entryValue(entry, "staminaRatio")),
    }
end

local function authoritativeRecord(entry)
    if entry and type(entry.record) == "table" then
        return entry.record
    end
    -- Native target resolution may have only the player-scoped replicated
    -- snapshot.  It contains the bounded companion/ownership facts needed
    -- for affordance projection; the server still revalidates every command.
    if entry and type(entry.snapshot) == "table" then
        return entry.snapshot
    end
    local source = entry and entry.source
    if type(source) == "table" then
        if type(source.record) == "table" then return source.record end
        return source
    end
    return {}
end

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

function Composer.BuildContext(
    entry,
    player,
    timeID,
    relationshipID,
    talkStartProjection
)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local record = authoritativeRecord(entry)
    local colonyManagement = state.colonyManagement or {}
    local npcID = tostring(entry and entry.id or "debug-npc")
    local relationship = Conversation.Relationship
        and Conversation.Relationship.GetPresentation(npcID) or {}
    local at = worldAgeHours()
    local profile = type(talkStartProjection) == "table"
        and type(talkStartProjection.audienceProfile) == "table"
        and talkStartProjection.audienceProfile
        or Audience.BuildProfile(
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
        talkStartProjection = talkStartProjection,
        npcRecord = record,
        actorAuthority = actorAuthority(entry, record, player),
        -- Keep the bounded authoritative companion state beside the authority
        -- verdict.  The semantic capability projector consumes this shape;
        -- it must not have to inspect Java objects or authored menu choices.
        npcState = companionState(entry, talkStartProjection),
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
