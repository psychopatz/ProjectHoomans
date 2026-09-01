local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")

local player = {
    x = 0,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getUsername = function() return "Mara" end,
}

local records = {
    ["npc-good"] = {
        id = "npc-good",
        alive = true,
        presenceState = "live",
        x = 3,
        y = 0,
        z = 0,
    },
    ["npc-hostile"] = {
        id = "npc-hostile",
        alive = true,
        presenceState = "live",
        x = 4,
        y = 0,
        z = 0,
        hostility = { attackPlayers = true },
    },
}

local bodies = {
    ["npc-good"] = {
        getX = function() return 3 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
    },
    ["npc-hostile"] = {
        getX = function() return 4 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
    },
}

local relationships = {
    ["npc-good"] = {
        approval = 35,
        respect = 15,
        familiarity = 5,
        state = "friend",
        memories = {},
        cooldowns = {},
        revision = 1,
    },
    ["npc-hostile"] = {
        approval = 35,
        respect = 15,
        familiarity = 5,
        state = "friend",
        memories = {},
        cooldowns = {},
        revision = 1,
    },
}

local applied = {}
local relationshipBroadcasts = {}
local speechBroadcasts = {}

PNC = {
    Core = {
        IsAuthority = function() return true end,
        ForEachPlayer = function(callback) callback(player) end,
    },
    Const = {},
    Registry = {
        GetLiveZombie = function(id) return bodies[id] end,
    },
    SpatialIndex = {
        QueryNPCs = function() return { records["npc-good"], records["npc-hostile"] } end,
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:slot:character-1" end,
    },
    RelationshipPresentation = {
        Summarize = function(value, exists)
            return {
                exists = exists == true,
                approval = value.approval,
                respect = value.respect,
                familiarity = value.familiarity,
                state = value.state,
                revision = value.revision,
            }
        end,
    },
    Relationships = {
        Get = function(npcID) return relationships[npcID] end,
        ApplyConversationEffect = function(npcID, _, effect, context)
            local current = relationships[npcID]
            local memory = {
                type = effect.memoryType,
                createdAt = context.worldAgeHours,
            }
            current.approval = current.approval + (effect.approval or 0)
            current.respect = current.respect + (effect.respect or 0)
            current.familiarity = current.familiarity
                + (effect.familiarity or 0)
            current.revision = current.revision + 1
            current.memories[#current.memories + 1] = memory
            applied[#applied + 1] = context
            return true, "applied", {
                relationship = current,
                eventID = context.eventID,
                memoryID = context.eventID,
                memoryType = effect.memoryType,
            }
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcID, reason, context)
            relationshipBroadcasts[#relationshipBroadcasts + 1] = {
                npcID = npcID,
                reason = reason,
                context = context,
            }
            return true
        end,
        SendSocialGreeting = function(_, payload)
            speechBroadcasts[#speechBroadcasts + 1] = payload
            return true
        end,
    },
}

T.load(SHARED .. "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_VanillaEmoteInteractions.lua")
T.load(SERVER .. "PNC/Social/PNC_SocialGreetingService.lua")

local Service = PNC.SocialGreeting
local Interactions = PNC.VanillaEmoteInteractions
local relationship = relationships["npc-good"]

Service.Reset()
T.equal(Service.Pump(24), 1, "first proximity entry greets the player")
T.equal(#applied, 1, "proximity greeting uses one relationship mutation")
T.equal(#relationshipBroadcasts, 1, "proximity greeting uses central relationship transport")
T.equal(#speechBroadcasts, 1, "proximity greeting sends NPC speech")
T.equal(
    speechBroadcasts[1].flavorID,
    "social_greeting_npc_neutral_warm_first",
    "friendly neutral NPC receives warm first greeting flavor"
)
T.equal(
    Interactions.GreetingState(
        Interactions.Get("wavehi"),
        relationship,
        24
    ),
    "returning",
    "wavehi sees the automatic greeting as today's greeting"
)

T.equal(Service.Pump(24.01), 0, "standing nearby does not retrigger greeting")
T.equal(#applied, 1, "standing nearby does not add relationship points")

player.x = 30
T.equal(Service.Pump(25), 0, "leaving the radius produces no greeting")
player.x = 0
T.equal(Service.Pump(48), 1, "next day allows a new proximity greeting")
T.equal(#applied, 2, "next day grants one new relationship mutation")
T.equal(#speechBroadcasts, 2, "next day sends another NPC greeting")
T.equal(
    speechBroadcasts[2].greetingDay,
    2,
    "next-day greeting carries the authoritative day index"
)

T.equal(
    Interactions.IsAutomaticGreetingEligible(
        relationships["npc-hostile"],
        "hostile"
    ),
    false,
    "hostile NPCs do not receive friendly automatic greeting behavior"
)
T.equal(
    Interactions.GreetingReplyFlavorID("family", "warm", "first"),
    "social_greeting_npc_family_warm_first",
    "family greeting flavor is relationship-aware"
)

return T.finish("pnc_social_greeting_smoke")
