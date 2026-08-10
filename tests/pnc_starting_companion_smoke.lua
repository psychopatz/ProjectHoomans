local SERVER_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

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
    { id = "PNC_HasBrother", relationshipKind = "brother", sex = "male" },
    { id = "PNC_HasLover", relationshipKind = "lover", sex = "orientation" },
    { id = "PNC_HasFriend", relationshipKind = "friend", sex = "random" },
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
        GenerateResolvedIdentity = function(definition)
            return {
                displayName = "Casey Random",
                isFemale = definition.isFemale,
                survivor = { forename = "Casey", surname = "Random" },
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
            return true, "recruited"
        end,
    },
    Relationships = {
        SetInitialBaseline = function(_, _, standing)
            relationshipCount = relationshipCount + 1
            assertEqual(standing.familiarity >= 90, true,
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

dofile(SERVER_ROOT .. "PNC_StartingCompanionService.lua")

local granted, reason, result = PNC.StartingCompanions.Ensure(
    player, record.uuid, 12
)
assertEqual(granted, true, "first ensure grants all companions")
assertEqual(reason, "granted", "first ensure result")
assertEqual(#result.npcIDs, 3, "three selected companions returned")
assertEqual(spawnCount, 3, "one NPC per selected trait")
assertEqual(assignCount, 3, "all companions assigned")
assertEqual(relationshipCount, 3, "all relationships initialized")
assertEqual(knowledgeCount, 3, "all dossiers initialized")
assertEqual(commitCount, 4, "selection plus each grant committed")

local brother = npcs[record.startingCompanions.grants.PNC_HasBrother.npcID]
local lover = npcs[record.startingCompanions.grants.PNC_HasLover.npcID]
local friend = npcs[record.startingCompanions.grants.PNC_HasFriend.npcID]
assertEqual(brother.identity.survivor.surname, "SurvivorFamily",
    "family companion shares player surname")
assertEqual(lover.identity.survivor.surname, "Random",
    "lover keeps independently generated surname")
assertEqual(friend.identity.survivor.surname, "Random",
    "friend keeps independently generated surname")
assertEqual(lover.isFemale, true,
    "gay female survivor receives female lover")

granted, reason = PNC.StartingCompanions.Ensure(
    player, record.uuid, 13
)
assertEqual(granted, false, "reconnect does not grant again")
assertEqual(reason, "granted", "reconnect sees persisted grants")
assertEqual(spawnCount, 3, "reconnect creates no duplicates")
assertEqual(assignCount, 3, "reconnect performs no reassignment")

print("pnc_starting_companion_smoke: ok")
