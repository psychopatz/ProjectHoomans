-- Bounded reactions and permanent witnessed-death memories for NPC deaths and corpses.

PNC = PNC or {}
PNC.CorpseAwareness = PNC.CorpseAwareness or {}

local Awareness = PNC.CorpseAwareness
local MEMORY_TYPE = "death_witnessed"
local MEMORY_ID_PREFIX = "death_witnessed:"
local MEMORY_LIMIT_PER_NPC = 24
local MAX_WITNESSES_PER_CORPSE = 12
local MAX_RELATIONSHIPS_TO_COUNT = 256
local MAX_RELATIONSHIP_MEMORIES_TO_SCAN = 32
local MAX_CORPSE_ITEMS_TO_SCAN = 256
local MAX_NPCS_TO_SCORE = 64
local MAX_VISIBILITY_CHECKS = 12
local MAX_CORPSE_REACTIONS_PER_SCAN = 8
local SCAN_INTERVAL_MS = 15000
local DETECTION_RADIUS = 10
local DETECTION_RADIUS_SQ = DETECTION_RADIUS * DETECTION_RADIUS
local CACHE_SCHEMA_VERSION = 1
local KINSHIP_MARKERS = {
    relative = true,
    relatives = true,
    family = true,
    kin = true,
    kinship = true,
    sibling = true,
    brother = true,
    sister = true,
    parent = true,
    mother = true,
    father = true,
    mom = true,
    dad = true,
    child = true,
    son = true,
    daughter = true,
    spouse = true,
    husband = true,
    wife = true,
    partner = true,
    lover = true,
    cousin = true,
    grandparent = true,
    grandchild = true,
}
local RELATION_PRIORITY = {
    relative = 5,
    friend = 4,
    hostile = 3,
    comrade = 2,
    neutral = 1,
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function safeDisplayText(value, fallback)
    local text = tostring(value or "")
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.sub(text, 1, 120)
    if text == "" then return fallback end
    return text
end

local function nowMs()
    return PNC.Core and PNC.Core.Now
        and math.max(0, tonumber(PNC.Core.Now()) or 0) or 0
end

local function worldAgeHours()
    local hooks = PNC.SocialEventHooks
    local value
    local gameTime
    if hooks and type(hooks.WorldAgeHours) == "function" then
        value = hooks.WorldAgeHours()
        if tonumber(value) then
            return math.max(0, tonumber(value))
        end
    end
    gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        value = gameTime:getWorldAgeHours()
        if tonumber(value) then
            return math.max(0, tonumber(value))
        end
    end
    return 0
end

local function modDataOf(object)
    if object and object.getModData then
        local data = object:getModData()
        if type(data) == "table" then return data end
    end
    return nil
end

local function itemFullType(item)
    if item and item.getFullType then
        local fullType = item:getFullType()
        if fullType then return tostring(fullType) end
    end
    return tostring(item and (item.fullType or item.type) or "")
end

local function itemModData(item)
    return modDataOf(item)
end

local function inspectCorpseItems(record, corpse)
    local expectedNPCID = tostring(record and record.id or "")
    local container = corpse and corpse.getContainer
        and corpse:getContainer()
        or corpse and corpse.getInventory
            and corpse:getInventory() or nil
    local items = container and container.getItems
        and container:getItems() or nil
    local identity
    local itemsScanned = 0

    local function inspect(item)
        local fullType = itemFullType(item)
        local data = itemModData(item)
        if fullType == "Base.IDcard" and data
            and data.PNC_IDCard == true
            and tostring(data.PNC_IDCardNPCId or "") == expectedNPCID
            and tonumber(data.PNC_IDCardVersion) == 1
        then
            identity = identity or {}
            identity.npcID = expectedNPCID
            identity.name = safeDisplayText(
                data.PNC_IDCardNPCName,
                "Unknown NPC"
            )
        elseif fullType == "Base.Necklace_DogTag" and data
            and data.PNC_FactionDogTag == true
            and tostring(data.PNC_FactionDogTagNPCId or "")
                == expectedNPCID
            and tonumber(data.PNC_FactionDogTagVersion) == 1
        then
            identity = identity or {}
            identity.factionID = tostring(
                data.PNC_FactionDogTagFactionId or ""
            )
            identity.factionName = safeDisplayText(
                data.PNC_FactionDogTagFactionName,
                ""
            )
        end
    end

    if not items then return nil end
    if items.size and items.get then
        local size = items:size()
        local lowerIndex
        local index
        size = math.max(0, tonumber(size) or 0)
        lowerIndex = math.max(0, size - MAX_CORPSE_ITEMS_TO_SCAN)
        for index = size - 1, lowerIndex, -1 do
            itemsScanned = itemsScanned + 1
            inspect(items:get(index))
            if identity and identity.name and identity.factionID
                and identity.factionID ~= ""
            then
                break
            end
        end
    elseif type(items) == "table" then
        for _, item in pairs(items) do
            itemsScanned = itemsScanned + 1
            inspect(item)
            if itemsScanned >= MAX_CORPSE_ITEMS_TO_SCAN then break end
            if identity and identity.name and identity.factionID
                and identity.factionID ~= ""
            then
                break
            end
        end
    end

    if not identity or identity.npcID ~= expectedNPCID
        or not identity.name or identity.name == ""
    then
        return nil
    end
    return identity
end

local function cacheCorpseIdentity(corpseData, identity)
    if type(corpseData) ~= "table" or type(identity) ~= "table" then
        return false
    end
    corpseData.PNC_CorpseAwarenessIdentityVersion = CACHE_SCHEMA_VERSION
    corpseData.PNC_CorpseAwarenessIdentityNPCId = tostring(
        identity.npcID or ""
    )
    corpseData.PNC_CorpseAwarenessIdentityToken = tostring(
        identity.token or ""
    )
    corpseData.PNC_CorpseAwarenessIdentityName = safeDisplayText(
        identity.name,
        "Unknown NPC"
    )
    corpseData.PNC_CorpseAwarenessFactionID = tostring(
        identity.factionID or ""
    )
    corpseData.PNC_CorpseAwarenessFactionName = safeDisplayText(
        identity.factionName,
        ""
    )
    return true
end

local function corpseIdentity(record, corpse, corpseData)
    local npcID = tostring(record and record.id or "")
    local token = tostring(
        corpseData.PNC_CorpseToken
            or record and record.corpseToken
            or record and record.corpse and record.corpse.token
            or ""
    )
    local cached
    if tonumber(corpseData.PNC_CorpseAwarenessIdentityVersion)
            == CACHE_SCHEMA_VERSION
        and tostring(corpseData.PNC_CorpseAwarenessIdentityNPCId or "")
            == npcID
        and tostring(corpseData.PNC_CorpseAwarenessIdentityToken or "")
            == token
    then
        cached = {
            npcID = npcID,
            name = safeDisplayText(
                corpseData.PNC_CorpseAwarenessIdentityName,
                "Unknown NPC"
            ),
            factionID = tostring(
                corpseData.PNC_CorpseAwarenessFactionID or ""
            ),
            factionName = safeDisplayText(
                corpseData.PNC_CorpseAwarenessFactionName,
                ""
            ),
            token = token,
        }
        if cached.name ~= "Unknown NPC" or corpseData.PNC_CorpseAwarenessIdentityName
            == "Unknown NPC"
        then
            return cached
        end
    end

    local found = inspectCorpseItems(record, corpse)
    if not found then return nil end
    found.token = token
    cacheCorpseIdentity(corpseData, found)
    return found
end

local function deathIdentityFromRecord(record, token)
    local npcID = tostring(record and record.id or "")
    local affiliation = record and record.affiliation or nil
    local factionID = tostring(affiliation and affiliation.factionID or "")
    local factionName = affiliation
        and (affiliation.factionName or affiliation.name) or ""
    local factions = PNC.Factions
    local faction
    if npcID == "" then return nil end
    if factionID ~= "" and factions and type(factions.Get) == "function" then
        faction = factions.Get(factionID)
        if faction and faction.name then factionName = faction.name end
    end
    return {
        npcID = npcID,
        name = safeDisplayText(
            record.name or record.displayName,
            "Unknown NPC"
        ),
        factionID = factionID,
        factionName = safeDisplayText(factionName, ""),
        token = tostring(token or ""),
    }
end

local function copyDeathIdentity(record, token, identity)
    if type(identity) ~= "table"
        or tostring(identity.npcID or "") ~= tostring(record and record.id or "")
        or tostring(identity.token or "") ~= tostring(token or "")
    then
        return nil
    end
    local name = safeDisplayText(identity.name, "Unknown NPC")
    if name == "Unknown NPC" and identity.name ~= "Unknown NPC" then
        return nil
    end
    return {
        npcID = tostring(identity.npcID),
        name = name,
        factionID = tostring(identity.factionID or ""),
        factionName = safeDisplayText(identity.factionName, ""),
        token = tostring(identity.token),
    }
end

local function deathAttribution(record, damageEvent)
    local attackerKind = lower(damageEvent and damageEvent.attackerKind)
    local attackerID = tostring(damageEvent and damageEvent.attackerID or "")
    local killerName
    local sourceKey
    local attacker
    if attackerKind == "player" then
        killerName = safeDisplayText(
            damageEvent.attackerUsername or damageEvent.username,
            ""
        )
        if killerName == "" then return nil end
        return {
            kind = "player",
            killerName = killerName,
        }
    end
    if attackerKind ~= "npc"
        and attackerKind ~= "foreign_npc"
        and attackerKind ~= "managed_npc"
    then
        return nil
    end
    if attackerID == "" or attackerID == tostring(record and record.id or "") then
        return nil
    end
    attacker = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(attackerID) or nil
    killerName = attacker and (attacker.name or attacker.displayName) or nil
    if PNC.EntityRef and PNC.EntityRef.ForNPC then
        sourceKey = PNC.EntityRef.ForNPC(attackerID)
    end
    if not sourceKey then return nil end
    return {
        kind = "npc",
        killerName = safeDisplayText(killerName, ""),
        sourceKey = sourceKey,
    }
end

local function knownKillerName(attribution)
    local name = type(attribution) == "table"
        and safeDisplayText(attribution.killerName, "") or ""
    return name ~= "" and name ~= "the one who did this"
end

local function cacheDeathAttribution(corpseData, token, attribution)
    if type(corpseData) ~= "table" then return false end
    corpseData.PNC_CorpseAwarenessAttributionVersion = 1
    corpseData.PNC_CorpseAwarenessAttributionToken = tostring(token or "")
    corpseData.PNC_CorpseAwarenessAttributionKnown =
        type(attribution) == "table"
    corpseData.PNC_CorpseAwarenessAttributionKind = type(attribution)
            == "table" and tostring(attribution.kind or "") or ""
    corpseData.PNC_CorpseAwarenessAttributionKiller = type(attribution)
            == "table"
        and safeDisplayText(
            attribution.killerName,
            "the one who did this"
        ) or ""
    corpseData.PNC_CorpseAwarenessAttributionSourceKey = type(attribution)
            == "table"
        and tostring(attribution.sourceKey or "") or ""
    return true
end

local function cachedDeathAttribution(corpseData, token)
    local entityRef = PNC.EntityRef
    local kind
    local sourceKey
    if type(corpseData) ~= "table"
        or tonumber(corpseData.PNC_CorpseAwarenessAttributionVersion) ~= 1
        or tostring(corpseData.PNC_CorpseAwarenessAttributionToken or "")
            ~= tostring(token or "")
        or corpseData.PNC_CorpseAwarenessAttributionKnown ~= true
    then
        return nil
    end
    kind = lower(corpseData.PNC_CorpseAwarenessAttributionKind)
    if kind ~= "player" and kind ~= "npc" then return nil end
    sourceKey = tostring(
        corpseData.PNC_CorpseAwarenessAttributionSourceKey or ""
    )
    if not entityRef or not entityRef.IsValid
        or not entityRef.IsValid(sourceKey)
    then
        sourceKey = nil
    end
    return {
        kind = kind,
        killerName = safeDisplayText(
            corpseData.PNC_CorpseAwarenessAttributionKiller,
            "the one who did this"
        ),
        sourceKey = sourceKey,
    }
end

local function cacheDeathAwarenessState(
    corpseData,
    token,
    identity,
    attribution,
    witnessCount,
    candidateCursor
)
    if type(corpseData) ~= "table" then return false end
    cacheCorpseIdentity(corpseData, identity)
    cacheDeathAttribution(corpseData, token, attribution)
    corpseData.PNC_CorpseAwarenessVersion = CACHE_SCHEMA_VERSION
    corpseData.PNC_CorpseAwarenessToken = tostring(token or "")
    corpseData.PNC_CorpseAwarenessWitnessCount = math.max(
        0,
        math.floor(tonumber(witnessCount) or 0)
    )
    corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(
        0,
        math.floor(tonumber(candidateCursor) or 0)
    )
    return true
end

local function valueSignalsKinship(value)
    if type(value) == "string" then
        return KINSHIP_MARKERS[lower(value)] == true
    end
    if type(value) ~= "table" then return false end
    for key, enabled in pairs(value) do
        if type(key) == "string"
            and (enabled == true and KINSHIP_MARKERS[lower(key)] == true
                or KINSHIP_MARKERS[lower(enabled)] == true)
        then
            return true
        end
    end
    for _, field in pairs({
        "kind", "type", "kinship", "familyRole", "relationshipKind",
    }) do
        if KINSHIP_MARKERS[lower(value[field])] == true then
            return true
        end
    end
    return false
end

local function isRelative(rawRelationship, relationship)
    local relations = { rawRelationship }
    local relationIndex
    if relationship ~= rawRelationship then
        relations[#relations + 1] = relationship
    end
    for relationIndex = 1, #relations do
        local relation = relations[relationIndex]
        if type(relation) == "table" then
            if relation.family == true or relation.relative == true
                or relation.kinship == true
            then
                return true
            end
            for _, field in pairs({
                "kind", "type", "kinship", "relationshipKind",
                "relationshipType", "familyRole", "relation",
            }) do
                if valueSignalsKinship(relation[field]) then return true end
            end
            local memoryScanned = 0
            for _, candidate in pairs(relation.memories or {}) do
                memoryScanned = memoryScanned + 1
                if memoryScanned > MAX_RELATIONSHIP_MEMORIES_TO_SCAN then
                    break
                end
                if type(candidate) == "table"
                    and (valueSignalsKinship(candidate.type)
                        or valueSignalsKinship(candidate.tags))
                then
                    return true
                end
            end
        end
    end
    return false
end

local function startingCompanionsShareKinship(observer, deceased)
    local observerGeneration = observer and observer.generation or nil
    local deceasedGeneration = deceased and deceased.generation or nil
    local observerCharacterID = tostring(
        observerGeneration and observerGeneration.playerCharacterUUID or ""
    )
    local deceasedCharacterID = tostring(
        deceasedGeneration and deceasedGeneration.playerCharacterUUID or ""
    )
    if observerCharacterID == "" or observerCharacterID ~= deceasedCharacterID then
        return false
    end
    return KINSHIP_MARKERS[lower(
        observerGeneration.relationshipKind
    )] == true
        and KINSHIP_MARKERS[lower(
            deceasedGeneration.relationshipKind
        )] == true
end

local function factionIsHostile(observerFactionID, corpseFactionID)
    local factions = PNC.Factions
    local relation
    if not observerFactionID or not corpseFactionID
        or tostring(observerFactionID) == ""
        or tostring(corpseFactionID) == ""
        or tostring(observerFactionID) == tostring(corpseFactionID)
        or not factions or type(factions.GetRelation) ~= "function"
    then
        return false
    end
    relation = factions.GetRelation(observerFactionID, corpseFactionID)
    if type(relation) ~= "table" then return false end
    return relation.atWar == true
        or lower(relation.state) == "hostile"
        or lower(relation.state) == "enemy"
        or lower(relation.stance) == "hostile"
        or lower(relation.stance) == "enemy"
end

local function recordIsHostile(record)
    local tacticalClass = lower(record and record.tacticalClass)
    local hostility = record and record.hostility or nil
    if tacticalClass == "hostile"
        or tacticalClass == lower(PNC.Const
            and PNC.Const.TACTICAL_CLASS_HOSTILE or "hostile")
    then
        return true
    end
    if type(hostility) == "string" then
        return lower(hostility) == "hostile" or lower(hostility) == "enemy"
    end
    return type(hostility) == "table"
        and (hostility.hostile == true
            or lower(hostility.mode) == "hostile"
            or lower(hostility.class) == "hostile")
        or false
end

local function classify(
    observer,
    deceased,
    identity,
    relationship,
    rawRelationship,
    sameFaction
)
    local state = lower(relationship and relationship.state)
    local observerFactionID = observer and observer.affiliation
        and observer.affiliation.factionID or nil
    local corpseFactionID = identity and identity.factionID or nil
    if isRelative(rawRelationship, relationship)
        or startingCompanionsShareKinship(observer, deceased)
    then
        return "relative"
    end
    if state == "friend" then return "friend" end
    if sameFaction then return "comrade" end
    if state == "enemy" or state == "rival"
        or recordIsHostile(deceased)
        or factionIsHostile(observerFactionID, corpseFactionID)
    then
        return "hostile"
    end
    return "neutral"
end

local function relationFor(observer, deceasedID)
    local entityRef = PNC.EntityRef
    local targetKey = entityRef and entityRef.ForNPC
        and entityRef.ForNPC(deceasedID)
        or "npc:" .. tostring(deceasedID)
    local raw = observer and observer.social
        and observer.social.relationships
        and observer.social.relationships[targetKey] or nil
    return targetKey, raw, raw
end

local function deathMemoryID(token)
    token = tostring(token or "")
    if token == "" then return nil end
    return MEMORY_ID_PREFIX .. string.sub(token, 1, 220)
end

local function hasMemory(relationship, memoryID)
    local memory
    local scanned = 0
    for _, memory in pairs(relationship and relationship.memories or {}) do
        scanned = scanned + 1
        if scanned > MAX_RELATIONSHIP_MEMORIES_TO_SCAN then
            return true
        end
        if memory and tostring(memory.id or "") == memoryID then
            return true
        end
    end
    return false
end

local function deathMemoryCount(record)
    local runtime = record.runtime
    local social = record.social
    local relationships = social and social.relationships or nil
    local count = 0
    local scanned = 0
    local memoriesScanned
    if type(runtime) ~= "table" then
        runtime = {}
        record.runtime = runtime
    end
    if runtime.corpseAwarenessMemorySocial == social
        and tonumber(runtime.corpseAwarenessMemoryCount)
    then
        return tonumber(runtime.corpseAwarenessMemoryCount)
    end
    for _, relationship in pairs(relationships or {}) do
        scanned = scanned + 1
        if scanned > MAX_RELATIONSHIPS_TO_COUNT then
            count = MEMORY_LIMIT_PER_NPC
            break
        end
        memoriesScanned = 0
        for _, memory in pairs(relationship and relationship.memories or {}) do
            memoriesScanned = memoriesScanned + 1
            if memoriesScanned > MAX_RELATIONSHIP_MEMORIES_TO_SCAN then
                count = MEMORY_LIMIT_PER_NPC
                break
            end
            if memory and (memory.type == MEMORY_TYPE
                or memory.tags and memory.tags.death_witnessed == true)
            then
                count = count + 1
                if count >= MEMORY_LIMIT_PER_NPC then break end
            end
        end
        if count >= MEMORY_LIMIT_PER_NPC then break end
    end
    runtime.corpseAwarenessMemorySocial = social
    runtime.corpseAwarenessMemoryCount = count
    return count
end

local function rememberWitness(
    observer,
    targetKey,
    identity,
    category,
    memoryID,
    attribution
)
    local relationships = PNC.Relationships
    local tags = {
        corpse = true,
        death = true,
        witnessed = true,
        death_witnessed = true,
        ["relation_" .. category] = true,
    }
    local factionID = tostring(identity.factionID or "")
    local ok
    local runtime
    local sourceKey
    if factionID ~= "" then
        tags["faction:" .. string.sub(factionID, 1, 120)] = true
    end
    if type(attribution) == "table" then
        local attackerKind = lower(attribution.kind)
        if attackerKind == "player" or attackerKind == "npc" then
            tags["death_caused_by_" .. attackerKind] = true
        end
        if attribution.sourceKey and PNC.EntityRef
            and PNC.EntityRef.IsValid
            and PNC.EntityRef.IsValid(attribution.sourceKey)
        then
            sourceKey = attribution.sourceKey
        elseif attackerKind == "player" then
            local killerName = safeDisplayText(
                attribution.killerName,
                ""
            )
            if killerName ~= "" then
                tags["killer_name:" .. string.sub(killerName, 1, 80)] = true
            end
        end
    end
    if not relationships or type(relationships.AddMemory) ~= "function" then
        return false
    end
    ok = relationships.AddMemory(observer.id, targetKey, {
        id = memoryID,
        type = MEMORY_TYPE,
        aboutKey = targetKey,
        createdAt = worldAgeHours(),
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        shareable = false,
        knowledgeSource = "witnessed",
        sourceKey = sourceKey,
        tags = tags,
    })
    if ok ~= true then return false end
    runtime = observer.runtime or {}
    observer.runtime = runtime
    runtime.corpseAwarenessMemorySocial = observer.social
    runtime.corpseAwarenessMemoryCount = math.min(
        MEMORY_LIMIT_PER_NPC,
        (tonumber(runtime.corpseAwarenessMemoryCount) or 0) + 1
    )
    return true
end

local function hasSpokenMemory(relation, memoryID)
    return hasMemory(relation, memoryID)
end

local function playerCanHear(player, x, y, z)
    local px
    local py
    local pz
    local dx
    local dy
    if not player or player.isDead and player:isDead() then return false end
    px = player.getX and tonumber(player:getX()) or nil
    py = player.getY and tonumber(player:getY()) or nil
    pz = player.getZ and tonumber(player:getZ()) or nil
    if not px or not py or not pz or math.floor(pz) ~= math.floor(z) then
        return false
    end
    dx = px - x
    dy = py - y
    return dx * dx + dy * dy <= DETECTION_RADIUS_SQ
end

local function sendToNearbyPlayers(observer, actor, greeting)
    local core = PNC.Core
    local network = PNC.Network
    local x = actor and actor.getX and tonumber(actor:getX())
        or tonumber(observer and observer.x)
    local y = actor and actor.getY and tonumber(actor:getY())
        or tonumber(observer and observer.y)
    local z = actor and actor.getZ and tonumber(actor:getZ())
        or tonumber(observer and observer.z) or 0
    local sent = false
    if not x or not y or not core or type(core.ForEachPlayer) ~= "function"
        or not network or type(network.SendSocialGreeting) ~= "function"
    then
        return false
    end
    core.ForEachPlayer(function(player)
        if playerCanHear(player, x, y, z)
            and network.SendSocialGreeting(player, greeting) == true
        then
            sent = true
        end
    end)
    return sent
end

local function speak(
    observer,
    actor,
    identity,
    category,
    token,
    attribution,
    revenge
)
    local memory = PNC.Conversation
    and PNC.Conversation.Memory or nil
    local template
    local gossipPacket
    local npcID = tostring(observer.id or "")
    local memoryID = deathMemoryID(token)
    local flavorID = "corpse_seen_" .. category
    local arguments = {
        subject = identity.name,
        faction = identity.factionName ~= ""
            and identity.factionName or "an unknown faction",
    }
    if not memory or type(memory.SelectGossipTemplate) ~= "function"
        or type(memory.BuildGossipPacket) ~= "function"
        or not actor
        or not memoryID
    then
        return false
    end
    if revenge and knownKillerName(attribution) then
        flavorID = "corpse_seen_revenge_" .. category
        arguments.killer = safeDisplayText(attribution.killerName, "")
        if arguments.faction == "an unknown faction" then
            arguments.faction = "our group"
        end
    end
    template = memory.SelectGossipTemplate(
        flavorID,
        observer.identitySeed or 1,
        token
    )
    if not template then return false end
    gossipPacket = memory.BuildGossipPacket(template, arguments)
    if type(gossipPacket) ~= "table" then return false end
    if npcID == "" or not sendToNearbyPlayers(observer, actor, {
        eventID = string.sub(
            "corpse-reaction:" .. npcID .. ":" .. memoryID,
            1,
            384
        ),
        npcID = npcID,
        flavorID = flavorID,
        eventType = "corpse_reaction",
        gossipPacket = gossipPacket,
        corpseNPCID = identity.npcID,
        corpseName = identity.name,
        factionName = identity.factionName,
        relationshipKind = category,
        memoryID = memoryID,
        memoryType = MEMORY_TYPE,
    }) then
        return false
    end
    return true
end

local function corpsePosition(record, corpse)
    local x = corpse and corpse.getX and corpse:getX() or record and record.x
    local y = corpse and corpse.getY and corpse:getY() or record and record.y
    local z = corpse and corpse.getZ and corpse:getZ() or record and record.z
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z) or 0
    if not x or not y then return nil end
    return x, y, z
end

local function candidateRelation(observer, deceased, identity)
    local targetKey
    local relationship
    local rawRelationship
    local observerFactionID = observer and observer.affiliation
        and tostring(observer.affiliation.factionID or "") or ""
    local corpseFactionID = tostring(identity and identity.factionID or "")
    local sameFaction = observerFactionID ~= ""
        and corpseFactionID ~= ""
        and observerFactionID == corpseFactionID
    targetKey, relationship, rawRelationship = relationFor(
        observer,
        identity.npcID
    )
    local category = classify(
        observer,
        deceased,
        identity,
        relationship,
        rawRelationship,
        sameFaction
    )
    return targetKey, relationship, category, sameFaction
end

local function collectCandidates(record, corpse, corpseData, identity)
    local spatial = PNC.SpatialIndex
    local registry = PNC.Registry
    local x, y, z = corpsePosition(record, corpse)
    local indexed
    local candidates = {}
    local indexedCount
    local cursor
    local scanCount
    local offset
    local index
    local observer
    local actor
    local actorX
    local actorY
    local actorZ
    local dx
    local dy
    local dz
    local targetKey
    local relationship
    local category
    local sameFaction
    local corpsePresenceState = PNC.Const
        and PNC.Const.PRESENCE_CORPSE or "corpse"
    if not x or not y or not spatial
        or type(spatial.QueryNPCs) ~= "function"
    then
        return candidates
    end
    indexed = spatial.QueryNPCs(x, y, DETECTION_RADIUS)
    if type(indexed) ~= "table" then return candidates end
    indexedCount = #indexed
    if indexedCount <= 0 then return candidates end
    cursor = math.floor(tonumber(
        corpseData.PNC_CorpseAwarenessCandidateCursor
    ) or 0) % indexedCount
    scanCount = math.min(indexedCount, MAX_NPCS_TO_SCORE)
    for offset = 0, scanCount - 1 do
        index = ((cursor + offset) % indexedCount) + 1
        observer = indexed[index]
        if observer and observer.id ~= nil
            and tostring(observer.id) ~= identity.npcID
            and observer.alive ~= false
            and observer.presenceState ~= corpsePresenceState
        then
            actor = registry and registry.GetLiveZombie
                and registry.GetLiveZombie(observer.id) or nil
            if actor and not (actor.isDead and actor:isDead()) then
                actorX = actor.getX and actor:getX() or observer.x
                actorY = actor.getY and actor:getY() or observer.y
                actorZ = actor.getZ and actor:getZ() or observer.z
                dx = (tonumber(actorX) or x) - x
                dy = (tonumber(actorY) or y) - y
                dz = math.abs((tonumber(actorZ) or z) - z)
                if dz < 1 and dx * dx + dy * dy <= DETECTION_RADIUS_SQ then
                    targetKey, relationship, category, sameFaction =
                        candidateRelation(observer, record, identity)
                    candidates[#candidates + 1] = {
                        record = observer,
                        actor = actor,
                        targetKey = targetKey,
                        relationship = relationship,
                        category = category,
                        sameFaction = sameFaction,
                        priority = (sameFaction and 10 or 0)
                            + (RELATION_PRIORITY[category] or 1),
                        distanceSq = dx * dx + dy * dy,
                    }
                end
            end
        end
    end
    corpseData.PNC_CorpseAwarenessCandidateCursor =
        (cursor + scanCount) % indexedCount
    table.sort(candidates, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return tostring(left.record.id) < tostring(right.record.id)
    end)
    return candidates
end

local function processWitnesses(
    record,
    target,
    scanState,
    identity,
    deathContext
)
    local witnessCount = math.max(0, math.floor(tonumber(
        scanState.PNC_CorpseAwarenessWitnessCount
    ) or 0))
    local memoryID = deathMemoryID(identity and identity.token)
    local candidates
    local checks = 0
    local reactions = 0
    local candidate
    local observer
    local visible
    local count
    local added
    local attribution = deathContext and deathContext.attribution or nil
    local index
    if not memoryID or witnessCount >= MAX_WITNESSES_PER_CORPSE then
        return witnessCount
    end
    candidates = collectCandidates(record, target, scanState, identity)
    for index = 1, #candidates do
        candidate = candidates[index]
        observer = candidate.record
        if checks >= MAX_VISIBILITY_CHECKS
            or reactions >= MAX_CORPSE_REACTIONS_PER_SCAN
            or witnessCount >= MAX_WITNESSES_PER_CORPSE
        then
            break
        end
        if not hasSpokenMemory(candidate.relationship, memoryID) then
            count = deathMemoryCount(observer)
            if count < MEMORY_LIMIT_PER_NPC then
                checks = checks + 1
                visible = PNC.Perception.CanSeeWorldObject(observer, target)
                if visible == true then
                    added = rememberWitness(
                        observer,
                        candidate.targetKey,
                        identity,
                        candidate.category,
                        memoryID,
                        attribution
                    )
                    if added then
                        witnessCount = witnessCount + 1
                        scanState.PNC_CorpseAwarenessWitnessCount =
                            witnessCount
                        if type(record.runtime) == "table" then
                            record.runtime.corpseAwarenessWitnessCount =
                                witnessCount
                            record.runtime.corpseAwarenessCandidateCursor =
                                tonumber(
                                    scanState.PNC_CorpseAwarenessCandidateCursor
                                ) or 0
                        end
                        if type(deathContext) == "table" then
                            deathContext.witnessCount = witnessCount
                            deathContext.PNC_CorpseAwarenessCandidateCursor =
                                tonumber(
                                    scanState.PNC_CorpseAwarenessCandidateCursor
                                ) or 0
                        end
                        if speak(
                            observer,
                            candidate.actor,
                            identity,
                            candidate.category,
                            identity.token,
                            attribution,
                            candidate.sameFaction
                                and knownKillerName(attribution)
                        ) then
                            reactions = reactions + 1
                        end
                    end
                end
            end
        end
    end
    if type(record.runtime) == "table" then
        record.runtime.corpseAwarenessWitnessCount = witnessCount
        record.runtime.corpseAwarenessCandidateCursor = tonumber(
            scanState.PNC_CorpseAwarenessCandidateCursor
        ) or 0
        record.runtime.corpseAwarenessScanToken = tostring(
            identity and identity.token or ""
        )
    end
    if type(deathContext) == "table" then
        deathContext.witnessCount = witnessCount
        deathContext.PNC_CorpseAwarenessCandidateCursor = tonumber(
            scanState.PNC_CorpseAwarenessCandidateCursor
        ) or 0
    end
    return witnessCount
end

function Awareness.ObserveDeath(record, actor, damageEvent, token)
    local core = PNC.Core
    local runtime
    local runtimeTokenMatches
    local identity
    local context
    local actorData
    local witnessCount
    local candidateCursor
    local now
    if not record or not core or not core.IsAuthority
        or core.IsAuthority() ~= true
    then
        return nil
    end
    token = tostring(token or record.corpseToken
        or record.corpse and record.corpse.token or "")
    if token == "" then return nil end
    identity = deathIdentityFromRecord(record, token)
    if not identity then return nil end
    runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime = runtime
    runtimeTokenMatches = tostring(
        runtime.corpseAwarenessScanToken or ""
    ) == token
    if not runtimeTokenMatches then
        runtime.corpseAwarenessScanToken = token
        runtime.corpseAwarenessWitnessCount = 0
        runtime.corpseAwarenessCandidateCursor = 0
        runtime.corpseAwarenessNextScanAtMs = 0
    end
    witnessCount = runtimeTokenMatches and math.max(0, math.floor(tonumber(
        runtime.corpseAwarenessWitnessCount
    ) or 0)) or 0
    candidateCursor = runtimeTokenMatches and math.max(0, math.floor(
        tonumber(runtime.corpseAwarenessCandidateCursor) or 0
    )) or 0
    context = {
        token = token,
        identity = identity,
        attribution = deathAttribution(record, damageEvent),
        witnessCount = witnessCount,
        PNC_CorpseAwarenessWitnessCount = witnessCount,
        PNC_CorpseAwarenessCandidateCursor = candidateCursor,
    }
    actorData = modDataOf(actor)
    cacheDeathAwarenessState(
        actorData,
        token,
        identity,
        context.attribution,
        witnessCount,
        candidateCursor
    )
    if actor and PNC.Relationships
        and type(PNC.Relationships.AddMemory) == "function"
        and PNC.Perception
        and type(PNC.Perception.CanSeeWorldObject) == "function"
    then
        now = nowMs()
        processWitnesses(
            record,
            actor,
            context,
            identity,
            context
        )
        runtime.corpseAwarenessNextScanAtMs = now + SCAN_INTERVAL_MS
    end
    cacheDeathAwarenessState(
        actorData,
        token,
        identity,
        context.attribution,
        context.witnessCount,
        context.PNC_CorpseAwarenessCandidateCursor
    )
    return context
end

function Awareness.ObserveCorpse(record, corpse, deathContext)
    local core = PNC.Core
    local relationships = PNC.Relationships
    local corpseData = modDataOf(corpse)
    local now = nowMs()
    local runtime
    local scanToken
    local identity
    local attribution
    local memoryID
    local witnessCount
    local count
    local context
    local carriedIdentity
    local hasDeathContext = false
    if not record or not corpse or not corpseData
        or not core or not core.IsAuthority
        or core.IsAuthority() ~= true
        or not relationships
        or type(relationships.AddMemory) ~= "function"
        or not PNC.Perception
        or type(PNC.Perception.CanSeeWorldObject) ~= "function"
    then
        return 0
    end
    scanToken = tostring(
        corpseData.PNC_CorpseToken
            or record.corpseToken
            or record.corpse and record.corpse.token
            or ""
    )
    if scanToken == "" then return 0 end
    runtime = type(record.runtime) == "table"
        and record.runtime or {}
    record.runtime = runtime
    if type(deathContext) == "table"
        and tostring(deathContext.token or "") == scanToken
    then
        carriedIdentity = copyDeathIdentity(
            record,
            scanToken,
            deathContext.identity
        )
        if carriedIdentity then
            identity = carriedIdentity
            cacheCorpseIdentity(corpseData, identity)
            cacheDeathAttribution(
                corpseData,
                scanToken,
                deathContext.attribution
            )
            hasDeathContext = true
        end
    end
    if not identity then
        identity = corpseIdentity(record, corpse, corpseData)
        attribution = cachedDeathAttribution(corpseData, scanToken)
    else
        attribution = deathContext.attribution
    end
    if not identity then return 0 end
    memoryID = deathMemoryID(identity.token)
    if not memoryID then return 0 end
    if tonumber(corpseData.PNC_CorpseAwarenessVersion)
            ~= CACHE_SCHEMA_VERSION
        or tostring(corpseData.PNC_CorpseAwarenessToken or "") ~= ""
            and tostring(corpseData.PNC_CorpseAwarenessToken or "")
                ~= scanToken
    then
        corpseData.PNC_CorpseAwarenessVersion = CACHE_SCHEMA_VERSION
        corpseData.PNC_CorpseAwarenessToken = scanToken
        corpseData.PNC_CorpseAwarenessWitnessCount = 0
        corpseData.PNC_CorpseAwarenessCandidateCursor = 0
    else
        corpseData.PNC_CorpseAwarenessToken = scanToken
    end
    witnessCount = math.max(0, math.floor(tonumber(
        corpseData.PNC_CorpseAwarenessWitnessCount
    ) or 0))
    if hasDeathContext then
        count = math.max(0, math.floor(tonumber(
            deathContext.witnessCount
        ) or 0))
        witnessCount = math.max(witnessCount, count)
        corpseData.PNC_CorpseAwarenessWitnessCount = witnessCount
        corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(0, math.floor(
            tonumber(deathContext.PNC_CorpseAwarenessCandidateCursor) or 0
        ))
    elseif tostring(runtime.corpseAwarenessScanToken or "") == scanToken
        and tonumber(runtime.corpseAwarenessWitnessCount)
    then
        witnessCount = math.max(
            witnessCount,
            math.floor(tonumber(runtime.corpseAwarenessWitnessCount) or 0)
        )
        corpseData.PNC_CorpseAwarenessWitnessCount = witnessCount
        corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(
            tonumber(corpseData.PNC_CorpseAwarenessCandidateCursor) or 0,
            math.floor(tonumber(runtime.corpseAwarenessCandidateCursor) or 0)
        )
    end
    if hasDeathContext then
        context = deathContext
    else
        context = {
            token = scanToken,
            identity = identity,
            attribution = attribution,
            witnessCount = witnessCount,
            PNC_CorpseAwarenessWitnessCount = witnessCount,
            PNC_CorpseAwarenessCandidateCursor = math.max(0, math.floor(
                tonumber(corpseData.PNC_CorpseAwarenessCandidateCursor) or 0
            )),
        }
    end
    context.token = scanToken
    context.identity = identity
    context.attribution = attribution
    context.witnessCount = witnessCount
    context.PNC_CorpseAwarenessWitnessCount = witnessCount
    context.PNC_CorpseAwarenessCandidateCursor = math.max(
        0,
        math.floor(tonumber(
            corpseData.PNC_CorpseAwarenessCandidateCursor
        ) or 0)
    )
    cacheDeathAwarenessState(
        corpseData,
        scanToken,
        identity,
        attribution,
        witnessCount,
        corpseData.PNC_CorpseAwarenessCandidateCursor
    )
    if witnessCount >= MAX_WITNESSES_PER_CORPSE then return 0 end
    if tostring(runtime.corpseAwarenessScanToken or "") ~= scanToken then
        runtime.corpseAwarenessScanToken = scanToken
        runtime.corpseAwarenessNextScanAtMs = 0
    end
    if now < (tonumber(runtime.corpseAwarenessNextScanAtMs) or 0) then
        return 0
    end
    runtime.corpseAwarenessNextScanAtMs = now + SCAN_INTERVAL_MS
    return processWitnesses(
        record,
        corpse,
        corpseData,
        identity,
        context
    )
end

return Awareness
