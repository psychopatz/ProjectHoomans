-- Bounded, read-only actor context for semantic dialogue.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.ActorConversationContext or {}
PNC.Semantics.ActorConversationContext = Context

Context.VERSION = 1
Context.SCHEMA = "actor.conversation.context.v1"
Context.MAX_TRAITS = 32
Context.MAX_CAPABILITIES = 24

local PERSONALITY_FIELDS = {
    "socialStyle", "compassion", "sociability", "forgiveness", "bravery",
    "materialism", "aggression", "loyalty",
}

local function text(value, fallback)
    if value == nil then return fallback end
    value = tostring(value)
    return value ~= "" and value or fallback
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

local function boundedNumber(value, minimum, maximum)
    value = finite(value)
    if value == nil then return nil end
    if minimum ~= nil and value < minimum then value = minimum end
    if maximum ~= nil and value > maximum then value = maximum end
    return value
end

local function copy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 4 then return nil end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    local count = 0
    for key, item in pairs(value) do
        if count >= 24 then break end
        if type(key) == "string" or type(key) == "number" then
            if type(item) ~= "function" then
                output[key] = copy(item, depth + 1, seen)
                count = count + 1
            end
        end
    end
    return output
end

local function sourceValue(context, key)
    if type(context) ~= "table" then return nil end
    if context[key] ~= nil then return context[key] end
    if type(context.npcState) == "table"
        and context.npcState[key] ~= nil
    then return context.npcState[key] end
    local entry = context.entry
    local snapshot = type(entry) == "table" and entry.snapshot or nil
    return type(snapshot) == "table" and snapshot[key] or nil
end

local function identitySource(context)
    local identity = type(context) == "table" and context.identity or nil
    local record = type(context) == "table" and context.npcRecord or nil
    if type(identity) == "table" then return identity end
    if type(record) == "table" and type(record.identity) == "table" then
        return record.identity
    end
    return type(record) == "table" and record or {}
end

