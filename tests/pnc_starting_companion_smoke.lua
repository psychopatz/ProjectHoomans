local T = require "tests/support/test"

local SERVER_ROOT =
    T.path("ProjectHoomans", "server", "PNC/")

local record = {
    uuid = "char_online_survivor",
    accountIdentity = "steam_123",
    startingCompanions = { resolved = false, grants = {} },
}
local npcs = {}
local spawnCount = 0
local assignCount = 0
local relationshipCount = 0
local knowledgeCount = 0
local commitCount = 0
local specs = {
    { id = "PNC_HasBrother", relationshipKind = "brother", sex = "male",
        sharesSurname = true, sharesAppearance = true },
    { id = "PNC_HasSister", relationshipKind = "sister", sex = "female",
        sharesSurname = true, sharesAppearance = true },
    { id = "PNC_HasMom", relationshipKind = "mother", sex = "female",
        sharesSurname = true, sharesAppearance = true },
    { id = "PNC_HasDad", relationshipKind = "father", sex = "male",
        sharesSurname = true, sharesAppearance = true },
    { id = "PNC_IsMarried", relationshipKind = "lover", sex = "orientation",
        sharesSurname = true },
    { id = "PNC_HasFriend", relationshipKind = "friend", sex = "random",
        sharesSurname = false },
}
local byID = {}
for _, spec in ipairs(specs) do byID[spec.id] = spec end

PNC = {
    StartingCompanionTraits = {
        DEFINITIONS = specs,
        GetDefinition = function(id) return byID[id] end,
        ResolveSelections = function() return specs, "selected" end,
        ResolveCompanionFemale = function(spec, survivorFemale, orientation, roll)
            if spec.sex == "female" then return true end
            if spec.sex == "male" then return false end
            if spec.sex == "random" then return roll end
            if orientation == "gay" then return survivorFemale end
            if orientation == "bisexual" then return roll end
            return not survivorFemale
        end,
    },
    Identity = {
        NormalizeSeed = function() return 41 end,
        Index = function() return 2 end,
        GetCharacterAppearance = function()
            return {
                skinColor = { r = 0.44, g = 0.31, b = 0.22 },
                hairColor = { r = 0.12, g = 0.07, b = 0.03 },
                skinTexture = "FemaleBody03",
            }
        end,
        GenerateResolvedIdentity = function(definition)
            return {
                displayName = "Casey Random",
                isFemale = definition.isFemale,
                survivor = {
                    forename = "Casey",
                    surname = "Random",
                    skinColor = { r = 0.8, g = 0.7, b = 0.6 },
                    hairColor = { r = 0.6, g = 0.5, b = 0.4 },
                    skinTexture = "MaleBody01",
                },
            }
        end,
    },
    Registry = {
        Get = function(id) return npcs[id] end,
        MarkDirty = function() end,
    },
    PlayerCharacterTypes = {
        NormalizeStartingCompanionState = function(value)
            return value or { resolved = false, grants = {} }
        end,
    },
    PlayerCharacters = {
        GetRegistryRecord = function() return record end,
        ApplyStartingCompanionState = function(_, value)
            record.startingCompanions = value
            return true, "updated", value
        end,
        Save = function() return true end,
    },
    SocialProfiles = {
        GetPlayerProfile = function() return { orientation = "gay" } end,
    },
    API = {
        Spawn = function(definition)
            spawnCount = spawnCount + 1
            local npc = {
                id = definition.id,
                isFemale = definition.isFemale,
                identity = definition.identity,
                name = definition.identity.displayName,
                generation = definition.generation,
                alive = true,
            }
            npcs[definition.id] = npc
            return npc
        end,
    },
    Recruitment = {
        Assign = function(player, npc)
            assignCount = assignCount + 1
            npc.recruited = true
            npc.ownerUsername = player:getUsername()
            npc.affiliation = {
                factionID = "faction_player",
                communityID = "community_player",
            }
            return true, "recruited"
        end,
    },
    Factions = {
        GetPlayerFaction = function() return { id = "faction_player" } end,
        GetNPCAffiliation = function(npc)
            return npcs[npc] and npcs[npc].affiliation or nil
        end,
    },
    Communities = {
        GetNPCCommunity = function(npc)
            local affiliation = npcs[npc] and npcs[npc].affiliation or nil
            return affiliation and affiliation.communityID
                and {
                    id = affiliation.communityID,
                    factionID = affiliation.factionID,
                    status = "active",
                } or nil
        end,
    },
    Relationships = {
        SetInitialBaseline = function(_, _, standing)
            relationshipCount = relationshipCount + 1
            T.equal(standing.familiarity >= 90, true,
                "lifelong familiarity baseline")
            return {}
        end,
    },
    NPCKnowledge = {
        DiscoverAllForPlayer = function()
            knowledgeCount = knowledgeCount + 1
            return { revealed = { "identity.name" } }
        end,
        BuildPlayerSnapshotForPlayer = function() return {} end,
    },
    Network = {
        SendNPCKnowledge = function() end,
        BroadcastRecord = function() end,
    },
    PersistenceCoordinator = {
        Commit = function()
            commitCount = commitCount + 1
            return true, "committed"
        end,
    },
    EntityRef = {
        ForPlayerIdentity = function(account, uuid)
            return "player:" .. account .. ":" .. uuid
        end,
    },
    Const = { FACTION_NEUTRAL = "neutral" },
    Core = { Now = function() return 1000 end, LogInfo = function() end },
}

