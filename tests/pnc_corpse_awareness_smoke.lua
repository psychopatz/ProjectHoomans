local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
)
local now = 60000
local indexedNPCs = {}
local records = {}
local actors = {}
local memoryAdds = {}
local speechEvents = {}
local sentGreetings = {}
local nearbyPlayer = {
    getX = function() return 1 end,
    getY = function() return 1 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
local liveLookups = 0
local visibilityChecks = 0
local canSee = true

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        ForEachPlayer = function(callback)
            callback(nearbyPlayer)
        end,
    },
    Const = {
        MODULE = "PNC",
        PRESENCE_CORPSE = "corpse",
        TACTICAL_CLASS_HOSTILE = "hostile",
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id)
            liveLookups = liveLookups + 1
            return actors[tostring(id)]
        end,
    },
    SpatialIndex = {
        QueryNPCs = function() return indexedNPCs end,
    },
    Perception = {
        CanSeeWorldObject = function()
            visibilityChecks = visibilityChecks + 1
            return canSee
        end,
    },
    Factions = {
        GetRelation = function() return nil, "relation_not_found" end,
    },
    Network = {
        SendSocialGreeting = function(player, greeting)
            local payload = {}
            for key, value in pairs(greeting) do payload[key] = value end
            sentGreetings[#sentGreetings + 1] = {
                player = player,
                payload = payload,
            }
            return true
        end,
    },
    SocialEventHooks = {
        WorldAgeHours = function() return 48 end,
    },
    Relationships = {
        Get = function(observerID, targetKey)
            local observer = records[tostring(observerID)]
            return observer and observer.social
                and observer.social.relationships
                and observer.social.relationships[targetKey] or nil
        end,
        AddMemory = function(observerID, targetKey, spec)
            local observer = records[tostring(observerID)]
            local relationships = observer.social.relationships
            local relationship = relationships[targetKey]
            if not relationship then
                relationship = {
                    state = "unknown",
                    memories = {},
                }
                relationships[targetKey] = relationship
            end
            for _, memory in pairs(relationship.memories) do
                if memory.id == spec.id then
                    return false, "duplicate_memory_id"
                end
            end
            relationship.memories[#relationship.memories + 1] = spec
            memoryAdds[#memoryAdds + 1] = {
                observerID = tostring(observerID),
                targetKey = targetKey,
                spec = spec,
            }
            return true, "added"
        end,
    },
    Conversation = {
        Memory = {
            SelectGossipTemplate = function(event, seed, token)
                speechEvents[#speechEvents + 1] = event
                return { event = event, seed = seed, token = token }
            end,
            BuildGossipPacket = function(template, args)
                return {
                    c = #speechEvents + 3100,
                    a = { args.subject, args.faction },
                }
            end,
        },
    },
}

local function makeItem(fullType, metadata)
    return {
        getFullType = function() return fullType end,
        getModData = function() return metadata end,
    }
end

local function makeCorpse(id, token, name, factionID, factionName)
    local metadata = {
        PNC_DeathMarkerID = id,
        PNC_CorpseToken = token,
    }
    local card = makeItem("Base.IDcard", {
        PNC_IDCard = true,
        PNC_IDCardVersion = 1,
        PNC_IDCardNPCId = id,
        PNC_IDCardNPCName = name,
    })
    local items = { card }
    if factionID then
        items[#items + 1] = makeItem("Base.Necklace_DogTag", {
            PNC_FactionDogTag = true,
            PNC_FactionDogTagVersion = 1,
            PNC_FactionDogTagNPCId = id,
            PNC_FactionDogTagFactionId = factionID,
            PNC_FactionDogTagFactionName = factionName,
        })
    end
    local container = { getItems = function() return items end }
    return {
        getModData = function() return metadata end,
        getContainer = function() return container end,
        getX = function() return 1 end,
        getY = function() return 1 end,
        getZ = function() return 0 end,
    }, metadata
end

local function addObserver(id, relation, factionID)
    local record = {
        id = id,
        alive = true,
        presenceState = "live",
        identitySeed = id,
        x = 1,
        y = 1,
        z = 0,
        affiliation = factionID and { factionID = factionID } or nil,
        social = { relationships = {} },
        runtime = {},
    }
    if relation then
        record.social.relationships["npc:dead_1"] = relation
    end
    records[id] = record
    local actor = {
        getX = function() return 1 end,
        getY = function() return 1 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        Say = function() error("IsoZombie:Say must not be used") end,
        getChatElement = function()
            error("corpse reactions must use PNC social presentation")
        end,
    }
    actors[id] = actor
    return record
