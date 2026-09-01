-- Audience-aware interaction metadata for vanilla player emotes.
-- The radial menu owns animation; the server owns the social consequence.

PNC = PNC or {}
PNC.VanillaEmoteInteractions = PNC.VanillaEmoteInteractions or {}

local Interactions = PNC.VanillaEmoteInteractions

local NPC_TYPES = {
    "hostile",
    "neutral",
    "colonist",
    "lover",
    "family",
}

local GREETING_MEMORY_TYPES = {
    "player_greeted",
    "npc_greeted_player",
    "greeting_exchanged",
}

local GREETING_TIERS = {
    warm = true,
    familiar = true,
    reserved = true,
}

local FAMILY_RELATIONSHIPS = {
    brother = true,
    sister = true,
    mother = true,
    father = true,
    parent = true,
    child = true,
    son = true,
    daughter = true,
    family = true,
}

local function typedReplies(id)
    local output = {}
    local index
    local npcType
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        output[npcType] = "vanilla_emote_" .. tostring(id)
            .. "_npc_" .. npcType
    end
    return output
end

local function dailyTypedReplies(id)
    local output = {}
    local index
    local npcType
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        output[npcType] = {
            first = "vanilla_emote_" .. tostring(id)
                .. "_npc_" .. npcType .. "_first",
            returning = "vanilla_emote_" .. tostring(id)
                .. "_npc_" .. npcType .. "_returning",
        }
    end
    return output
end