local player = {
    getUsername = function() return "OnlinePlayer" end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    isFemale = function() return true end,
    getDescriptor = function()
        return {
            getSurname = function() return "SurvivorFamily" end,
            isFemale = function() return true end,
        }
    end,
}

T.load(SERVER_ROOT .. "Companions/PNC_StartingCompanionService.lua")

local granted, reason, result = PNC.StartingCompanions.Ensure(
    player, record.uuid, 12
)
T.equal(granted, true, "first ensure grants all companions")
T.equal(reason, "granted", "first ensure result")
T.equal(#result.npcIDs, 6, "six selected companions returned")
T.equal(spawnCount, 6, "one NPC per selected trait")
T.equal(assignCount, 6, "all companions assigned")
T.equal(relationshipCount, 6, "all relationships initialized")
T.equal(knowledgeCount, 6, "all dossiers initialized")
T.equal(commitCount, 7, "selection plus each grant committed")

local brother = npcs[record.startingCompanions.grants.PNC_HasBrother.npcID]
local sister = npcs[record.startingCompanions.grants.PNC_HasSister.npcID]
local mom = npcs[record.startingCompanions.grants.PNC_HasMom.npcID]
local dad = npcs[record.startingCompanions.grants.PNC_HasDad.npcID]
local lover = npcs[record.startingCompanions.grants.PNC_IsMarried.npcID]
local friend = npcs[record.startingCompanions.grants.PNC_HasFriend.npcID]
for _, familyMember in ipairs({ brother, sister, mom, dad }) do
    T.equal(familyMember.identity.survivor.surname, "SurvivorFamily",
        "blood relative shares player surname")
    T.equal(familyMember.identity.survivor.skinColor.r, 0.44,
        "blood relative shares player skin color")
    T.equal(familyMember.identity.survivor.skinColor.g, 0.31,
        "blood relative shares player skin color green channel")
    T.equal(familyMember.identity.survivor.hairColor.b, 0.03,
        "blood relative shares player hair color")
    local expectedTexture = familyMember.isFemale
        and "FemaleBody03" or "MaleBody03"
    T.equal(familyMember.identity.survivor.skinTexture, expectedTexture,
        "blood relative shares player skin texture index")
end
T.equal(lover.identity.survivor.surname, "SurvivorFamily",
    "married lover shares player surname")
T.equal(friend.identity.survivor.surname, "Random",
    "friend keeps independently generated surname")
T.equal(lover.isFemale, true,
    "gay female survivor receives female lover")

brother.identity.survivor.skinColor = { r = 0.1, g = 0.1, b = 0.1 }
brother.identity.survivor.skinTexture = "MaleBody01"
brother.isFemale = nil
record.startingCompanions.grants.PNC_HasBrother.enrichmentVersion = 4
granted, reason = PNC.StartingCompanions.Ensure(
    player, record.uuid, 13
)
T.equal(granted, true, "existing blood relative is enriched")
T.equal(reason, "granted", "existing blood relative enrichment result")
T.equal(brother.identity.survivor.skinColor.r, 0.44,
    "existing blood relative receives player skin color")
T.equal(brother.identity.survivor.skinTexture, "MaleBody03",
    "existing blood relative receives player skin texture")

granted, reason = PNC.StartingCompanions.Ensure(
    player, record.uuid, 14
)
T.equal(granted, false, "reconnect does not grant again")
T.equal(reason, "granted", "reconnect sees persisted grants")
T.equal(spawnCount, 6, "reconnect creates no duplicates")
T.equal(assignCount, 6, "reconnect performs no reassignment")

-- Existing grants repair a stale faction/community link exactly once.
lover.affiliation = nil
record.startingCompanions.grants.PNC_IsMarried.enrichmentVersion = 2
granted, reason = PNC.StartingCompanions.Ensure(
    player, record.uuid, 15
)
T.equal(granted, true, "stale enrollment is repaired")
T.equal(reason, "granted", "repair completes grant")
T.equal(assignCount, 7, "only stale companion is reassigned")
granted, reason = PNC.StartingCompanions.Ensure(
    player, record.uuid, 16
)
T.equal(granted, false, "completed repair is not repeated")
T.equal(reason, "granted", "completed repair remains resolved")
T.equal(assignCount, 7, "repair performs no per-frame reassignment")
local stableCommitCount = commitCount
for frame = 1, 120 do
    PNC.StartingCompanions.Ensure(player, record.uuid, 16 + frame)
end
T.equal(assignCount, 7,
    "steady lifecycle checks never repeat companion assignment")
T.equal(commitCount, stableCommitCount,
    "steady lifecycle checks never save companion state per frame")
T.finish("pnc_starting_companion_smoke")

T.finish("pnc_starting_companion_smoke")
