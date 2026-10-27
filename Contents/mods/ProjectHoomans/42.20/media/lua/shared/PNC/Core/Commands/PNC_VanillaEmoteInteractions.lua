-- Audience-aware interaction metadata for vanilla player emotes.
-- The radial menu owns animation; the server owns the social consequence.

PNC = PNC or {}
PNC.VanillaEmoteInteractions = PNC.VanillaEmoteInteractions or {}

local Interactions = PNC.VanillaEmoteInteractions

local GREETING_MEMORY_TYPES = {
    "player_greeted",
    "npc_greeted_player",
    "greeting_exchanged",
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

local function normalizeType(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

local DEFINITIONS = {
    insult = {
        id = "insult",
        eventType = "player_emote_insult",
        radius = 12,
        maxTargets = 6,
        hostile = true,
    },
    thumbsdown = {
        id = "thumbsdown",
        eventType = "player_emote_thumbsdown",
        radius = 12,
        maxTargets = 6,
        hostile = true,
    },
    wavehi = {
        id = "wavehi",
        eventType = "player_emote_wavehi",
        radius = 14,
        maxTargets = 8,
        dayGate = "greeting",
    },
    wavebye = {
        id = "wavebye",
        eventType = "player_emote_wavebye",
        radius = 14,
        maxTargets = 8,
    },
    thankyou = {
        id = "thankyou",
        eventType = "player_emote_thankyou",
        radius = 14,
        maxTargets = 8,
    },
    thumbsup = {
        id = "thumbsup",
        eventType = "player_emote_thumbsup",
        radius = 14,
        maxTargets = 8,
    },
    clap = {
        id = "clap",
        eventType = "player_emote_clap",
        radius = 14,
        maxTargets = 8,
    },
    salute = {
        id = "salute",
        eventType = "player_emote_salute",
        radius = 14,
        maxTargets = 8,
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

return Interactions