local function normalizeType(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

local DEFINITIONS = {
    insult = {
        id = "insult",
        eventType = "player_emote_insult",
        flavorID = "vanilla_emote_insult",
        radius = 12,
        maxTargets = 6,
        hostile = true,
        replyFlavor = {
            familiar = "vanilla_emote_insult_npc_familiar",
            guarded = "vanilla_emote_insult_npc_guarded",
            hostile = "vanilla_emote_insult_npc_hostile",
            byNPCType = typedReplies("insult"),
        },
    },
    thumbsdown = {
        id = "thumbsdown",
        eventType = "player_emote_thumbsdown",
        flavorID = "vanilla_emote_thumbsdown",
        radius = 12,
        maxTargets = 6,
        hostile = true,
        replyFlavor = {
            guarded = "vanilla_emote_thumbsdown_npc_guarded",
            hostile = "vanilla_emote_thumbsdown_npc_hostile",
            byNPCType = typedReplies("thumbsdown"),
        },
    },
    wavehi = {
        id = "wavehi",
        eventType = "player_emote_wavehi",
        flavorID = "vanilla_emote_wavehi",
        radius = 14,
        maxTargets = 8,
        dayGate = "greeting",
        replyFlavor = {
            warm = "vanilla_emote_wavehi_npc_warm",
            reserved = "vanilla_emote_wavehi_npc_reserved",
            byNPCType = dailyTypedReplies("wavehi"),
        },
    },
    wavebye = {
        id = "wavebye",
        eventType = "player_emote_wavebye",
        flavorID = "vanilla_emote_wavebye",
        radius = 14,
        maxTargets = 8,
        replyFlavor = {
            warm = "vanilla_emote_wavebye_npc_warm",
            reserved = "vanilla_emote_wavebye_npc_reserved",
            byNPCType = typedReplies("wavebye"),
        },
    },
    thankyou = {
        id = "thankyou",
        eventType = "player_emote_thankyou",
        flavorID = "vanilla_emote_thankyou",
        radius = 14,
        maxTargets = 8,
        replyFlavor = {
            warm = "vanilla_emote_thankyou_npc_warm",
            reserved = "vanilla_emote_thankyou_npc_reserved",
            byNPCType = typedReplies("thankyou"),
        },
    },
    thumbsup = {
        id = "thumbsup",
        eventType = "player_emote_thumbsup",
        flavorID = "vanilla_emote_thumbsup",
        radius = 14,
        maxTargets = 8,
        replyFlavor = {
            warm = "vanilla_emote_thumbsup_npc_warm",
            reserved = "vanilla_emote_thumbsup_npc_reserved",
            byNPCType = typedReplies("thumbsup"),
        },
    },
    clap = {
        id = "clap",
        eventType = "player_emote_clap",
        flavorID = "vanilla_emote_clap",
        radius = 14,
        maxTargets = 8,
        replyFlavor = {
            warm = "vanilla_emote_clap_npc_warm",
            reserved = "vanilla_emote_clap_npc_reserved",
            byNPCType = typedReplies("clap"),
        },
    },
    salute = {
        id = "salute",
        eventType = "player_emote_salute",
        flavorID = "vanilla_emote_salute",
        radius = 14,
        maxTargets = 8,
        replyFlavor = {
            warm = "vanilla_emote_salute_npc_warm",
            reserved = "vanilla_emote_salute_npc_reserved",
            byNPCType = typedReplies("salute"),
        },
    },
}

local ALIASES = {
    wavehi02 = "wavehi",
    comehere02 = "comehere",
    stop02 = "stop",
    clap02 = "clap",
    saluteformal = "salute",
    salutecasual = "salute",
}

function Interactions.Get(emote)
    local id = tostring(emote or "")
    id = ALIASES[id] or id
    return DEFINITIONS[id]
end

function Interactions.List()
    local output = {}
    local id
    for id, _ in pairs(DEFINITIONS) do
        output[#output + 1] = id
    end
    table.sort(output)
    return output
end

function Interactions.ResolveNPCType(record)
    local generation = record and record.generation or {}
    local relationshipKind = normalizeType(
        generation.relationshipKind
            or record and record.relationshipKind
            or record and record.conversationRelationship
            or record and record.relationshipCategory
    )
    local tacticalClass = PNC.Types
        and PNC.Types.ResolveTacticalClass
        and PNC.Types.ResolveTacticalClass(record)
        or normalizeType(record and record.tacticalClass)
    local hostility = record and record.hostility or {}
    if tacticalClass == "hostile" or hostility.attackPlayers == true then
        return "hostile"
    end
    if relationshipKind == "lover"
        or relationshipKind == "partner"
        or relationshipKind == "spouse"
    then
        return "lover"
    end
    if FAMILY_RELATIONSHIPS[relationshipKind] then
        return "family"
    end
    if tacticalClass == "colonist"
        or record and (record.recruited == true
            or record.ownerUsername ~= nil
            or record.ownerOnlineID ~= nil)
    then
        return "colonist"
    end
    return "neutral"
end

local function memoryTypeFor(definition)
    local memory = PNC.SocialEventDefinitions
        and definition and definition.eventType
        and PNC.SocialEventDefinitions[definition.eventType]
        and PNC.SocialEventDefinitions[definition.eventType].targetMemory
    return memory and memory.type or nil
end

function Interactions.DayIndex(worldAgeHours)
    return math.floor(math.max(0, tonumber(worldAgeHours) or 0) / 24)
end

function Interactions.HasMemoryToday(relationship, memoryType, worldAgeHours)
    local targetDay = Interactions.DayIndex(worldAgeHours)
    local memories = relationship and relationship.memories or {}
    local memory
    local createdAt
    for _, memoryValue in ipairs(memories) do
        memory = memoryValue
        if memory and memory.type == memoryType then
            createdAt = tonumber(memory.createdAt)
            if createdAt ~= nil
                and Interactions.DayIndex(createdAt) == targetDay
            then
                return true
            end
        end
    end
    return false
end

-- All positive greetings share this ledger.  The source may be a player emote
-- or an NPC-initiated proximity greeting, but the player/NPC pair only earns
-- one daily greeting credit.
function Interactions.HasGreetingToday(relationship, worldAgeHours)
    local index
    for index = 1, #GREETING_MEMORY_TYPES do
        if Interactions.HasMemoryToday(
            relationship,
            GREETING_MEMORY_TYPES[index],
            worldAgeHours
        )
        then
            return true
        end
    end
    return false
end

function Interactions.GreetingState(definition, relationship, worldAgeHours)
    if not definition or definition.dayGate ~= "greeting" then
        return nil
    end
    if Interactions.HasGreetingToday(relationship, worldAgeHours) then
        return "returning"
    end
    return "first"
end

function Interactions.ResolveRelationshipTier(relationship)
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    local state = normalizeType(relationship and relationship.state)
    if state == "enemy" or state == "rival" then
        return "reserved"
    end
    if state == "friend" or approval >= 30 then
        return "warm"
    end
    if approval >= 10 or familiarity >= 5 then
        return "familiar"
    end
    return "reserved"
end

function Interactions.IsAutomaticGreetingEligible(relationship, npcType)
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    local state = normalizeType(relationship and relationship.state)
    npcType = normalizeType(npcType)
    if not relationship or npcType == "hostile" then return false end
    if state == "enemy" or state == "rival" then return false end
    if state == "friend" or approval >= 10 then return true end
    return (npcType == "lover" or npcType == "family")
        and familiarity >= 5
end

function Interactions.GreetingReplyFlavorID(npcType, relationshipTier, state)
    npcType = normalizeType(npcType)
    relationshipTier = normalizeType(relationshipTier)
    state = normalizeType(state)
    if not GREETING_TIERS[relationshipTier] then
        relationshipTier = "reserved"
    end
    if state ~= "first" and state ~= "returning" then
        state = "first"
    end
    return "social_greeting_npc_" .. npcType .. "_"
        .. relationshipTier .. "_" .. state
end

function Interactions.ReplyFlavorID(definition, relationship, context)
    local approval = tonumber(relationship and relationship.approval) or 0
    local flavors = definition and definition.replyFlavor or nil
    local npcType = normalizeType(context and context.npcType)
    local greetingState = normalizeType(context and context.greetingState)
    local typed = flavors and flavors.byNPCType
        and flavors.byNPCType[npcType] or nil
    if not flavors then return nil end
    if definition.id == "wavehi" and context
        and context.relationshipTier
    then
        return Interactions.GreetingReplyFlavorID(
            npcType,
            context.relationshipTier,
            greetingState
        )
    end
    if typed then
        if type(typed) == "table" and typed[greetingState] then
            return typed[greetingState]
        end
        if type(typed) == "string" then return typed end
        if type(typed) == "table" and typed.default then
            return typed.default
        end
    end
    if definition.hostile == true then
        if approval <= -25 then
            return flavors.hostile or flavors.guarded
        end
        if approval >= 30 then
            return flavors.familiar or flavors.guarded
        end
        return flavors.guarded or flavors.hostile
    end
    if approval >= 30 then
        return flavors.warm or flavors.reserved
    end
    return flavors.reserved or flavors.warm
end

return Interactions
