local T = require "tests/support/test"

local API_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_API.lua"
)
local REF_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_ActorRef.lua"
)
local OWNERSHIP_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_ActorOwnership.lua"
)
local TARGETING_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_Targeting.lua"
)
local BANDITS_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Adapter.lua"
)
local ACTOR_SEARCH_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception/ActorSearch.lua"
)

local managed = {}
local bodies = {}

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return managed[body] == true
        end,
        Now = function() return 42 end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (x1 or 0) - (x2 or 0)
            local dy = (y1 or 0) - (y2 or 0)
            return dx * dx + dy * dy
        end,
    },
    Const = { ZOMBIE_TARGET_RADIUS = 10 },
    SpatialIndex = {
        QueryNPCs = function() return {} end,
    },
    Identity = {
        Verifier = {
            IsPlayerFaction = function(record)
                return record and record.playerFaction == true
            end,
        },
    },
    Perception = {
        Internal = {},
        CanSeeWorldObject = function()
            return true, "open"
        end,
    },
}

local function body(id, brain)
    local value = {
        id = id,
        brain = brain,
        alive = true,
        health = 100,
        x = id,
        y = 0,
        z = 0,
    }
    value.getModData = function() return {} end
    value.getVariableBoolean = function(_, name)
        return name == "Bandit"
    end
    value.getX = function(self) return self.x end
    value.getY = function(self) return self.y end
    value.getZ = function(self) return self.z end
    value.isAlive = function(self) return self.alive end
    value.getHealth = function(self) return self.health end
    value.setHealth = function(self, health) self.health = health end
    value.getPersistentOutfitID = function(self) return self.id end
    bodies[id] = value
    return value
end

BanditBrain = {
    Get = function(value) return value and value.brain end,
}
BanditUtils = {
    GetCharacterID = function(value) return value and value.id end,
}
BanditZombie = {
    Cache = bodies,
    CacheLightB = {},
    GetAllB = function() return BanditZombie.CacheLightB end,
    GetInstanceById = function(id)
        return BanditZombie.Cache[id] or BanditZombie.Cache[tonumber(id)]
    end,
}

local hostile = body(3, { hostile = true })
BanditZombie.CacheLightB[3] = {
    id = 3,
    x = 3,
    y = 0,
    z = 0,
}

T.load(API_FILE)
T.load(REF_FILE)
T.load(OWNERSHIP_FILE)
T.load(BANDITS_FILE)
T.load(TARGETING_FILE)
PNC.Perception.Internal.PickNearest = function(first, second)
    return first or second
end
T.load(ACTOR_SEARCH_FILE)

local spokenPhrase
Bandit = {
    SoundTab = { HOOMANS_HIT = {} },
    Say = function(_, phrase)
        spokenPhrase = phrase
    end,
}

local adapter = PNC.Compatibility.API.GetAdapter("Bandits")
T.truthy(adapter, "Bandits adapter was not registered")
T.truthy(PNC.Compatibility.API.HasCapability("Bandits", "targeting"),
    "Bandits targeting capability was not registered")
T.truthy(PNC.Compatibility.API.HasCapability("Bandits", "damage"),
    "Bandits damage capability was not registered")

local source = {
    id = "hooman-1",
    x = 0,
    y = 0,
    z = 0,
    recruited = true,
}
local target = PNC.Compatibility.API.GetActorRef("Bandits", hostile)
T.equal(target.provider, "Bandits", "foreign provider was not normalized")
T.equal(target.actorId, "3", "foreign stable ID was not normalized")

local allowed, reason = PNC.Compatibility.API.CanAttack(
    source,
    target,
    { source = source }
)
T.truthy(allowed, "hostile Bandit was not attackable")
T.equal(reason, "bandit_hostile", "wrong hostile relationship reason")

local nearest = PNC.Compatibility.Targeting.FindNearestEnemy(source, 10)
T.truthy(nearest, "foreign target was not discovered")
T.equal(nearest.kind, "foreign_npc", "foreign target kind was not preserved")
T.equal(nearest.actorId, "3", "foreign target ID was lost during discovery")
T.near(nearest.distSq, 9, 0.0001, "foreign target distance was wrong")

local npcLaneNearest = PNC.Perception.FindNearestEnemyNPC(source, 10)
T.truthy(npcLaneNearest,
    "NPC perception lane did not merge foreign targets")
T.equal(npcLaneNearest.kind, "foreign_npc",
    "NPC perception lane returned the wrong foreign target kind")

local applied, applyReason = PNC.Compatibility.API.ApplyDamage(target, {
    attackerBody = source,
    hit = { amount = 8 },
})
T.truthy(applied, "foreign damage bridge rejected a valid Bandit")
T.equal(applyReason, "hit_bandit_health_fallback",
    "foreign damage bridge returned the wrong result")
T.equal(hostile.health, 92, "foreign damage bridge did not apply damage")

local handled = PNC.Compatibility.API.EmitEvent(
    "foreign_damage_applied",
    { target = target }
)
T.equal(handled, 1, "foreign combat event was not routed to Bandits")
T.equal(spokenPhrase, "HOOMANS_HIT",
    "Bandits native flavor bridge received the wrong phrase")

hostile.brain.hostile = false
hostile.brain.hostileP = true
source.recruited = false
source.ownerOnlineID = nil
source.playerFaction = false
source.alive = true
T.truthy(PNC.Compatibility.API.CanAttack(source, target, {}),
    "hostile-player Bandit did not attack a live Hooman variant")

source.alive = false
T.falsy(PNC.Compatibility.API.CanAttack(source, target, {}),
    "hostile-player Bandit attacked a dead Hooman")

T.finish("pnc_compatibility_adapter_smoke")
