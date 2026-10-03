local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then
    return
end

local Internal = Awareness.Internal
local Relationship = Internal and Internal.Relationship
local Deps = Internal and Internal.RelationshipDeps
if not Relationship or not Deps then
    return
end

local lower = Deps.lower
local MEMORY_TYPE = Deps.MEMORY_TYPE
local MEMORY_ID_PREFIX = Deps.MEMORY_ID_PREFIX
local MEMORY_LIMIT_PER_NPC = Deps.MEMORY_LIMIT_PER_NPC
local MAX_RELATIONSHIPS_TO_COUNT = Deps.MAX_RELATIONSHIPS_TO_COUNT
local MAX_RELATIONSHIP_MEMORIES_TO_SCAN = Deps.MAX_RELATIONSHIP_MEMORIES_TO_SCAN
local KINSHIP_MARKERS = Deps.KINSHIP_MARKERS
local RELATION_PRIORITY = Deps.RELATION_PRIORITY

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


Relationship.classify = classify
Relationship.relationFor = relationFor
Relationship.deathMemoryID = deathMemoryID
Relationship.hasMemory = hasMemory
Relationship.deathMemoryCount = deathMemoryCount