end

local dead = {
    id = "dead_1",
    name = "Avery Reed",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_token_1",
    generation = {
        relationshipKind = "brother",
        playerCharacterUUID = "player_character_1",
    },
}
records[dead.id] = dead

local relativeObserver = addObserver("relative", {
    state = "neutral",
    memories = {},
})
relativeObserver.generation = {
    relationshipKind = "sister",
    playerCharacterUUID = "player_character_1",
}
local friendObserver = addObserver("friend", { state = "friend", memories = {} })
friendObserver.generation = {
    relationshipKind = "friend",
    playerCharacterUUID = "player_character_1",
}
addObserver("hostile", { state = "enemy", memories = {} })
addObserver("comrade", { state = "neutral", memories = {} }, "faction_1")
addObserver("neutral", { state = "neutral", memories = {} })
indexedNPCs = {
    records.relative,
    records.friend,
    records.hostile,
    records.comrade,
    records.neutral,
}

T.load(ROOT .. "PNC_BodyLifecycle_CorpseAwareness.lua")

local corpse, corpseData = makeCorpse(
    dead.id,
    dead.corpseToken,
    "Avery Reed",
    "faction_1",
    "North Watch"
)
local witnessCount = PNC.CorpseAwareness.ObserveCorpse(dead, corpse)
T.equal(witnessCount, 5, "all visible nearby observers are recorded")
T.equal(#memoryAdds, 5, "one permanent memory is added per observer")
T.equal(#sentGreetings, 5,
    "nearby NPC reactions use the existing social greeting route")
T.equal(corpseData.PNC_CorpseAwarenessWitnessCount, 5,
    "corpse witness count is bounded and recorded")

local categories = {}
for _, event in ipairs(speechEvents) do categories[event] = true end
T.truthy(categories.corpse_seen_relative, "relative reply category")
T.truthy(categories.corpse_seen_friend, "friend reply category")
T.truthy(categories.corpse_seen_hostile, "hostile reply category")
T.truthy(categories.corpse_seen_comrade, "faction comrade reply category")
T.truthy(categories.corpse_seen_neutral, "neutral reply category")
local comradeGreeting
for _, event in ipairs(sentGreetings) do
    if event.payload.flavorID == "corpse_seen_comrade" then
        comradeGreeting = event.payload
        break
    end
end
T.truthy(comradeGreeting, "comrade reaction has a localized gossip packet")
T.equal(comradeGreeting.gossipPacket.a[1], "Avery Reed",
    "ID card name is passed as the corpse subject")
T.equal(comradeGreeting.gossipPacket.a[2], "North Watch",
    "dogtag faction name is passed to the reaction template")
for _, entry in ipairs(memoryAdds) do
    T.equal(entry.spec.type, "death_witnessed", "long-term memory type")
    T.equal(entry.spec.permanent, true, "death memory does not decay")
    T.equal(entry.spec.knowledgeSource, "witnessed",
        "memory records direct observation")
    T.equal(entry.spec.approvalEffect, 0, "corpse sight does not alter approval")
    T.equal(entry.spec.moraleEffect, 0, "corpse sight does not alter morale")
end
T.equal(PNC.CorpseAwareness.ObserveCorpse(dead, corpse), 0,
    "same corpse scan is throttled")
T.equal(#memoryAdds, 5, "repeat scan does not duplicate memories")
T.equal(#sentGreetings, 5, "repeat scan does not repeat replies")

now = now + 20000
local lateObserver = addObserver("late_observer", nil)
indexedNPCs[#indexedNPCs + 1] = lateObserver
T.equal(PNC.CorpseAwareness.ObserveCorpse(dead, corpse), 6,
    "later nearby NPC can discover a still present corpse")
T.equal(#memoryAdds, 6, "late discovery adds one new memory")
T.equal(#sentGreetings, 6, "late discovery can produce a reply")

local hiddenDead = {
    id = "dead_hidden",
    name = "Hidden Corpse",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_hidden",
}
records[hiddenDead.id] = hiddenDead
local hiddenCorpse = makeCorpse(
    hiddenDead.id,
    hiddenDead.corpseToken,
    hiddenDead.name
)
indexedNPCs = {}
for index = 1, 100 do
    indexedNPCs[index] = addObserver("hidden_observer_" .. index, nil)
end
canSee = false
visibilityChecks = 0
liveLookups = 0
local hiddenWitnesses = PNC.CorpseAwareness.ObserveCorpse(
    hiddenDead,
    hiddenCorpse
)
T.equal(hiddenWitnesses, 0, "blocked line of sight prevents reaction")
T.equal(#memoryAdds, 6, "blocked line of sight does not add memories")
T.equal(visibilityChecks, 12, "visibility checks have a hard cap per scan")
T.equal(liveLookups, 64, "candidate scans have a hard cap per scan")

local fullObserver = addObserver("memory_full", nil)
local priorMemories = {}
for index = 1, 24 do
    priorMemories[index] = { type = "death_witnessed" }
end
fullObserver.social.relationships["npc:prior"] = {
    state = "neutral",
    memories = priorMemories,
}
indexedNPCs = { fullObserver }
canSee = true
now = now + 20000
local fullDead = {
    id = "dead_memory_full",
    name = "Another Corpse",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_memory_full",
}
records[fullDead.id] = fullDead
local fullCorpse = makeCorpse(
    fullDead.id,
    fullDead.corpseToken,
    fullDead.name
)
T.equal(PNC.CorpseAwareness.ObserveCorpse(fullDead, fullCorpse), 0,
    "per-NPC long-term memory cap blocks further additions")
T.equal(#memoryAdds, 6, "memory cap prevents a flood of death records")

local oversizedObserver = addObserver("oversized_history", nil)
local oversizedMemories = {}
for index = 1, 33 do
    oversizedMemories[index] = { type = "unrelated_memory" }
end
oversizedObserver.social.relationships["npc:unrelated_history"] = {
    state = "neutral",
    memories = oversizedMemories,
}
indexedNPCs = { oversizedObserver }
now = now + 20000
local oversizedDead = {
    id = "dead_oversized_history",
    name = "Oversized History Corpse",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_oversized_history",
}
records[oversizedDead.id] = oversizedDead
local oversizedCorpse = makeCorpse(
    oversizedDead.id,
    oversizedDead.corpseToken,
    oversizedDead.name
)
T.equal(PNC.CorpseAwareness.ObserveCorpse(
    oversizedDead,
    oversizedCorpse
), 0, "oversized relationship memory arrays fail closed")
T.equal(#memoryAdds, 6,
    "oversized history scan does not exceed the memory budget")

local networkObserver = addObserver("network_observer", nil)
local networkDead = {
    id = "dead_network",
    name = "Network Corpse",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_network",
}
records[networkDead.id] = networkDead
indexedNPCs = { networkObserver }
now = now + 20000
local networkCorpse = makeCorpse(
    networkDead.id,
    networkDead.corpseToken,
    networkDead.name
)
local greetingsBeforeNetwork = #sentGreetings
PNC.CorpseAwareness.ObserveCorpse(networkDead, networkCorpse)
T.equal(#sentGreetings, greetingsBeforeNetwork + 1,
    "authority sends through the current PNC social greeting network method")
T.equal(sentGreetings[#sentGreetings].payload.eventType, "corpse_reaction",
    "existing greeting command distinguishes corpse reactions")
T.equal(sentGreetings[#sentGreetings].payload.npcID, "network_observer",
    "social greeting payload identifies the speaker")

local speechStart = #sentGreetings
local crowdDead = {
    id = "dead_crowd",
    name = "Crowd Corpse",
    alive = false,
    tacticalClass = "neutral",
    x = 1,
    y = 1,
    z = 0,
    corpseToken = "corpse_crowd",
}
records[crowdDead.id] = crowdDead
local crowd = {}
for index = 1, 20 do
    crowd[index] = addObserver("crowd_observer_" .. index, nil)
end
indexedNPCs = crowd
local crowdCorpse = makeCorpse(
    crowdDead.id,
    crowdDead.corpseToken,
    crowdDead.name
)
now = now + 20000
local crowdWitnesses = PNC.CorpseAwareness.ObserveCorpse(
    crowdDead,
    crowdCorpse
)
T.equal(crowdWitnesses, 12, "per-corpse witness cap is enforced")
T.equal(#sentGreetings - speechStart, 6,
    "global speech budget prevents a crowd from flooding replies")

T.finish("pnc_corpse_awareness_smoke")