local function sortedIDs(value, limit)
    local output = {}
    local seen = {}
    limit = tonumber(limit) or Context.MAX_TRAITS
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        local candidate
        if type(key) == "number" then candidate = item
        elseif item == true then candidate = key
        elseif type(item) == "string" then candidate = item end
        candidate = type(candidate) == "string" and candidate or nil
        if candidate then
            candidate = string.lower(candidate)
            if candidate ~= "" and not seen[candidate]
                and #output < limit
            then
                seen[candidate] = true
                output[#output + 1] = candidate
            end
        end
    end
    table.sort(output)
    return output
end

local function personalitySource(context)
    local source = context and context.npcPersonality
    if type(source) ~= "table" then source = context and context.personality end
    if type(source) ~= "table" then source = context and context.socialProfile end
    if type(source) ~= "table" then
        local record = context and context.npcRecord
        source = type(record) == "table" and (
            record.personality or record.socialProfile
                or record.social and record.social.personality
        ) or nil
    end
    return type(source) == "table" and source or {}
end

local function publicPersonality(context)
    local source = personalitySource(context)
    local output = {}
    for index = 1, #PERSONALITY_FIELDS do
        local field = PERSONALITY_FIELDS[index]
        local value = source[field]
        if field == "socialStyle" then
            value = type(value) == "string" and value or nil
        else value = boundedNumber(value, 0, 1) end
        if value ~= nil then output[field] = value end
    end
    output.revision = math.max(0, math.floor(finite(source.revision) or 0))
    output.generationVersion = math.max(
        0, math.floor(finite(source.generationVersion) or 0)
    )
    return output
end

local function relationshipProjection(context)
    local source = type(context.relationship) == "table"
        and context.relationship or {}
    return {
        approval = boundedNumber(source.approval, -100, 100),
        respect = boundedNumber(source.respect, -100, 100),
        familiarity = boundedNumber(source.familiarity, 0, 100),
        state = text(
            source.relationshipState or source.state or context.relationshipState,
            "unknown"
        ),
        identityTrust = text(source.identityTrust or context.identityTrust),
        revision = math.max(0, math.floor(finite(source.revision) or 0)),
    }
end

local function actorRoles(context)
    local authority = type(context.actorAuthority) == "table"
        and context.actorAuthority or {}
    local role = context.role
    if role == nil and type(context.npcState) == "table" then
        role = context.npcState.role
    end
    if role == nil and type(context.npcRecord) == "table" then
        role = context.npcRecord.role
    end
    role = type(role) == "string" and role or nil
    local hostile = context.hostile == true
    local hostility = sourceValue(context, "hostility")
    if type(hostility) == "table" and hostility.attackPlayers == true then
        hostile = true
    end
    local capabilities = sortedIDs(
        context.capabilities or context.npcCapabilities,
        Context.MAX_CAPABILITIES
    )
    local hasCapability = {}
    for index = 1, #capabilities do hasCapability[capabilities[index]] = true end
    return {
        role = role,
        capabilities = capabilities,
        companion = authority.companion == true,
        owned = authority.owned == true,
        authorityEligible = authority.eligible == true,
        authorityStatus = text(authority.status, "authority_unknown"),
        hostile = hostile,
        trader = role == "trader" or hasCapability.trader == true
            or hasCapability.trade == true,
    }
end

local function situationProjection(context)
    local situation = type(context.dialogueSituation) == "table"
        and context.dialogueSituation or {}
    local npc = type(situation.npc) == "table" and situation.npc or {}
    local state = type(context.semanticDialogueState) == "table"
        and context.semanticDialogueState or {}
    local needs = type(npc.needs) == "table" and npc.needs
        or sourceValue(context, "needs")
    local activity = type(npc.activity) == "table" and npc.activity or nil
    return {
        healthState = text(npc.healthState or sourceValue(context, "healthState")),
        activeBehavior = text(sourceValue(context, "activeBehavior")),
        activity = copy(activity),
        needs = copy(needs),
        emotion = copy(npc.emotion),
        inCombat = npc.inCombat == true or context.inCombat == true,
        currentTopic = text(
            state.currentTopic or context.currentTopic
                or context.conversationTopic
        ),
        previousTopic = text(state.previousTopic or context.previousTopic),
        worldRevision = math.max(
            0, math.floor(finite(context.worldRevision) or 0)
        ),
    }
end

local function identityProjection(context)
    local source = identitySource(context)
    local gender = source.gender or source.sex
    if gender == nil and source.isFemale ~= nil then
        gender = source.isFemale == true and "female" or "male"
    end
    return {
        state = text(context.identityState or source.identityState, "unknown"),
        gender = type(gender) == "string" and string.lower(gender) or nil,
        isFemale = type(source.isFemale) == "boolean"
            and source.isFemale or nil,
        source = text(source.identitySource or source.source),
    }
end

local function revisions(context, relationship, personality, roles, situation)
    local fingerprint = context.npcTraitFingerprint
    if fingerprint == nil and type(context.npcRecord) == "table" then
        fingerprint = context.npcRecord.npcTraitFingerprint
    end
    return {
        context = math.max(0, math.floor(finite(
            context.contextRevision or context.revision
        ) or 0)),
        relationship = relationship.revision,
        personality = personality.revision,
        traits = text(fingerprint, ""),
        roles = text(roles.authorityStatus, "authority_unknown"),
        situation = situation.worldRevision,
    }
end

function Context.Build(source)
    local context = type(source) == "table" and source or {}
    local relationship = relationshipProjection(context)
    local personality = publicPersonality(context)
    local roles = actorRoles(context)
    local situation = situationProjection(context)
    local identity = identityProjection(context)
    local traits = sortedIDs(context.npcTraits, Context.MAX_TRAITS)
    return {
        schemaVersion = Context.VERSION,
        schema = Context.SCHEMA,
        actorID = text(context.npcID or context.actorID),
        identity = identity,
        traits = traits,
        personality = personality,
        relationship = relationship,
        roles = roles,
        situation = situation,
        revisions = revisions(context, relationship, personality, roles, situation),
        provenance = {
            identity = context.identity and "identity_projection"
                or "context.identityState",
            traits = context.npcTraits and "registered_npc_traits"
                or "traits_unavailable",
            personality = context.npcPersonality and "social_profile_projection"
                or "personality_unavailable",
            relationship = context.relationship and "directed_relationship",
            roles = context.actorAuthority and "actor_authority",
            situation = context.dialogueSituation and "dialogue_situation"
                or "actor_state_projection",
        },
        privacy = {
            privateFieldsOmitted = {
                "orientation", "romanceStyle", "jealousyStyle",
            },
            undiscoveredFactsExcluded = true,
            playerVisible = false,
        },
    }
end

function Context.PublicView(value)
    value = type(value) == "table" and value or {}
    local identity = type(value.identity) == "table" and value.identity or {}
    local roles = type(value.roles) == "table" and value.roles or {}
    local situation = type(value.situation) == "table" and value.situation or {}
    return {
        schemaVersion = value.schemaVersion,
        actorID = value.actorID,
        identity = { state = identity.state },
        roles = {
            role = roles.role,
            companion = roles.companion == true,
            owned = roles.owned == true,
            authorityEligible = roles.authorityEligible == true,
            hostile = roles.hostile == true,
            trader = roles.trader == true,
        },
        situation = {
            healthState = situation.healthState,
            activeBehavior = situation.activeBehavior,
            currentTopic = situation.currentTopic,
            inCombat = situation.inCombat == true,
        },
        revisions = copy(value.revisions),
        privacy = {
            privateFieldsOmitted = true,
            undiscoveredFactsExcluded = true,
            playerVisible = true,
        },
    }
end

return Context
